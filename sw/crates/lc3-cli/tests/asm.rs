use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Output},
    time::{SystemTime, UNIX_EPOCH},
};

fn run_lc3_cli(args: &[&str]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_lc3-cli"))
        .args(args)
        .output()
        .expect("lc3-cli should run")
}

fn temp_path(name: &str) -> PathBuf {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system time should be after UNIX epoch")
        .as_nanos();

    std::env::temp_dir().join(format!("lc3-cli-{name}-{}-{nanos}", std::process::id()))
}

fn temp_dir(name: &str) -> PathBuf {
    let path = temp_path(name);
    fs::create_dir(&path).expect("temp directory should be created");
    path
}

fn write_source(path: &Path, source: &str) {
    fs::write(path, source).expect("source should be written");
}

fn read_bytes(path: &Path) -> Vec<u8> {
    fs::read(path).expect("output should be readable")
}

fn read_to_string(path: &Path) -> String {
    fs::read_to_string(path).expect("output should be readable")
}

#[test]
fn asm_writes_object_file() {
    let source_path = temp_path("basic.asm");
    let obj_path = temp_path("basic.obj");

    write_source(
        &source_path,
        r"
.ORIG x3000
.FILL #42
.FILL xF025
.END
",
    );

    let output = run_lc3_cli(&[
        "asm",
        source_path.to_str().expect("source path should be UTF-8"),
        "--obj",
        obj_path.to_str().expect("object path should be UTF-8"),
    ]);

    assert!(
        output.status.success(),
        "expected success\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        read_bytes(&obj_path),
        vec![0x30, 0x00, 0x00, 0x2A, 0xF0, 0x25]
    );

    let _ = fs::remove_file(source_path);
    let _ = fs::remove_file(obj_path);
}

#[test]
fn asm_defaults_object_and_symbol_paths_to_input_stem() {
    let dir = temp_dir("default-output");
    let source_path = dir.join("program.asm");
    let obj_path = dir.join("program.obj");
    let sym_path = dir.join("program.sym");

    write_source(
        &source_path,
        r"
.ORIG x3000
START ADD R1, R2, R3
DATA .FILL START
.END
",
    );

    let output = run_lc3_cli(&[
        "asm",
        source_path.to_str().expect("source path should be UTF-8"),
    ]);

    assert!(
        output.status.success(),
        "expected success\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        read_bytes(&obj_path),
        vec![
            0x30, 0x00, // origin
            0x12, 0x83, // START ADD R1, R2, R3
            0x30, 0x00, // DATA .FILL START
        ]
    );
    assert_eq!(
        read_to_string(&sym_path),
        "// Symbol table\n\
// Scope level 0:\n\
//\tSymbol Name       Page Address\n\
//\t----------------  ------------\n\
//\tDATA              3001\n\
//\tSTART             3000\n\
//\t$               3000\n"
    );

    let _ = fs::remove_dir_all(dir);
}

#[test]
fn asm_allows_object_and_symbol_path_overrides() {
    let dir = temp_dir("override-output");
    let source_path = dir.join("program.asm");
    let obj_path = dir.join("custom-output.obj");
    let sym_path = dir.join("custom-symbols.sym");

    write_source(
        &source_path,
        r"
.ORIG x3000
START ADD R1, R2, R3
DATA .FILL START
.END
",
    );

    let output = run_lc3_cli(&[
        "asm",
        source_path.to_str().expect("source path should be UTF-8"),
        "--obj",
        obj_path.to_str().expect("object path should be UTF-8"),
        "--sym",
        sym_path.to_str().expect("symbol path should be UTF-8"),
    ]);

    assert!(
        output.status.success(),
        "expected success\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        read_bytes(&obj_path),
        vec![
            0x30, 0x00, // origin
            0x12, 0x83, // START ADD R1, R2, R3
            0x30, 0x00, // DATA .FILL START
        ]
    );
    assert_eq!(
        read_to_string(&sym_path),
        "// Symbol table\n\
// Scope level 0:\n\
//\tSymbol Name       Page Address\n\
//\t----------------  ------------\n\
//\tDATA              3001\n\
//\tSTART             3000\n\
//\t$               3000\n"
    );

    let _ = fs::remove_dir_all(dir);
}

#[test]
fn asm_writes_object_for_labels_and_pseudo_ops() {
    let source_path = temp_path("pseudo.asm");
    let obj_path = temp_path("pseudo.obj");

    write_source(
        &source_path,
        r#"
.ORIG x3000
MESSAGE .STRINGZ "HI"
PTR .FILL MESSAGE
SPACE .BLKW #2
NEXT .FILL NEXT
.END
"#,
    );

    let output = run_lc3_cli(&[
        "asm",
        source_path.to_str().expect("source path should be UTF-8"),
        "--obj",
        obj_path.to_str().expect("object path should be UTF-8"),
    ]);

    assert!(
        output.status.success(),
        "expected success\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );
    assert_eq!(
        read_bytes(&obj_path),
        vec![
            0x30, 0x00, // origin
            0x00, 0x48, // 'H'
            0x00, 0x49, // 'I'
            0x00, 0x00, // string terminator
            0x30, 0x00, // PTR .FILL MESSAGE
            0x00, 0x00, // SPACE .BLKW #2
            0x00, 0x00, 0x30, 0x06, // NEXT .FILL NEXT
        ]
    );

    let _ = fs::remove_file(source_path);
    let _ = fs::remove_file(obj_path);
}

#[test]
fn asm_reports_diagnostics_and_does_not_write_object() {
    let source_path = temp_path("bad.asm");
    let obj_path = temp_path("bad.obj");

    write_source(
        &source_path,
        r"
.ORIG x3000
ADD R1, R2
.END
",
    );

    let output = run_lc3_cli(&[
        "asm",
        source_path.to_str().expect("source path should be UTF-8"),
        "--obj",
        obj_path.to_str().expect("object path should be UTF-8"),
    ]);

    assert!(
        !output.status.success(),
        "expected failure\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("line 3"), "stderr was:\n{stderr}");
    assert!(stderr.contains("ADD"), "stderr was:\n{stderr}");
    assert!(!obj_path.exists());

    let _ = fs::remove_file(source_path);
}
