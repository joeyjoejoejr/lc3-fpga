use std::fs;

use lc3_desktop::{LoadedProgram, open_program_path};

fn assert_be_word(bytes: &[u8], address: usize, word: u16) {
    assert_eq!(
        &bytes[(address * 2)..(address * 2 + 2)],
        &word.to_be_bytes()
    );
}

#[test]
fn loaded_program_starts_empty() {
    let program = LoadedProgram::new();

    assert!(program.assemblies.is_empty());
    assert_be_word(program.dense_image.be_bytes(), 0x3000, 0x0000);
}

#[test]
fn opens_asm_program_into_existing_loaded_program() {
    let temp_dir = tempfile::tempdir().expect("temp dir should be created");
    let asm_path = temp_dir.path().join("add.asm");
    fs::write(
        &asm_path,
        r"
.ORIG x3000
ADD R1, R2, R3
HALT
.END
",
    )
    .expect("asm fixture should be written");

    let mut program = LoadedProgram::new();
    open_program_path(&mut program, &asm_path).expect("asm program should open");

    assert_eq!(program.assemblies.len(), 1);

    let bytes = program.dense_image.be_bytes();
    assert_be_word(bytes, 0x3000, 0x1283);
    assert_be_word(bytes, 0x3001, 0xF025);
    assert_be_word(bytes, 0x2FFF, 0x0000);
    assert_be_word(bytes, 0x3002, 0x0000);

    let loaded = &program.assemblies[0];
    assert_eq!(loaded.path, asm_path);
    let assembly = &loaded.assembly;
    let image = assembly
        .image
        .as_ref()
        .expect("assembly should have an image");
    assert_eq!(image.origin(), 0x3000);
    assert_eq!(image.words().len(), 2);

    let rows = &assembly.listing.rows;
    assert_eq!(rows.len(), 4);
    assert_eq!(rows[0].line, 2);
    assert_eq!(rows[0].address, Some(0x3000));
    assert_eq!(rows[0].word_count, 0);
    assert_eq!(assembly.source_line(rows[0].line), Some(".ORIG x3000"));
    assert_eq!(rows[1].line, 3);
    assert_eq!(rows[1].address, Some(0x3000));
    assert_eq!(rows[1].word_count, 1);
    assert_eq!(assembly.source_line(rows[1].line), Some("ADD R1, R2, R3"));
    assert_eq!(rows[2].line, 4);
    assert_eq!(rows[2].address, Some(0x3001));
    assert_eq!(rows[2].word_count, 1);
    assert_eq!(assembly.source_line(rows[2].line), Some("HALT"));
    assert_eq!(rows[3].line, 5);
    assert_eq!(rows[3].address, Some(0x3002));
    assert_eq!(rows[3].word_count, 0);
    assert_eq!(assembly.source_line(rows[3].line), Some(".END"));
}

#[test]
fn opens_multiple_asm_programs_into_existing_loaded_program() {
    let temp_dir = tempfile::tempdir().expect("temp dir should be created");
    let first_path = temp_dir.path().join("first.asm");
    let second_path = temp_dir.path().join("second.asm");
    fs::write(
        &first_path,
        r"
.ORIG x3000
ADD R1, R2, R3
.END
",
    )
    .expect("first asm fixture should be written");
    fs::write(
        &second_path,
        r"
.ORIG x3100
HALT
.END
",
    )
    .expect("second asm fixture should be written");

    let mut program = LoadedProgram::new();
    open_program_path(&mut program, &first_path).expect("first asm program should open");
    open_program_path(&mut program, &second_path).expect("second asm program should open");

    assert_eq!(program.assemblies.len(), 2);
    assert_eq!(program.assemblies[0].path, first_path);
    let first_image = program.assemblies[0]
        .assembly
        .image
        .as_ref()
        .expect("first assembly should have an image");
    assert_eq!(first_image.origin(), 0x3000);
    assert_eq!(first_image.words().len(), 1);

    assert_eq!(program.assemblies[1].path, second_path);
    let second_image = program.assemblies[1]
        .assembly
        .image
        .as_ref()
        .expect("second assembly should have an image");
    assert_eq!(second_image.origin(), 0x3100);
    assert_eq!(second_image.words().len(), 1);

    let bytes = program.dense_image.be_bytes();
    assert_be_word(bytes, 0x3000, 0x1283);
    assert_be_word(bytes, 0x3100, 0xF025);
    assert_be_word(bytes, 0x3001, 0x0000);
    assert_be_word(bytes, 0x30FF, 0x0000);
}

#[test]
fn retains_failed_assembly_without_loading_an_image() {
    let temp_dir = tempfile::tempdir().expect("temp dir should be created");
    let asm_path = temp_dir.path().join("invalid.asm");
    fs::write(
        &asm_path,
        r"
.ORIG x3000
ADD R0, R0, #16
.END
",
    )
    .expect("asm fixture should be written");

    let mut program = LoadedProgram::new();
    open_program_path(&mut program, &asm_path)
        .expect("invalid assembly should still open for diagnostics");

    assert_eq!(program.assemblies.len(), 1);
    let loaded = &program.assemblies[0];
    assert_eq!(loaded.path, asm_path);
    assert!(loaded.assembly.image.is_none());
    assert_eq!(loaded.assembly.diagnostics.len(), 1);
    assert_eq!(
        loaded.assembly.diagnostics[0].message,
        "imm5 value out of range"
    );
    assert_eq!(loaded.assembly.listing.rows.len(), 3);
    assert_be_word(program.dense_image.be_bytes(), 0x3000, 0x0000);
}
