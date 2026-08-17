use std::{
    fs,
    path::{Path, PathBuf},
    process::{Command, Output},
    time::{SystemTime, UNIX_EPOCH},
};

struct Fixture {
    name: &'static str,
    source: &'static str,
}

const FIXTURES: &[Fixture] = &[
    Fixture {
        name: "alu_and_branch",
        source: r"
.ORIG x3000
START ADD R1, R2, R3
ADD R4, R4, #-1
AND R5, R5, #0
NOT R6, R6
BRnzp DONE
DONE HALT
.END
",
    },
    Fixture {
        name: "trap_aliases",
        source: r"
.ORIG x3000
GETC
OUT
PUTS
IN
PUTSP
HALT
.END
",
    },
    Fixture {
        name: "pc_relative_memory",
        source: r"
.ORIG x3000
LD R0, VALUE
LDI R1, PTR
LEA R2, VALUE
ST R0, STORE_SLOT
STI R1, PTR
BRp DONE
STORE_SLOT .BLKW #1
PTR .FILL VALUE
VALUE .FILL x1234
DONE HALT
.END
",
    },
    Fixture {
        name: "base_offset_and_control",
        source: r"
.ORIG x3000
LEA R0, DATA
LDR R1, R0, #0
STR R1, R0, #1
JSR ROUTINE
JSRR R3
JMP R7
ROUTINE RET
DATA .BLKW #2
.END
",
    },
    Fixture {
        name: "pseudo_ops_and_string_escapes",
        source: r#"
.ORIG x3000
MESSAGE .STRINGZ "A\nB\tC\"D\0E"
UNKNOWN .STRINGZ "A\\B\x41C\rD\bE\'F"
SPACE .BLKW #2
PTR .FILL MESSAGE
.FILL UNKNOWN
.END
"#,
    },
    Fixture {
        name: "rti",
        source: r"
.ORIG x0200
RTI
.END
",
    },
];

fn run_lc3_cli(args: &[&str]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_lc3-cli"))
        .args(args)
        .output()
        .expect("lc3-cli should run")
}

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(3)
        .expect("crate should live under sw/crates/lc3-cli")
        .to_path_buf()
}

fn temp_dir(name: &str) -> PathBuf {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system time should be after UNIX epoch")
        .as_nanos();
    let path = std::env::temp_dir().join(format!(
        "lc3-cli-golden-{name}-{}-{nanos}",
        std::process::id()
    ));

    fs::create_dir(&path).expect("temp directory should be created");
    path
}

fn assemble_with_pennsim(source_path: &Path) -> Output {
    let project_root = repo_root();
    let script_path = source_path.with_extension("pennsim-script");

    fs::write(
        &script_path,
        format!("as {}\nquit\n", source_path.display()),
    )
    .expect("PennSim script should be written");

    Command::new("java")
        .args([
            "-jar",
            project_root
                .join("tools/PennSim.jar")
                .to_str()
                .expect("PennSim jar path should be UTF-8"),
            "-t",
            "-s",
            script_path
                .to_str()
                .expect("PennSim script path should be UTF-8"),
        ])
        .output()
        .expect("PennSim should run")
}

#[test]
fn cli_object_output_matches_pennsim() {
    for fixture in FIXTURES {
        let dir = temp_dir(fixture.name);
        let source_path = dir.join(format!("{}.asm", fixture.name));
        let pennsim_obj_path = source_path.with_extension("obj");
        let our_obj_path = dir.join(format!("{}-ours.obj", fixture.name));
        let our_sym_path = dir.join(format!("{}-ours.sym", fixture.name));

        fs::write(&source_path, fixture.source).expect("fixture source should be written");

        let pennsim_output = assemble_with_pennsim(&source_path);
        assert!(
            pennsim_output.status.success(),
            "PennSim failed for {}\nstdout:\n{}\nstderr:\n{}",
            fixture.name,
            String::from_utf8_lossy(&pennsim_output.stdout),
            String::from_utf8_lossy(&pennsim_output.stderr)
        );
        assert!(
            pennsim_obj_path.exists(),
            "PennSim did not create an object for {}\nstdout:\n{}\nstderr:\n{}",
            fixture.name,
            String::from_utf8_lossy(&pennsim_output.stdout),
            String::from_utf8_lossy(&pennsim_output.stderr)
        );

        let cli_output = run_lc3_cli(&[
            "asm",
            source_path.to_str().expect("source path should be UTF-8"),
            "--obj",
            our_obj_path.to_str().expect("object path should be UTF-8"),
            "--sym",
            our_sym_path.to_str().expect("symbol path should be UTF-8"),
        ]);
        assert!(
            cli_output.status.success(),
            "lc3-cli failed for {}\nstdout:\n{}\nstderr:\n{}",
            fixture.name,
            String::from_utf8_lossy(&cli_output.stdout),
            String::from_utf8_lossy(&cli_output.stderr)
        );

        assert_eq!(
            fs::read(&our_obj_path).expect("our object should be readable"),
            fs::read(&pennsim_obj_path).expect("PennSim object should be readable"),
            "object output differed for {}",
            fixture.name
        );

        let _ = fs::remove_dir_all(dir);
    }
}
