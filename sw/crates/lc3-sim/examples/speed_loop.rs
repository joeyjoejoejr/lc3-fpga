use std::{env, fs, time::Instant};

use lc3_image::{DenseMemoryImage, MemoryImage};
use lc3_sim::Simulator;

const EXPECTED_INSTRUCTIONS: f64 = 2_003_001.0;
const RUNS: usize = 6; // First run warms up the process and simulator.

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let path = env::args().nth(1).ok_or("usage: speed_loop FILE.obj")?;
    let image = MemoryImage::try_from(fs::read(path)?)?;
    let dense = DenseMemoryImage::from_memory_images(&[image])?;
    let mut elapsed = Vec::with_capacity(RUNS - 1);

    for run in 0..RUNS {
        let mut sim =
            Simulator::new(0x3000, Some(100_000_000)).map_err(|error| error.to_string())?;
        sim.load_dense_image(&dense)
            .map_err(|error| error.to_string())?;

        let start = Instant::now();
        let report = sim.run().map_err(|error| error.to_string())?;
        let duration = start.elapsed();

        if report.pc != 0x3007 || report.ir != 0xD000 {
            return Err(format!("unexpected final report: {report}").into());
        }

        if run > 0 {
            println!(
                "Verilator run {run}: {:.3} s, {:.0} instructions/s ({} RTL cycles)",
                duration.as_secs_f64(),
                EXPECTED_INSTRUCTIONS / duration.as_secs_f64(),
                report.cycles,
            );
            elapsed.push(duration);
        }
    }

    elapsed.sort_unstable();
    let median = elapsed[elapsed.len() / 2];
    println!(
        "Verilator median: {:.3} s, {:.0} instructions/s",
        median.as_secs_f64(),
        EXPECTED_INSTRUCTIONS / median.as_secs_f64(),
    );

    Ok(())
}
