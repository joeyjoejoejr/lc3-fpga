use std::{
    fs::{self, File},
    io::{Read, Write},
    path::PathBuf,
};

use clap::{Parser, Subcommand};
use lc3_asm::{Diagnostic, assemble};
use lc3_image::{DenseMemoryImage, MemoryImage};
use lc3_sim::Simulator;

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
    Sim {
        #[command(subcommand)]
        command: SimCommand,
    },
}

#[derive(Subcommand)]
enum SimCommand {
    Run {
        #[arg(required = true)]
        input: Vec<PathBuf>,
        #[arg(long, value_parser = parse_u16_address)]
        reset_pc: u16,
        #[arg(long)]
        max_cycles: u64,
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
    match cli.command {
        Command::Asm { .. } => run_asm(cli.command),
        Command::Sim { .. } => run_sim(cli.command),
    }
}

fn run_asm(command: Command) -> Result<(), String> {
    let Command::Asm { input, obj, sym } = command else {
        return Ok(());
    };

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

fn run_sim(command: Command) -> Result<(), String> {
    let Command::Sim {
        command:
            SimCommand::Run {
                input,
                reset_pc,
                max_cycles,
            },
    } = command
    else {
        return Ok(());
    };

    let mut images = vec![];

    for obj_file in &input {
        let bytes =
            fs::read(obj_file).map_err(|_| format!("cannot open file: {}", obj_file.display()))?;
        images.push(MemoryImage::try_from(bytes)?);
    }

    let dense_image = DenseMemoryImage::from_memory_images(&images)?;

    let mut simulator =
        Simulator::new(reset_pc, Some(max_cycles)).map_err(|err| err.to_string())?;
    simulator
        .load_dense_image(&dense_image)
        .map_err(|err| err.to_string())?;
    let report = simulator.run().map_err(|err| err.to_string())?;

    println!("{report}");
    Ok(())
}

fn parse_u16_address(raw: &str) -> Result<u16, String> {
    let raw = &raw.trim().to_ascii_lowercase();

    let digits = if let Some(hex) = raw.strip_prefix('x') {
        (hex, 16)
    } else if let Some(hex) = raw.strip_prefix("0x") {
        (hex, 16)
    } else if let Some(decimal) = raw.strip_prefix('#') {
        (decimal, 10)
    } else {
        (raw.as_str(), 10)
    };

    u16::from_str_radix(digits.0, digits.1).map_err(|_| format!("invalid LC-3 address: {raw}"))
}
