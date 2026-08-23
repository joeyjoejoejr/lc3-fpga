# Verilator Harnesses

This directory is reserved for the C++ and WebAssembly glue around the
Verilated LC-3 RTL model.

The goal is to let CLI, native GUI, and web frontends drive the same simulated
hardware design.

Current entry points:

- `make verilator-tools`: check that Verilator is installed
- `make verilator-lint`: lint the Verilator wrapper and core RTL
- `make verilator-build`: build the skeletal C++ simulation harness
- `make verilator-smoke`: run executable smoke tests for the harness

Generated Verilator files are written under `sw/target/verilator`, which is
ignored with the rest of the Rust/software build output.

The wrapper top intentionally stays small. It instantiates `lc3_core` with
`lc3_memory` and exposes a few top-level signals that the C++ harness can read.

Next implementation work:

- load assembler output into memory
- choose reset PC from the image metadata or CLI arguments
- add cycle/run controls
- expose registers and selected memory for inspection
- add console and keyboard hooks

The first smoke test expects the harness to accept a full 64K-word memory
image directly:

```sh
sw/target/verilator/Vlc3_verilator_top --memory memory.bin --reset-pc 0x3000 --cycles 20
```
