use std::{fmt::Display, fs, path::PathBuf};

use lc3_asm::{Assembly, assemble};
use lc3_image::DenseMemoryImage;

#[derive(Debug)]
pub struct SourceRow<'a> {
    pub line: usize,
    pub address: Option<u16>,
    pub source: &'a str,
    pub words: &'a [u16],
}

#[derive(Debug)]
pub struct LoadedAssembly {
    pub path: PathBuf,
    pub assembly: Assembly,
}

#[derive(Debug, Default)]
pub struct LoadedProgram {
    pub dense_image: DenseMemoryImage,
    pub assemblies: Vec<LoadedAssembly>,
}

impl LoadedProgram {
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    fn load_image_from_asm(&mut self, path: PathBuf, asm: &str) -> Result<(), LoadProgramError> {
        let assembly = assemble(asm);

        if let Some(image) = assembly.image.as_ref() {
            self.dense_image
                .load_memory_images(std::slice::from_ref(image))
                .map_err(|err| LoadProgramError::Image(err))?;
        }

        self.assemblies.push(LoadedAssembly { path, assembly });
        Ok(())
    }
}

#[derive(Debug, Eq, PartialEq)]
pub enum LoadProgramError {
    UnsupportedFileType,
    Io(String),
    Image(String),
}

impl Display for LoadProgramError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::UnsupportedFileType => f.write_str("unsupported file type"),
            Self::Io(message) | Self::Image(message) => f.write_str(message),
        }
    }
}

impl std::error::Error for LoadProgramError {}

/// Open one LC-3 assembly file and merge its image into existing UI-ready state.
///
/// # Errors
///
/// Returns an error when the file type is unsupported, the file cannot be read,
/// or the program cannot be assembled/loaded.
pub fn open_program_path(
    program: &mut LoadedProgram,
    path: &PathBuf,
) -> Result<(), LoadProgramError> {
    let source = fs::read_to_string(path)
        .map_err(|_| LoadProgramError::Io("failed to open file".to_owned()))?;
    program.load_image_from_asm(path.clone(), &source)?;
    Ok(())
}

pub fn source_rows(assembly: &Assembly) -> Vec<SourceRow<'_>> {
    let mut rows = vec![];

    for listing_row in &assembly.listing.rows {
        rows.push(SourceRow {
            line: listing_row.line,
            address: listing_row.address,
            source: assembly.source_line(listing_row.line).unwrap_or(""),
            words: assembly.words_for(listing_row).unwrap_or(&[]),
        });
    }

    rows
}
