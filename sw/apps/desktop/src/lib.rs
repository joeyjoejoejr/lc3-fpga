use std::{fs, path::PathBuf};

use lc3_asm::{Assembly, assemble};
use lc3_image::DenseMemoryImage;

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

/// Open LC-3 program files and merge them into existing UI-ready state.
///
/// # Errors
///
/// Returns an error when the file type is unsupported, the file cannot be read,
/// or the program cannot be assembled/loaded.
pub fn open_program_paths(
    program: &mut LoadedProgram,
    paths: &[PathBuf],
) -> Result<(), LoadProgramError> {
    for path in paths {
        let source = fs::read_to_string(path)
            .map_err(|_| LoadProgramError::Io("failed to open file".to_owned()))?;
        program.load_image_from_asm(path.clone(), &source)?;
    }
    Ok(())
}
