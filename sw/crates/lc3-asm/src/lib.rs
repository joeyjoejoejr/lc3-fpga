use lc3_image::MemoryImage;

use crate::{encoder::encode, lexer::LexError, parser::parse_source};

mod encoder;
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
        Self::new(value.location, value.message)
    }
}

impl Diagnostic {
    pub fn new(location: SourceLocation, message: impl Into<String>) -> Self {
        Self {
            location,
            message: message.into(),
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
