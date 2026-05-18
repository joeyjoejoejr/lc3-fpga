# LC-3 FPGA

This is a small starter scaffold for building an LC-3 computer in SystemVerilog.
The first goal is not a complete CPU. The first goal is a clean simulation loop:

```sh
make test
```

The starter core currently proves reset and instruction fetch:

- reset sets `PC` to `x3000`
- the core reads one instruction from memory
- `PC` advances to the next word

## Assembling LC-3 Programs

This project uses the local copy of PennSim in `tools/PennSim.jar`:

```sh
make assemble
```

That assembles the files in `programs/add/*.asm` and converts PennSim `.obj`
files into `$readmemh`-friendly `.hex` files.

The ADD tests are set up but are expected to fail until the core executes more
than fetch:

```sh
make test-add
```

The AND smoke test is similarly available once ADD works:

```sh
make test-and
```

The NOT smoke test checks complementing zero and all ones:

```sh
make test-not
```

The BR smoke test checks taken and not-taken branches:

```sh
make test-br
```

The default test target stays on the passing fetch smoke test:

```sh
make test
```

## Suggested Milestones

1. Fetch one instruction from memory.
2. Decode opcode fields into readable wires.
3. Implement `ADD`, `AND`, and `NOT`.
4. Add condition codes `N/Z/P`.
5. Implement `BR`.
6. Add `LD`, `ST`, `LEA`.
7. Add `LDR`, `STR`, `LDI`, `STI`.
8. Add `JMP`, `JSR`, `JSRR`, `TRAP`.
9. Add memory-mapped I/O: keyboard, console, timer.
10. Add video framebuffer and HDMI scanout.

## Style Choice

The core should be RTL-level enough to synthesize to FPGA hardware, but it does
not need to reproduce the textbook LC-3 datapath gate-for-gate. A small
multi-cycle FSM is a good first implementation: fetch, decode, execute, memory,
writeback.

Once that works, you can decide whether to make a more textbook-style datapath
for learning value.

## References

- [Implementation roadmap](docs/implementation-roadmap.md)
- [Instruction formats](docs/instruction-formats.md)
