use crate::{
    Diagnostic, SourceLocation,
    lexer::{SpannedToken, Token, tokenize},
};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Operation {
    Add,
    And,
    Not,
    Trap,
    Br { n: bool, z: bool, p: bool },
    Ld,
    Ldi,
    Lea,
    St,
    Sti,
    Orig,
    End,
    Fill,
}

impl Operation {
    #[must_use]
    pub fn parse(token: &str) -> Option<Self> {
        let token = token.to_ascii_uppercase();

        if let Some(flags) = token.strip_prefix("BR") {
            return Self::parse_br(flags);
        }

        match token.as_str() {
            "ADD" => Some(Self::Add),
            "AND" => Some(Self::And),
            "NOT" => Some(Self::Not),
            "TRAP" => Some(Self::Trap),
            "LD" => Some(Self::Ld),
            "LDI" => Some(Self::Ldi),
            "LEA" => Some(Self::Lea),
            "ST" => Some(Self::St),
            "STI" => Some(Self::Sti),
            ".ORIG" => Some(Self::Orig),
            ".END" => Some(Self::End),
            ".FILL" => Some(Self::Fill),
            _ => None,
        }
    }

    fn parse_br(flags: &str) -> Option<Self> {
        match flags {
            "" | "NZP" => Some(Self::Br {
                n: true,
                z: true,
                p: true,
            }),
            "N" => Some(Self::Br {
                n: true,
                z: false,
                p: false,
            }),
            "NZ" => Some(Self::Br {
                n: true,
                z: true,
                p: false,
            }),
            "NP" => Some(Self::Br {
                n: true,
                z: false,
                p: true,
            }),
            "Z" => Some(Self::Br {
                n: false,
                z: true,
                p: false,
            }),
            "ZP" => Some(Self::Br {
                n: false,
                z: true,
                p: true,
            }),
            "P" => Some(Self::Br {
                n: false,
                z: false,
                p: true,
            }),
            _ => None,
        }
    }

    #[must_use]
    pub fn word_count(self) -> u16 {
        match self {
            Self::Br { .. }
            | Self::Add
            | Self::And
            | Self::Not
            | Self::Trap
            | Self::Fill
            | Self::Ld
            | Self::Ldi
            | Self::Lea
            | Self::St
            | Self::Sti => 1,
            Self::Orig | Self::End => 0,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Operand {
    Register(u8),
    Number(i32),
    Ident(String),
    StringLiteral(String),
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ParsedStatement {
    Label {
        label: Spanned<String>,
    },
    Operation {
        label: Option<Spanned<String>>,
        operation: Spanned<Operation>,
        operands: Vec<Spanned<Operand>>,
    },
}

impl ParsedStatement {
    #[must_use]
    pub const fn location(&self) -> SourceLocation {
        match self {
            Self::Label { label } => label.location,
            Self::Operation { operation, .. } => operation.location,
        }
    }

    #[must_use]
    pub const fn line(&self) -> usize {
        self.location().line
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Spanned<T> {
    pub value: T,
    pub location: SourceLocation,
}

impl<T> Spanned<T> {
    pub const fn new(value: T, location: SourceLocation) -> Self {
        Self { value, location }
    }
}

/// Parse LC-3 assembly source into labeled statements and raw operands.
///
/// # Errors
///
/// Returns a diagnostic when the token stream cannot be interpreted as LC-3
/// assembly statements.
pub fn parse_source(source: &str) -> Result<Vec<ParsedStatement>, Diagnostic> {
    tokenize(source)?
        .split(|spanned_token| spanned_token.token == Token::Newline)
        .map(parse_statement)
        .filter_map(Result::transpose)
        .collect()
}

fn parse_statement(tokens: &[SpannedToken]) -> Result<Option<ParsedStatement>, Diagnostic> {
    let Some(first) = tokens.first() else {
        return Ok(None);
    };

    let Token::Ident(first_ident) = &first.token else {
        return Err(Diagnostic::new(
            first.location,
            "expected operation or label",
        ));
    };

    let (label, operation, operand_tokens) = if let Some(operation) = Operation::parse(first_ident)
    {
        (None, Spanned::new(operation, first.location), &tokens[1..])
    } else if let Some(SpannedToken {
        token: Token::Ident(second_ident),
        location,
    }) = tokens.get(1)
    {
        if let Some(operation) = Operation::parse(second_ident) {
            (
                Some(Spanned::new(first_ident.clone(), first.location)),
                Spanned::new(operation, *location),
                &tokens[2..],
            )
        } else {
            return Err(Diagnostic::new(
                first.location,
                "expected operation or nothing after a label",
            ));
        }
    } else if tokens.get(1).is_some() {
        return Err(Diagnostic::new(
            tokens[1].location,
            "expected operation after label",
        ));
    } else {
        return Ok(Some(ParsedStatement::Label {
            label: Spanned::new(first_ident.clone(), first.location),
        }));
    };

    let operands = parse_operands(operand_tokens)?;

    Ok(Some(ParsedStatement::Operation {
        label,
        operation,
        operands,
    }))
}

fn parse_operands(tokens: &[SpannedToken]) -> Result<Vec<Spanned<Operand>>, Diagnostic> {
    let mut operands = vec![];

    for spanned_token in tokens {
        let operand = match &spanned_token.token {
            Token::Comma => continue,
            Token::Register(val) => Operand::Register(*val),
            Token::Number(val) => Operand::Number(*val),
            Token::StringLiteral(val) => Operand::StringLiteral(val.clone()),
            Token::Ident(val) => Operand::Ident(val.clone()),
            _ => {
                return Err(Diagnostic::new(
                    spanned_token.location,
                    "error parsing operand: expected register, number, string or ident",
                ));
            }
        };

        operands.push(Spanned::new(operand, spanned_token.location));
    }

    Ok(operands)
}

#[cfg(test)]
mod tests {
    use super::{Operand, Operation, ParsedStatement, parse_source};

    fn statement_line(statement: &ParsedStatement) -> usize {
        statement.line()
    }

    fn label_value(statement: &ParsedStatement) -> Option<&str> {
        match statement {
            ParsedStatement::Label { label, .. } => Some(label.value.as_str()),
            ParsedStatement::Operation { label, .. } => {
                label.as_ref().map(|label| label.value.as_str())
            }
        }
    }

    fn operation_value(statement: &ParsedStatement) -> Option<Operation> {
        match statement {
            ParsedStatement::Label { .. } => None,
            ParsedStatement::Operation { operation, .. } => Some(operation.value),
        }
    }

    fn operand_values(statement: &ParsedStatement) -> Vec<Operand> {
        match statement {
            ParsedStatement::Label { .. } => Vec::new(),
            ParsedStatement::Operation { operands, .. } => operands
                .iter()
                .map(|operand| operand.value.clone())
                .collect(),
        }
    }

    #[test]
    fn parses_multiline_assembly_into_statements() {
        let source = r".ORIG x3000
START ADD R1, R2, R3 ; comment
     TRAP x25
.END
";

        let statements = parse_source(source).unwrap();

        assert_eq!(statements.len(), 4);

        assert_eq!(statement_line(&statements[0]), 1);
        assert_eq!(label_value(&statements[0]), None);
        assert_eq!(operation_value(&statements[0]), Some(Operation::Orig));
        assert_eq!(
            operand_values(&statements[0]),
            vec![Operand::Number(0x3000)]
        );

        assert_eq!(statement_line(&statements[1]), 2);
        assert_eq!(label_value(&statements[1]), Some("START"));
        assert_eq!(operation_value(&statements[1]), Some(Operation::Add));
        assert_eq!(
            operand_values(&statements[1]),
            vec![
                Operand::Register(1),
                Operand::Register(2),
                Operand::Register(3)
            ]
        );

        assert_eq!(statement_line(&statements[2]), 3);
        assert_eq!(label_value(&statements[2]), None);
        assert_eq!(operation_value(&statements[2]), Some(Operation::Trap));
        assert_eq!(operand_values(&statements[2]), vec![Operand::Number(0x25)]);

        assert_eq!(statement_line(&statements[3]), 4);
        assert_eq!(label_value(&statements[3]), None);
        assert_eq!(operation_value(&statements[3]), Some(Operation::End));
        assert!(operand_values(&statements[3]).is_empty());
    }

    #[test]
    fn parses_standalone_label_statement() {
        let source = r"LOOP
ADD R0, R0, #1
";

        let statements = parse_source(source).unwrap();

        assert_eq!(statements.len(), 2);
        assert_eq!(statement_line(&statements[0]), 1);
        assert_eq!(label_value(&statements[0]), Some("LOOP"));
        assert_eq!(operation_value(&statements[0]), None);
        assert!(operand_values(&statements[0]).is_empty());

        assert_eq!(statement_line(&statements[1]), 2);
        assert_eq!(label_value(&statements[1]), None);
        assert_eq!(operation_value(&statements[1]), Some(Operation::Add));
        assert_eq!(
            operand_values(&statements[1]),
            vec![
                Operand::Register(0),
                Operand::Register(0),
                Operand::Number(1)
            ]
        );
    }
}
