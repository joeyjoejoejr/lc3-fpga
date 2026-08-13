use lc3_image::MemoryImage;

use crate::lexer::LexError;

pub mod lexer;
pub mod parser;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SourceLocation {
    pub line: usize,
    pub column: usize,
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
pub fn assemble(_source: &str) -> Result<Assembly, Vec<Diagnostic>> {
    Err(vec![Diagnostic {
        location: SourceLocation { line: 1, column: 1 },
        message: "assembler parser is not implemented yet".to_string(),
    }])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reports_unimplemented_parser() {
        let diagnostics = assemble(".ORIG x3000\nHALT\n.END\n").unwrap_err();

        assert_eq!(diagnostics.len(), 1);
        assert_eq!(
            diagnostics[0].message,
            "assembler parser is not implemented yet"
        );
    }
}
