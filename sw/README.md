# LC-3 Software

This workspace holds the host-side software for the LC-3 FPGA project.

The long-term direction is:

- `lc3-asm`: PennSim-compatible assembler library
- `lc3-image`: shared memory image, object, and hex formats
- `lc3-cli`: command-line tools for assembling, loading, and driving simulation
- `apps/desktop`: native simulator/debugger UI
- `apps/web`: browser simulator/debugger UI
- `verilator`: RTL simulation harnesses and WebAssembly glue

The RTL remains the execution source of truth. Software frontends should drive
the Verilated LC-3 design instead of growing a separate instruction interpreter.

Run the software tests with:

```sh
cargo test --manifest-path sw/Cargo.toml
```

or from the repository root:

```sh
make sw-test
```

The assembler and CLI test suite includes PennSim golden comparisons. Those
tests assemble representative fixtures and real checked-in programs with both
PennSim and `lc3-cli`, then compare the emitted `.obj` bytes. PennSim remains a
test/reference tool only; the project-owned assembler does not depend on it at
runtime.

Current assembler CLI:

```sh
cargo run --manifest-path sw/Cargo.toml -p lc3-cli -- asm program.asm
cargo run --manifest-path sw/Cargo.toml -p lc3-cli -- asm program.asm --obj out.obj --sym out.sym
```
