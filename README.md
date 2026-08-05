# LC-3 FPGA

This is a small LC-3 computer in SystemVerilog, targeting simulation first and
the Tang Nano 20K FPGA board as the current hardware target.

The project now includes:

- a multi-cycle LC-3 core with the standard ISA smoke-tested through `TRAP`
- a memory controller with RAM, framebuffer, timer, keyboard, console, and MCR
- UART RX/TX for development console input/output
- RGB LCD timing and LC-3 framebuffer scanout
- build support for selecting FPGA program images

Run the full simulation suite with:

```sh
make test
```

## Assembling LC-3 Programs

This project uses the local copy of PennSim in `tools/PennSim.jar`:

```sh
make assemble
```

That assembles the files in `programs/add/*.asm` and converts PennSim `.obj`
files into `$readmemh`-friendly `.hex` files.

Individual instruction and subsystem tests are available while working on a
specific feature:

```sh
make test-fetch
make test-add
make test-and
make test-not
make test-br
make test-lea
make test-ld
make test-st
make test-ldr
make test-str
make test-jmp
make test-ret
make test-jsr
make test-jsrr
make test-ldi
make test-sti
make test-trap
make test-memory-controller
make test-timer
make test-keyboard
make test-framebuffer-reader
make test-top
make test-uart-tx
make test-uart-rx
```

## FPGA Builds

Build the current top-level bitstream:

```sh
make fpga-bitstream
```

Program the board SRAM:

```sh
make fpga-program
```

Flash the board so the design reloads after power cycling:

```sh
make fpga-flash
```

The default top-level program image is `programs/top/lc3_uart_echo.hex`.
Override it with `FPGA_INIT_HEX` and, when needed, `FPGA_RAM_WORDS`:

```sh
make fpga-bitstream \
  FPGA_INIT_HEX=programs/top/invaders_with_p3os.hex \
  FPGA_RAM_WORDS=13056
```

## Suggested Milestones

Most of the original CPU milestones are complete. The next useful milestones
are documented in detail in `docs/implementation-roadmap.md`, but the short
version is:

1. Make the Invaders+OS hardware build reproducible.
2. Add direct PS/2 keyboard input.
3. Add a small keyboard FIFO.
4. Add optional on-screen text console output.
5. Add an SD-card loader for user programs.
6. Decide reset/reload behavior.
7. Consider SDRAM only when a concrete program needs more memory.

## Style Choice

The core should be RTL-level enough to synthesize to FPGA hardware, but it does
not need to reproduce the textbook LC-3 datapath gate-for-gate. A small
multi-cycle FSM is a good first implementation: fetch, decode, execute, memory,
writeback.

Once that works, you can decide whether to make a more textbook-style datapath
for learning value.

## References

- [Implementation roadmap](docs/implementation-roadmap.md)
- [Architecture notes](docs/architecture-notes.md)
- [Instruction formats](docs/instruction-formats.md)
