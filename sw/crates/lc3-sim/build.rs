#[cfg(feature = "verilator")]
use std::{
    env, fs,
    path::{Path, PathBuf},
};

#[cfg(not(feature = "verilator"))]
fn main() {}

#[cfg(feature = "verilator")]
fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR"));
    let sw_dir = manifest_dir
        .ancestors()
        .nth(2)
        .expect("lc3-sim should live under sw/crates/lc3-sim");
    let repo_dir = sw_dir.parent().expect("sw should have a parent directory");
    let verilator_dir = sw_dir.join("verilator");
    let verilator_build_dir = sw_dir.join("target/verilator");
    let generated_all = verilator_build_dir.join("Vlc3_verilator_top__ALL.cpp");
    let generated_makefile = verilator_build_dir.join("Vlc3_verilator_top.mk");

    println!(
        "cargo:rerun-if-changed={}",
        verilator_dir.join("lc3_sim_ffi.h").display()
    );
    println!(
        "cargo:rerun-if-changed={}",
        verilator_dir.join("lc3_sim_ffi.cpp").display()
    );
    println!(
        "cargo:rerun-if-changed={}",
        verilator_dir.join("lc3_sim_core.h").display()
    );
    println!(
        "cargo:rerun-if-changed={}",
        verilator_dir.join("lc3_sim_core.cpp").display()
    );
    println!("cargo:rerun-if-changed={}", generated_all.display());
    println!("cargo:rerun-if-changed={}", generated_makefile.display());

    if !generated_all.exists() {
        panic!(
            "missing generated Verilator model at {}; run `make verilator-build` first",
            generated_all.display()
        );
    }

    let verilator_root = verilator_root_from_makefile(&generated_makefile)
        .or_else(verilator_root_from_env)
        .expect("could not find VERILATOR_ROOT; run `make verilator-build` or set VERILATOR_ROOT");

    let verilator_include = verilator_root.join("include");
    let verilator_vltstd = verilator_include.join("vltstd");

    cc::Build::new()
        .cpp(true)
        .std("c++17")
        .flag_if_supported("-Wno-unused-parameter")
        .flag_if_supported("-Wno-unused-variable")
        .flag_if_supported("-Wno-unused-but-set-variable")
        .flag_if_supported("-Wno-sign-compare")
        .include(repo_dir.join("rtl"))
        .include(&verilator_dir)
        .include(&verilator_build_dir)
        .include(&verilator_include)
        .include(&verilator_vltstd)
        .file(verilator_dir.join("lc3_sim_ffi.cpp"))
        .file(verilator_dir.join("lc3_sim_core.cpp"))
        .file(generated_all)
        .file(verilator_include.join("verilated.cpp"))
        .file(verilator_include.join("verilated_threads.cpp"))
        .compile("lc3_sim_verilator");
}

#[cfg(feature = "verilator")]
fn verilator_root_from_makefile(makefile: &Path) -> Option<PathBuf> {
    let contents = fs::read_to_string(makefile).ok()?;

    contents.lines().find_map(|line| {
        let (key, value) = line.split_once('=')?;
        (key.trim() == "VERILATOR_ROOT").then(|| PathBuf::from(value.trim()))
    })
}

#[cfg(feature = "verilator")]
fn verilator_root_from_env() -> Option<PathBuf> {
    env::var_os("VERILATOR_ROOT").map(PathBuf::from)
}
