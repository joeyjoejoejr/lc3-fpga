use lc3_image::MemoryImage;

use crate::{
    Diagnostic, SourceLocation,
    parser::{Operand, Operation, ParsedStatement, Spanned},
};

const TRAP_OPCODE: u16 = 0xF000;
const ADD_OPCODE: u16 = 0x1000;
const AND_OPCODE: u16 = 0x5000;
const NOT_OPCODE: u16 = 0x903F;

pub fn encode(statements: &[ParsedStatement]) -> Result<MemoryImage, Vec<Diagnostic>> {
    let mut diagnostics = vec![];
    let (origin, skip) = read_origin(statements, &mut diagnostics);
    let mut words = vec![];
    let mut saw_end = false;

    for statement in statements.iter().skip(skip) {
        if saw_end {
            diagnostics.push(Diagnostic {
                location: statement.location(),
                message: "statement after .END".to_string(),
            });
            continue;
        }

        match statement {
            ParsedStatement::Label { .. } => {}
            ParsedStatement::Operation { operation, .. } => match operation.value {
                Operation::Fill => encode_fill(statement, &mut words, &mut diagnostics),
                Operation::End => saw_end = true,
                Operation::Orig => diagnostics.push(Diagnostic {
                    location: operation.location,
                    message: "nested .ORIG is not supported".to_string(),
                }),
                Operation::Trap => encode_trap(statement, &mut words, &mut diagnostics),
                Operation::Add => encode_add(statement, &mut words, &mut diagnostics),
                Operation::And => encode_and(statement, &mut words, &mut diagnostics),
                Operation::Not => encode_not(statement, &mut words, &mut diagnostics),
            },
        }
    }

    if !saw_end {
        diagnostics.push(Diagnostic {
            location: SourceLocation::default(),
            message: "expected .END".to_string(),
        });
    }

    if diagnostics.is_empty() {
        Ok(MemoryImage::new(origin, words))
    } else {
        Err(diagnostics)
    }
}

fn read_origin(statements: &[ParsedStatement], diagnostics: &mut Vec<Diagnostic>) -> (u16, usize) {
    let Some(first_statement) = statements.first() else {
        diagnostics.push(Diagnostic {
            location: SourceLocation::default(),
            message: "expected .ORIG but empty file found".to_string(),
        });
        return (0, 0);
    };

    let ParsedStatement::Operation {
        operation,
        operands,
        ..
    } = first_statement
    else {
        diagnostics.push(Diagnostic {
            location: first_statement.location(),
            message: "expected .ORIG before any labels".to_string(),
        });
        return (0, 0);
    };

    if operation.value != Operation::Orig {
        diagnostics.push(Diagnostic {
            location: first_statement.location(),
            message: "expected .ORIG as first statement".to_string(),
        });
        return (0, 0);
    }

    if let [operand] = operands.as_slice() {
        (
            read_address_operand(
                operand,
                ".ORIG expects a 16-bit, numeric address",
                diagnostics,
            )
            .unwrap_or(0),
            1,
        )
    } else {
        diagnostics.push(Diagnostic {
            location: operation.location,
            message: ".ORIG expects a single address operand".to_string(),
        });
        (0, 1)
    }
}

fn encode_fill(
    statement: &ParsedStatement,
    words: &mut Vec<u16>,
    diagnostics: &mut Vec<Diagnostic>,
) {
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
            read_word_operand(operand, ".FILL expects a 16-bit numeric value", diagnostics)
        {
            words.push(value);
        }
    } else {
        diagnostics.push(Diagnostic {
            location: operation.location,
            message: ".FILL expects a single numeric operand".to_string(),
        });
    }
}

fn encode_trap(
    statement: &ParsedStatement,
    words: &mut Vec<u16>,
    diagnostics: &mut Vec<Diagnostic>,
) {
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
            diagnostics.push(Diagnostic {
                location: operand.location,
                message: "TRAP expects a numeric vector".to_string(),
            });
            return;
        };

        if let Ok(vector) = u8::try_from(value) {
            words.push(TRAP_OPCODE | u16::from(vector));
        } else {
            diagnostics.push(Diagnostic {
                location: operand.location,
                message: "TRAP vector must fit in 8 bits".to_string(),
            });
        }
    } else {
        diagnostics.push(Diagnostic {
            location: operation.location,
            message: "TRAP expects a single vector operand".to_string(),
        });
    }
}

fn encode_add(
    statement: &ParsedStatement,
    words: &mut Vec<u16>,
    diagnostics: &mut Vec<Diagnostic>,
) {
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

            words.push(ADD_OPCODE | dr | sr1 | sr2);
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
                diagnostics.push(Diagnostic {
                    location: *location,
                    message: "imm5 value out of range".to_string(),
                });
                return;
            }

            let dr = u16::from(*dr) << 9;
            let sr1 = u16::from(*sr1) << 6;
            let imm_bit = 1 << 5;
            let imm = u16::try_from(*imm & 0x001F).expect("masked imm5 fits in u16");

            words.push(ADD_OPCODE | dr | sr1 | imm_bit | imm);
        }
        _ => {
            diagnostics.push(Diagnostic {
                location: operation.location,
                message: "ADD expects operands: destination register, source register, and 5 bit immediate value or second source".to_string(),
            });
        }
    }
}

fn encode_and(
    statement: &ParsedStatement,
    words: &mut Vec<u16>,
    diagnostics: &mut Vec<Diagnostic>,
) {
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

            words.push(AND_OPCODE | dr | sr1 | sr2);
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
                diagnostics.push(Diagnostic {
                    location: *location,
                    message: "imm5 value out of range".to_string(),
                });
                return;
            }

            let dr = u16::from(*dr) << 9;
            let sr1 = u16::from(*sr1) << 6;
            let imm_bit = 1 << 5;
            let imm = u16::try_from(*imm & 0x001F).expect("masked imm5 fits in u16");

            words.push(AND_OPCODE | dr | sr1 | imm_bit | imm);
        }
        _ => {
            diagnostics.push(Diagnostic {
                location: operation.location,
                message: "AND expects operands: destination register, source register, and 5 bit immediate value or second source".to_string(),
            });
        }
    }
}

fn encode_not(
    statement: &ParsedStatement,
    words: &mut Vec<u16>,
    diagnostics: &mut Vec<Diagnostic>,
) {
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
        diagnostics.push(Diagnostic {
            location: operation.location,
            message: "NOT expects a source and destination register as operands".to_string(),
        });
        return;
    };
    let dr = u16::from(*dr) << 9;
    let sr = u16::from(*sr) << 6;
    words.push(NOT_OPCODE | dr | sr);
}

fn read_address_operand(
    operand: &Spanned<Operand>,
    message: &str,
    diagnostics: &mut Vec<Diagnostic>,
) -> Option<u16> {
    let Operand::Number(value) = operand.value else {
        diagnostics.push(Diagnostic {
            location: operand.location,
            message: message.to_string(),
        });
        return None;
    };

    if let Ok(value) = u16::try_from(value) {
        Some(value)
    } else {
        diagnostics.push(Diagnostic {
            location: operand.location,
            message: message.to_string(),
        });
        None
    }
}

fn read_word_operand(
    operand: &Spanned<Operand>,
    message: &str,
    diagnostics: &mut Vec<Diagnostic>,
) -> Option<u16> {
    let Operand::Number(value) = operand.value else {
        diagnostics.push(Diagnostic {
            location: operand.location,
            message: message.to_string(),
        });
        return None;
    };

    if let Ok(value) = i16::try_from(value) {
        Some(value.cast_unsigned())
    } else if let Ok(value) = u16::try_from(value) {
        Some(value)
    } else {
        diagnostics.push(Diagnostic {
            location: operand.location,
            message: message.to_string(),
        });
        None
    }
}
