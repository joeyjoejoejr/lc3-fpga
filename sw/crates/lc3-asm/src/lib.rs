use std::fmt::Display;

use lc3_image::MemoryImage;

use crate::{encoder::encode, lexer::LexError, listing::ProgramListing, parser::parse_source};

mod encoder;
pub mod lexer;
pub mod listing;
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

impl Display for Diagnostic {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "line {}:{}: {}",
            self.location.line, self.location.column, self.message
        )
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Assembly {
    pub diagnostics: Vec<Diagnostic>,
    pub image: Option<MemoryImage>,
    pub listing: ProgramListing,
}

impl Assembly {
    /// Return the loadable image, or the diagnostics that prevented one.
    ///
    /// # Errors
    ///
    /// Returns the collected diagnostics when assembly did not produce an image.
    pub fn into_image(self) -> Result<MemoryImage, Vec<Diagnostic>> {
        self.image.ok_or(self.diagnostics)
    }
}

/// Assemble PennSim-style LC-3 source into an assembly report.
#[must_use]
pub fn assemble(source: &str) -> Assembly {
    match parse_source(source) {
        Ok(statements) => {
            let encoded = encode(&statements);
            Assembly {
                image: encoded.image,
                diagnostics: encoded.diagnostics,
                listing: encoded.listing,
            }
        }
        Err(diagnostic) => Assembly {
            image: None,
            diagnostics: vec![diagnostic],
            listing: ProgramListing::default(),
        },
    }
}
