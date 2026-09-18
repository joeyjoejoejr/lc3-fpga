# PennSim execution-speed comparison

`pennsim_speed.asm` executes 2,003,001 instructions in a finite nested loop.
PennSim stops at a breakpoint just before the reserved opcode at `STOP`; the
Verilator-backed core halts on that opcode. Both runners verify the final PC.
Image loading and simulator construction are outside the timed interval. The
first run is discarded as warm-up, then five runs are timed and the median is
reported.

From the `sw` directory, with Java, Verilator, and Rust installed:

```sh
benchmark_dir="$(mktemp -d)"
cargo run -q -p lc3-cli -- asm benchmarks/pennsim_speed.asm \
  --obj "$benchmark_dir/loop.obj" --sym "$benchmark_dir/loop.sym"
javac -cp ../tools/PennSim.jar -d "$benchmark_dir" benchmarks/PennSimSpeed.java
java -cp "../tools/PennSim.jar:$benchmark_dir" PennSimSpeed "$benchmark_dir/loop.obj"
java -cp "../tools/PennSim.jar:$benchmark_dir" PennSimSpeed "$benchmark_dir/loop.obj" --gui
make -C .. verilator-build
cargo run --release -q -p lc3-sim --features verilator --example speed_loop -- "$benchmark_dir/loop.obj"
```

The GUI comparison opens and closes a visible PennSim window. It measures
PennSim's GUI execution, including event-loop overhead, but the Verilator runner
does not yet include the desktop UI. The headless PennSim run is useful for
isolating the execution engine; neither result is a fixed PennSim clock rate.

On an Apple M2 with Corretto 11 and Verilator 5.050 (2026-09-13), one run gave:

| Runner | Median elapsed | Effective instructions/s |
| --- | ---: | ---: |
| PennSim headless | 0.029 s | 68.4 million |
| PennSim GUI | 2.325 s | 0.861 million |
| Verilator core, release build | 0.422 s | 4.75 million |

On this fixture, the Verilator core is about 5.5 times faster than PennSim's
GUI, but about 14 times slower than PennSim headless. Re-run locally before
choosing a UI speed default; the result depends on the host and workload.
