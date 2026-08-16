use std::collections::{HashMap, hash_map::Entry};

use lc3_image::MemoryImage;

use crate::{
    Diagnostic, SourceLocation,
    parser::{Operand, Operation, ParsedStatement, Spanned},
};

const TRAP_OPCODE: u16 = 0xF000;
const ADD_OPCODE: u16 = 0x1000;
const AND_OPCODE: u16 = 0x5000;
const NOT_OPCODE: u16 = 0x903F;
const BR_OPCODE: u16 = 0x0000;
const LD_OPCODE: u16 = 0x2000;
const LDI_OPCODE: u16 = 0xA000;
const LDR_OPCODE: u16 = 0x6000;
const LEA_OPCODE: u16 = 0xE000;
const ST_OPCODE: u16 = 0x3000;
const STI_OPCODE: u16 = 0xB000;
const STR_OPCODE: u16 = 0x7000;
const JMP_OPCODE: u16 = 0xC000;
const JSR_OPCODE: u16 = 0x4000;
const RTI_OPCODE: u16 = 0x8000;

#[derive(Clone, Eq, PartialEq, Default)]
struct Encoder {
    origin: u16,
    words: Vec<u16>,
    diagnostics: Vec<Diagnostic>,
    saw_end: bool,
    symbols: HashMap<String, u32>,
}

impl Encoder {
    fn get_offset9(&mut self, label: &str, location: SourceLocation) -> Option<u16> {
        let Some(addr) = self.symbols.get(&label.to_ascii_uppercase()) else {
            self.add_diagnostic(location, "label not found");
            return None;
        };

        let offset = i64::from(*addr) - i64::from(self.current_addr()) - 1;

        if !(-256..=255).contains(&offset) {
            self.add_diagnostic(location, "offset9 out of range");
            return None;
        }

        Some(u16::try_from(offset & 0x01FF).expect("offset9 fits in u16"))
    }

    fn get_offset11(&mut self, label: &str, location: SourceLocation) -> Option<u16> {
        let Some(addr) = self.symbols.get(&label.to_ascii_uppercase()) else {
            self.add_diagnostic(location, "label not found");
            return None;
        };

        let offset = i64::from(*addr) - i64::from(self.current_addr()) - 1;

        if !(-1024..=1023).contains(&offset) {
            self.add_diagnostic(location, "offset11 out of range");
            return None;
        }

        Some(u16::try_from(offset & 0x07FF).expect("offset11 fits in u16"))
    }

    fn get_offset6(&mut self, offset: i32, location: SourceLocation) -> Option<u16> {
        if !(-32..=31).contains(&offset) {
            self.add_diagnostic(location, "offset6 out of range");
            return None;
        }

        Some(u16::try_from(offset & 0x003F).expect("offset6 fits in u16"))
    }

    fn current_addr(&self) -> u16 {
        self.origin + u16::try_from(self.words.len()).expect("words fits in 16 bits")
    }

    fn build_symbol_table(&mut self, statements: &[ParsedStatement]) {
        let mut address = u32::from(self.origin);

        for statement in statements {
            let new_words = match statement {
                ParsedStatement::Label { label } => {
                    self.add_symbol(&label.value, address, label.location);
                    0
                }
                ParsedStatement::Operation {
                    operation:
                        Spanned {
                            value: Operation::Blkw,
                            ..
                        },
                    operands,
                    label,
                } => {
                    if let Some(label) = label {
                        self.add_symbol(&label.value, address, label.location);
                    }

                    let [
                        Spanned {
                            value: Operand::Number(num),
                            ..
                        },
                    ] = operands.as_slice()
                    else {
                        continue;
                    };

                    if !(0..=65535).contains(num) {
                        continue;
                    }

                    u16::try_from(*num).expect("BLKW fits in u16")
                }
                ParsedStatement::Operation {
                    operation:
                        Spanned {
                            value: Operation::Stringz,
                            ..
                        },
                    operands,
                    label,
                } => {
                    if let Some(label) = label {
                        self.add_symbol(&label.value, address, label.location);
                    }

                    let [
                        Spanned {
                            value: Operand::StringLiteral(string),
                            ..
                        },
                    ] = operands.as_slice()
                    else {
                        continue;
                    };

                    if string.len() > 65534 {
                        continue;
                    }

                    u16::try_from(string.len() + 1).expect("string fits in 16 bits")
                }
                ParsedStatement::Operation {
                    label: Some(label),
                    operation,
                    ..
                } => {
                    self.add_symbol(&label.value, address, label.location);
                    operation.value.word_count()
                }
                ParsedStatement::Operation {
                    label: None,
                    operation,
                    ..
                } => operation.value.word_count(),
            };

            if new_words > 0 {
                let last_address = address + u32::from(new_words) - 1;

                if last_address > u32::from(u16::MAX) {
                    address = u32::from(u16::MAX);
                    self.add_diagnostic(statement.location(), "address out of bounds");
                    continue;
                }
                address += u32::from(new_words);
            }
        }
    }

    fn add_symbol(&mut self, value: &str, address: u32, location: SourceLocation) {
        match self.symbols.entry(value.to_ascii_uppercase()) {
            Entry::Vacant(entry) => {
                entry.insert(address);
            }
            Entry::Occupied(_) => self.add_diagnostic(location, "duplicate label"),
        }
    }

    fn add_diagnostic(&mut self, location: SourceLocation, message: impl Into<String>) {
        self.diagnostics.push(Diagnostic::new(location, message));
    }

    fn read_origin(&mut self, statements: &[ParsedStatement]) -> usize {
        let Some(first_statement) = statements.first() else {
            self.add_diagnostic(
                SourceLocation::default(),
                "expected .ORIG but empty file found",
            );
            return 0;
        };

        let ParsedStatement::Operation {
            operation,
            operands,
            ..
        } = first_statement
        else {
            self.add_diagnostic(
                first_statement.location(),
                "expected .ORIG before any labels",
            );
            return 0;
        };

        if operation.value != Operation::Orig {
            self.add_diagnostic(
                first_statement.location(),
                "expected .ORIG as first statement",
            );
            return 0;
        }

        if let [operand] = operands.as_slice() {
            self.origin = self
                .read_address_operand(operand, ".ORIG expects a 16-bit, numeric address")
                .unwrap_or(0);
            1
        } else {
            self.add_diagnostic(operation.location, ".ORIG expects a single address operand");
            1
        }
    }

    fn read_end(&mut self) {
        self.saw_end = true;
    }

    fn read_address_operand(&mut self, operand: &Spanned<Operand>, message: &str) -> Option<u16> {
        let Operand::Number(value) = operand.value else {
            self.add_diagnostic(operand.location, message);
            return None;
        };

        if let Ok(value) = u16::try_from(value) {
            Some(value)
        } else {
            self.add_diagnostic(operand.location, message);
            None
        }
    }

    fn read_word_operand(&mut self, operand: &Spanned<Operand>, message: &str) -> Option<u16> {
        let Operand::Number(value) = operand.value else {
            return None;
        };

        if let Ok(value) = i16::try_from(value) {
            Some(value.cast_unsigned())
        } else if let Ok(value) = u16::try_from(value) {
            Some(value)
        } else {
            self.add_diagnostic(operand.location, message);
            None
        }
    }
}

impl Encoder {
    fn encode_fill(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        if let [operand] = operands.as_slice() {
            if let Some(value) =
                self.read_word_operand(operand, ".FILL expects a 16-bit numeric value")
            {
                self.words.push(value);
            } else if let Operand::Ident(value) = &operand.value {
                let Some(addr) = self.symbols.get(&value.to_ascii_uppercase()) else {
                    self.add_diagnostic(operand.location, "label not found");
                    return;
                };

                self.words
                    .push(u16::try_from(*addr).expect("address fits in u16"));
            } else {
                self.add_diagnostic(
                    operation.location,
                    ".FILL expects a numeric or label operand",
                );
            }
        } else {
            self.add_diagnostic(operation.location, ".FILL expects a single operand");
        }
    }

    fn encode_trap(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        if let [operand] = operands.as_slice() {
            let Operand::Number(value) = operand.value else {
                self.add_diagnostic(operand.location, "TRAP expects a numeric vector");
                return;
            };

            if let Ok(vector) = u8::try_from(value) {
                self.words.push(TRAP_OPCODE | u16::from(vector));
            } else {
                self.add_diagnostic(operand.location, "TRAP vector must fit in 8 bits");
            }
        } else {
            self.add_diagnostic(operation.location, "TRAP expects a single vector operand");
        }
    }

    fn encode_imm5_op(&mut self, opcode: u16, name: &str, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        match operands.as_slice() {
            [
                Spanned {
                    value: Operand::Register(dr),
                    ..
                },
                Spanned {
                    value: Operand::Register(sr1),
                    ..
                },
                Spanned {
                    value: Operand::Register(sr2),
                    ..
                },
            ] => {
                let dr = u16::from(*dr) << 9;
                let sr1 = u16::from(*sr1) << 6;
                let sr2 = u16::from(*sr2);

                self.words.push(opcode | dr | sr1 | sr2);
            }
            [
                Spanned {
                    value: Operand::Register(dr),
                    ..
                },
                Spanned {
                    value: Operand::Register(sr1),
                    ..
                },
                Spanned {
                    value: Operand::Number(imm),
                    location,
                },
            ] => {
                if !(-16..=15).contains(imm) {
                    self.add_diagnostic(*location, "imm5 value out of range");
                    return;
                }

                let dr = u16::from(*dr) << 9;
                let sr1 = u16::from(*sr1) << 6;
                let imm_bit = 1 << 5;
                let imm = u16::try_from(*imm & 0x001F).expect("masked imm5 fits in u16");

                self.words.push(opcode | dr | sr1 | imm_bit | imm);
            }
            _ => {
                self.add_diagnostic(
                    operation.location,
                    format!("{name} expects operands: destination register, source register, and 5 bit immediate value or second source"),
                );
            }
        }
    }

    fn encode_not(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::Register(dr),
                ..
            },
            Spanned {
                value: Operand::Register(sr),
                ..
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(
                operation.location,
                "NOT expects a source and destination register as operands",
            );
            return;
        };
        let dr = u16::from(*dr) << 9;
        let sr = u16::from(*sr) << 6;
        self.words.push(NOT_OPCODE | dr | sr);
    }

    fn encode_br(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation:
                Spanned {
                    value: Operation::Br { n, z, p },
                    location,
                },
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::Ident(label),
                location,
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(*location, "BR expects a label operand");
            return;
        };

        let Some(offset) = self.get_offset9(label, *location) else {
            return;
        };
        let nzp = (u16::from(*n) << 11) | (u16::from(*z) << 10) | (u16::from(*p) << 9);

        self.words.push(BR_OPCODE | nzp | offset);
    }

    fn encode_offset9_op(&mut self, opcode: u16, name: &str, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::Register(reg),
                ..
            },
            Spanned {
                value: Operand::Ident(label),
                location,
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(
                operation.location,
                format!("{name} expects a register and label operand"),
            );
            return;
        };

        let Some(offset) = self.get_offset9(label, *location) else {
            return;
        };

        self.words.push(opcode | u16::from(*reg) << 9 | offset);
    }

    fn encode_offset6_op(&mut self, opcode: u16, name: &str, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::Register(reg1),
                ..
            },
            Spanned {
                value: Operand::Register(reg2),
                ..
            },
            Spanned {
                value: Operand::Number(offset),
                location,
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(
                operation.location,
                format!("{name} expects two registers and an offset operand"),
            );
            return;
        };

        let Some(offset) = self.get_offset6(*offset, *location) else {
            return;
        };

        self.words
            .push(opcode | u16::from(*reg1) << 9 | u16::from(*reg2) << 6 | offset);
    }

    fn encode_jmp(&mut self, is_jmpt: bool, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };
        let name = if is_jmpt { "JMPT" } else { "JMP" };

        let [
            Spanned {
                value: Operand::Register(reg),
                ..
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(
                operation.location,
                format!("{name} expects a base register operand"),
            );
            return;
        };

        let reg = u16::from(*reg) << 6;

        self.words.push(JMP_OPCODE | reg | u16::from(is_jmpt));
    }

    fn encode_ret(&mut self, is_rtt: bool, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };
        let name = if is_rtt { "RTT" } else { "RET" };

        let [] = operands.as_slice() else {
            self.add_diagnostic(operation.location, format!("{name} expects no operands"));
            return;
        };

        let reg = 7 << 6;

        self.words.push(JMP_OPCODE | reg | u16::from(is_rtt));
    }

    fn encode_jsr(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::Ident(label),
                location,
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(operation.location, "JSR expects a label operand");
            return;
        };

        let Some(offset) = self.get_offset11(label, *location) else {
            return;
        };

        self.words.push(JSR_OPCODE | 1 << 11 | offset);
    }

    fn encode_jsrr(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::Register(reg),
                ..
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(operation.location, "JSRR expects a register operand");
            return;
        };

        let reg = u16::from(*reg) << 6;

        self.words.push(JSR_OPCODE | reg);
    }

    fn encode_rti(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [] = operands.as_slice() else {
            self.add_diagnostic(operation.location, "RTI expects no operands");
            return;
        };

        self.words.push(RTI_OPCODE);
    }

    fn encode_blkw(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::Number(num),
                location,
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(operation.location, ".BLKW expects a single count operand");
            return;
        };

        if !(0..=65535).contains(num) {
            self.add_diagnostic(*location, ".BLKW operand must be positive 16 bit number");
            return;
        }

        let num = usize::try_from(*num).expect("Operand is positive");

        self.words.extend(std::iter::repeat_n(0, num));
    }

    fn encode_stringz(&mut self, statement: &ParsedStatement) {
        let ParsedStatement::Operation {
            operands,
            operation,
            ..
        } = statement
        else {
            return;
        };

        let [
            Spanned {
                value: Operand::StringLiteral(string),
                location,
            },
        ] = operands.as_slice()
        else {
            self.add_diagnostic(
                operation.location,
                ".STRINGZ expects a single string operand",
            );
            return;
        };

        if string.len() > 65534 {
            self.add_diagnostic(*location, "string size out of bounds");
            return;
        }

        if !string.is_ascii() {
            self.add_diagnostic(*location, "string only supports ascii");
            return;
        }

        self.words.extend(string.bytes().map(u16::from));
        self.words.push(0);
    }
}

pub fn encode(statements: &[ParsedStatement]) -> Result<MemoryImage, Vec<Diagnostic>> {
    let mut encoder = Encoder::default();
    let skip = encoder.read_origin(statements);
    encoder.build_symbol_table(statements);

    for statement in statements.iter().skip(skip) {
        if encoder.saw_end {
            encoder.diagnostics.push(Diagnostic::new(
                statement.location(),
                "statement after .END",
            ));
            continue;
        }

        match statement {
            ParsedStatement::Label { .. } => {}
            ParsedStatement::Operation { operation, .. } => match operation.value {
                Operation::Fill => encoder.encode_fill(statement),
                Operation::End => encoder.read_end(),
                Operation::Orig => {
                    encoder.add_diagnostic(operation.location, "nested .ORIG is not supported");
                }
                Operation::Trap => encoder.encode_trap(statement),
                Operation::Add => encoder.encode_imm5_op(ADD_OPCODE, "ADD", statement),
                Operation::And => encoder.encode_imm5_op(AND_OPCODE, "AND", statement),
                Operation::Not => encoder.encode_not(statement),
                Operation::Br { .. } => encoder.encode_br(statement),
                Operation::Ld => encoder.encode_offset9_op(LD_OPCODE, "LD", statement),
                Operation::Ldi => encoder.encode_offset9_op(LDI_OPCODE, "LDI", statement),
                Operation::Ldr => encoder.encode_offset6_op(LDR_OPCODE, "LDR", statement),
                Operation::Lea => encoder.encode_offset9_op(LEA_OPCODE, "LEA", statement),
                Operation::St => encoder.encode_offset9_op(ST_OPCODE, "ST", statement),
                Operation::Sti => encoder.encode_offset9_op(STI_OPCODE, "STI", statement),
                Operation::Str => encoder.encode_offset6_op(STR_OPCODE, "STR", statement),
                Operation::Jmp => encoder.encode_jmp(false, statement),
                Operation::Jmpt => encoder.encode_jmp(true, statement),
                Operation::Ret => encoder.encode_ret(false, statement),
                Operation::Rtt => encoder.encode_ret(true, statement),
                Operation::Jsr => encoder.encode_jsr(statement),
                Operation::Jsrr => encoder.encode_jsrr(statement),
                Operation::Rti => encoder.encode_rti(statement),
                Operation::Blkw => encoder.encode_blkw(statement),
                Operation::Stringz => encoder.encode_stringz(statement),
            },
        }
    }

    if !encoder.saw_end {
        encoder.add_diagnostic(SourceLocation::default(), "expected .END");
    }

    if encoder.diagnostics.is_empty() {
        Ok(MemoryImage::new(encoder.origin, encoder.words))
    } else {
        Err(encoder.diagnostics)
    }
}
