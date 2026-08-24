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

fn temp_dir(name: &str) -> PathBuf {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system time should be after UNIX epoch")
        .as_nanos();
    let path =
        std::env::temp_dir().join(format!("lc3-cli-sim-{name}-{}-{nanos}", std::process::id()));

    fs::create_dir(&path).expect("temp directory should be created");
    path
}

fn write_object(path: &Path, origin: u16, words: &[u16]) {
    let mut bytes = origin.to_be_bytes().to_vec();
    bytes.extend(words.iter().flat_map(|word| word.to_be_bytes()));

    fs::write(path, bytes).expect("object file should be written");
}

#[test]
#[ignore = "sim command is not implemented yet"]
fn sim_run_loads_multiple_objects_and_reports_final_state() {
    let dir = temp_dir("run-multiple-objects");
    let trap_vector_path = dir.join("trap-vector.obj");
    let program_path = dir.join("program.obj");

    write_object(&trap_vector_path, 0x0025, &[0x3002]);
    write_object(&program_path, 0x3000, &[0x1021, 0xF025, 0xD000]);

    let output = run_lc3_cli(&[
        "sim",
        "run",
        trap_vector_path
            .to_str()
            .expect("trap vector path should be UTF-8"),
        program_path.to_str().expect("program path should be UTF-8"),
        "--reset-pc",
        "x3000",
        "--max-cycles",
        "20",
    ]);

    let _ = fs::remove_dir_all(dir);

    assert!(
        output.status.success(),
        "expected success\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("pc: x3003"), "stdout was:\n{stdout}");
    assert!(stdout.contains("ir: xD000"), "stdout was:\n{stdout}");
}
