use std::{
    fs::File,
    io::{Read, Write},
    path::PathBuf,
};

use clap::{Parser, Subcommand};
use lc3_asm::{Diagnostic, assemble};

#[derive(Parser)]
#[command(name = "lc3")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Asm {
        input: PathBuf,
        #[arg(long)]
        obj: Option<PathBuf>,
        #[arg(long)]
        sym: Option<PathBuf>,
    },
}

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let cli = Cli::parse();
    let Command::Asm { input, obj, sym } = cli.command;
    let obj = obj.unwrap_or_else(|| input.with_extension("obj"));
    let sym = sym.unwrap_or_else(|| input.with_extension("sym"));

    let mut input_file = File::open(input).map_err(|_| "invalid input file")?;
    let mut input_contents = String::new();
    input_file
        .read_to_string(&mut input_contents)
        .map_err(|_| "failed to read file")?;

    let assembly = assemble(&input_contents).map_err(|diagnostics| {
        diagnostics
            .iter()
            .map(Diagnostic::to_string)
            .collect::<Vec<_>>()
            .join("\n")
    })?;

    let mut obj_file = File::create(obj).map_err(|_| "invalid output file")?;
    obj_file
        .write_all(&assembly.image.origin().to_be_bytes())
        .map_err(|_| "unable to write origin")?;
    obj_file
        .write_all(
            &assembly
                .image
                .words()
                .iter()
                .flat_map(|word| word.to_be_bytes())
                .collect::<Vec<_>>(),
        )
        .map_err(|_| "unable to write assembly")?;
    std::fs::write(sym, assembly.image.symbol_string()).map_err(|_| "unable to write symbols")?;
    Ok(())
}
