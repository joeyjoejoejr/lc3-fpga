use lc3_image::MemoryImage;

use crate::{
    lexer::LexError,
    parser::{Operand, Operation, ParsedStatement, Spanned, parse_source},
};

pub mod lexer;
pub mod parser;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SourceLocation {
    pub line: usize,
    pub column: usize,
}

impl Default for SourceLocation {
    fn default() -> Self {
        Self { line: 1, column: 1 }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Diagnostic {
    pub location: SourceLocation,
    pub message: String,
}

impl From<LexError> for Diagnostic {
    fn from(value: LexError) -> Self {
        Self {
            location: value.location,
            message: value.message,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Assembly {
    pub image: MemoryImage,
}

/// Assemble PennSim-style LC-3 source into an origin-addressed memory image.
///
/// # Errors
///
/// Returns diagnostics when the source cannot be parsed or encoded.
pub fn assemble(source: &str) -> Result<Assembly, Vec<Diagnostic>> {
    let statements = parse_source(source).map_err(|err| vec![err])?;

    let image = encode(&statements)?;

    Ok(Assembly { image })
}

fn encode(statements: &[ParsedStatement]) -> Result<MemoryImage, Vec<Diagnostic>> {
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
                _ => diagnostics.push(Diagnostic {
                    location: operation.location,
                    message: format!("{:?} encoding is not implemented yet", operation.value),
                }),
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
