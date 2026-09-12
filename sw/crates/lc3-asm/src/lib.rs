use std::fmt::Display;

use lc3_image::MemoryImage;

use crate::{
    encoder::encode,
    lexer::LexError,
    listing::{ListingRow, ProgramListing},
    parser::parse_source,
};

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
    source: Vec<String>,
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

    pub fn source_line(&self, line: usize) -> Option<&str> {
        self.source.get(line.checked_sub(1)?).map(String::as_str)
    }

    pub fn words_for(&self, row: &ListingRow) -> Option<&[u16]> {
        let image = self.image.as_ref()?;
        let address = row.address?;
        let offset = address.checked_sub(image.origin())?;
        let start = usize::from(offset);
        let end = start.checked_add(row.word_count)?;

        image.words().get(start..end)
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
                source: source.lines().map(str::to_string).collect(),
            }
        }
        Err(diagnostic) => Assembly {
            image: None,
            diagnostics: vec![diagnostic],
            listing: ProgramListing::default(),
            source: source.lines().map(str::to_string).collect(),
        },
    }
}
