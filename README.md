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

## Invaders Hardware Smoke

The Invaders build combines `external/LC3Programs/Invaders/p3os.obj` with
`programs/top/invaders.asm` and uses a larger RAM setting so the OS and program
fit in initialized BRAM.

Build the Invaders bitstream:

```sh
make invaders-bitstream
```

Program the board SRAM:

```sh
make invaders-program
```

Flash the board so Invaders reloads after power cycling:

```sh
make invaders-flash
```

Expected hardware behavior:

- the LCD shows the LC-3 framebuffer
- keyboard input currently comes from UART RX
- console output is mirrored to UART TX
- the timer registers drive the game loop
- `HALT` stops the machine through MCR at `xFFFE`

The reset button resets CPU/device state, but it does not reload modified BRAM
or framebuffer contents. Power cycling after `make invaders-flash` reloads the
initialized image from flash.

## Real OS Console Smoke

The `andme` build combines the real course OS object with
`programs/top/andme.asm`, resets the LC-3 at `x0200`, and enables LCD text
console mode. This is the first small smoke test for booting through an
unmodified OS before running a user program at `x3000`.

Build the bitstream:

```sh
make andme-bitstream
```

Program the board SRAM:

```sh
make andme-program
```

Flash the board:

```sh
make andme-flash
```

By default, the Makefile expects the course OS object at:

```text
/Users/josephjackson/src/ECE-109-Pogram-1-main/lc3os.obj
```

Use another OS object by overriding `ANDME_OS_OBJ`:

```sh
make andme-bitstream ANDME_OS_OBJ=/path/to/lc3os.obj
```

The `ANDME_RESET_PC` Make variable is decimal by default to avoid shell quoting
issues with Verilog literals:

```text
512 = x0200
```

## Suggested Milestones

Most of the original CPU milestones are complete. The next priority is
compatibility with the unmodified course OS image, so ordinary LC-3 programs can
use the same trap routines, device registers, and boot path they use in PennSim.

The short version is:

1. Boot through the course OS at `x0200` instead of custom trap shims.
2. Add the OS compatibility pieces: `JMPT`, MPR at `xFE12`, PSR/privilege
   tracking, and eventually `RTI`/interrupt entry.
3. Replace the temporary `andme` trap shim with the real OS image.
4. Keep UART and LCD text output mirrored behind `DSR`/`DDR`.
5. Add direct PS/2 keyboard input after the OS path is solid.
6. Add an SD-card loader for user programs.
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
- [Course OS compatibility notes](docs/os-compatibility.md)
- [Instruction formats](docs/instruction-formats.md)
