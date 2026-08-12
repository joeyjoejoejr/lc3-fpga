# Implementation Roadmap

This order keeps each new instruction small while reusing pieces that already
work.

## Current Status

The basic LC-3 system is now far enough along to run meaningful programs on the
Tang Nano 20K:

```text
done  core ISA smoke tests through TRAP
done  PC-relative, base-register, indirect, and jump/control-flow paths
done  memory controller with RAM, framebuffer, and device-register decode
done  KBSR/KBDR keyboard MMIO
done  DSR/DDR UART console MMIO
done  TSR/TIR timer MMIO
done  MCR machine halt at xFFFE
done  RGB LCD timing and LC-3 framebuffer scanout
done  UART RX/TX demos and LC-3 UART echo program
done  configurable FPGA init image and Invaders+OS image generation
done  Invaders+OS Makefile targets and README hardware-smoke notes
```

The remaining work has shifted toward compatibility with the unmodified course
OS image. Better physical input, SD loading, and larger memory still matter, but
the next CPU/system priority is running the real OS boot path instead of custom
trap shims.

## Updated Project Goals

The project is now aiming for one LC-3 system that can run on hardware and also
act as its own software reference model:

```text
1. Finish the FPGA build with full keyboard interrupt support.
2. Use Verilator to build a tier-1 command-line simulator from the RTL.
3. Build a self-contained native GUI around the same simulated system.
4. Build a web version from the Verilated model compiled to WebAssembly.
```

The important constraint is to keep the RTL as the source of truth. The command
line, native GUI, and web simulator should drive the same Verilated LC-3 design
rather than growing a second hand-written instruction interpreter.

## Assembler Direction

The native GUI and web simulator should include a built-in assembler so small
LC-3 programs can be edited, assembled, loaded, and run without a separate
PennSim install.

Build a project-owned assembler instead of embedding `lc3tools` for now.
`lc3tools` looks technically embeddable, but its repository-level Apache-2.0
license conflicts with source-file headers that say McGraw-Hill Education owns
the files and prohibits redistribution without written consent. Until that is
clarified, use it only as a behavioral reference.

Use PennSim as the primary compatibility reference:

```text
input:      PennSim-style LC-3 assembly source
output:     memory image suitable for the RTL simulator and FPGA image tools
optional:   PennSim-compatible .obj output if useful for cross-checking
diagnostic: source locations and clear parse/assembly errors for the GUI
```

Keep the assembler small and boring. A practical first version only needs the
course-visible LC-3 language:

```text
instructions: ADD AND NOT BR JMP JSR JSRR LD LDI LDR LEA ST STI STR TRAP RTI
pseudos:      .ORIG .END .FILL .BLKW .STRINGZ
labels:       normal symbol definition and forward references
literals:     decimal #n, hex xNNNN, character/string forms as PennSim accepts
output:       origin-addressed words, plus symbol/debug metadata for the UI
```

Suggested implementation layers:

```text
1. Lexer/parser for PennSim-compatible assembly lines.
2. First pass that records labels and section origins.
3. Second pass that encodes instructions and pseudo-ops.
4. Diagnostics that point at the source line/column where practical.
5. Golden comparisons against PennSim for representative programs.
6. Integration into the Verilator command-line simulator.
7. Native GUI and web/WASM bindings around the same assembler core.
```

Do not build a separate CPU interpreter as part of the assembler work. The
assembler can be ordinary host software, but execution should still happen
through the RTL-derived simulator.

Timer interrupts are not a required compatibility target yet. The references
inspected so far agree on keyboard interrupts much more strongly than timer
interrupts:

```text
keyboard interrupt: vector x80, IVT entry x0180, enabled by KBSR[14]
timer polling:      supported through TMR/TSR and TMI/TIR-style registers
timer interrupt:    simulator/course-specific extension, not a PennSim baseline
```

For the FPGA, keep the existing polling timer because programs already use it.
Add timer interrupts only later as an optional platform feature or plugin-like
device policy.

Full keyboard interrupt support includes the stack mechanism, not just the
pending/vector/priority interface: the first real implementation should add
hidden `USP`/`SSP` state so user-mode interrupts save `PC`/`PSR` on the
supervisor stack instead of the user stack. Use a core/top `initial_ssp`
parameter or boot metadata at first, then update the OS path to initialize the
supervisor stack deliberately.

## 1. Core ALU Instructions

```text
ADD
AND
NOT
```

These prove instruction fetch/decode, register reads, register writeback, and
condition-code updates.

## 2. Branching

```text
BR
```

Branches make the condition codes observable and useful. After `BR`, small test
programs can contain loops and conditional paths.

## 3. Simple PC-Relative Instructions

```text
LEA
LD
ST
```

`LEA` is a good first PC-relative instruction because it does not touch memory.
Then add `LD` and `ST` to exercise synchronous memory reads and writes.

## 4. Base-Register Memory Instructions

```text
LDR
STR
```

These reuse memory access but compute addresses from a base register plus a
sign-extended offset.

## 5. Control Flow

```text
JMP
JSR
JSRR
```

`JMP` is the simplest register-based PC update. `JSR` and `JSRR` add link
register behavior through `R7`.

## 6. Indirect Memory Instructions

```text
LDI
STI
```

These require two memory accesses, so they are easier after normal loads/stores
are solid.

## 7. Trap Support

```text
TRAP
```

Start with `TRAP x25` as HALT if needed. Later, load an LC-3 OS and implement
the full trap vector behavior:

```text
R7 <- PC
PC <- MEM[ZEXT(trapvect8)]
```

## 8. Memory-Mapped Devices

```text
xFE00 KBSR
xFE02 KBDR
xFE04 DSR
xFE06 DDR
xFE08 TSR
xFE0A TIR
xC000-xFDFF video framebuffer
```

These make console programs and PennSim-style graphics programs work.

Suggested implementation order:

### 8.1 Memory Controller Shell

Create a module that keeps the same simple CPU-facing interface:

```text
addr
wdata
we
rdata
```

Internally, decode the LC-3 address map:

```text
x0000-xBFFF  program/data RAM
xC000-xFDFF  framebuffer or extra RAM, depending on platform mode
xFE00-xFFFF  device registers
```

Start by making all non-device addresses behave like the existing synchronous
RAM. Device reads can return zero until each device is implemented.

For first board bring-up, add one custom LED register:

```text
xFE10 LED output register
```

A tiny top-level can then instantiate:

```text
board clock/reset
LC-3 core
memory controller
LED pins
```

and run a program that stores a value to `xFE10`. Seeing the LEDs change proves
that fetch, decode, memory writes, address decoding, and top-level pin wiring
are all alive on real hardware.

### 8.2 Framebuffer-As-RAM Mode

Before building video, prove that `xC000-xFDFF` can still act like ordinary
working memory when video is disabled. This lets text-only programs reclaim
that address range.

```text
video_enabled = 0: xC000-xFDFF behaves like RAM
video_enabled = 1: xC000-xFDFF is interpreted as pixels
```

### 8.3 Framebuffer Video Port

Add a second read port for the video pipeline:

```text
CPU port:   LC-3 reads/writes framebuffer words
video port: LCD scanout reads framebuffer pixels
```

On FPGA this should infer or instantiate dual-port block RAM. Keep the video
port read-only from the display side.

### 8.4 LCD Color Demo

Use the RGB LCD as the first real display target. It keeps the project
self-contained and avoids the HDMI TMDS encoder while still teaching real video
timing.

Start with a standalone LCD color demo:

```text
pixel clock -> LCD timing generator -> color bars -> RGB LCD pins
```

This should not involve the LC-3 core yet. Prove the panel pinout, clock, syncs,
data-enable, backlight, and reset/enable signals first.

### 8.5 LC-3 Framebuffer To LCD

After the color demo works, replace the color bars with a scaled LC-3
framebuffer:

```text
LCD x/y -> LC-3 framebuffer x/y -> video RAM read -> RGB pixel -> LCD
```

For a 480x272 LCD, scale the LC-3 128x124 framebuffer by 2:

```text
128x124 -> 256x248
left/right margin: 112 pixels
top/bottom margin: 12 pixels
```

The console should stay on UART at first. Do not build an on-screen text
terminal until the framebuffer path is working.

### 8.6 Console Output Registers

Implement the standard LC-3 display registers:

```text
xFE04 DSR  display status
xFE06 DDR  display data
```

At first, `DSR` can always report ready. Writes to `DDR` can be captured in a
testbench FIFO or debug register. Then connect `DDR` to UART TX. An on-screen
text console is optional later work.

### 8.7 Keyboard Input Registers

Implement:

```text
xFE00 KBSR  keyboard status
xFE02 KBDR  keyboard data
```

Start with testbench-controlled key injection. Then connect the same ready/data
interface to a UART keyboard adapter, PS/2 bridge, USB-host helper, or another
board-level input source.

### 8.8 Timer Registers

Implement the PennSim-style timer extension used by graphics programs:

```text
xFE08 TSR  timer status
xFE0A TIR  timer interval
```

The Space Invaders program writes an interval to `TIR` and polls `TSR` until
bit 15 becomes set. Start with a simple down-counter that sets `TSR[15]` when a
tick expires.

### 8.9 Trap/OS Integration

Once `TRAP` follows the vector table, load or seed the low-memory trap vector
entries:

```text
x0020 GETC
x0021 OUT
x0022 PUTS
x0023 IN
x0024 PUTSP
x0025 HALT
```

The OS routines use the memory-mapped device registers. The memory controller
does not implement `PUTS` directly; it only supplies the hardware registers the
OS code talks to.

### 8.10 FPGA Memory Choices

Use internal block RAM first. It has predictable synchronous timing and is
enough for the initial LC-3 RAM plus a 128x124 16-bit framebuffer.

External SDRAM can come later behind a handshake-based controller:

```text
request valid/write/address/data
ready
response valid/read data
```

Do not connect the CPU directly to SDRAM pins. Put an SDRAM controller between
the LC-3 memory map and the external memory.

## 9. Next Feature Order

This is the current recommended order from the present state of the project.

### 9.1 Course OS Compatibility

The project should use the same OS image that PennSim loads for the course.
That makes user programs more reproducible and avoids maintaining one-off trap
shims for each demo.

Known requirements from the local `lc3os.asm`:

```text
OS starts at x0200
user programs start at x3000
trap vector table lives at x0000-x00FF
interrupt vector table lives at x0100-x01FF
OS writes MPR at xFE12
OS writes TMI at xFE0A
OS enters user code with JMPT R7
BAD_INT contains RTI
```

Privilege polarity is a compatibility concern, not a universal LC-3 truth. The
course OS and PennSim behavior tested locally use:

```text
PSR[15] = 1  supervisor mode
PSR[15] = 0  user mode
```

This was verified with a PennSim probe that sets `MPR = x0FF8`, writes protected
memory at `x2000` before `JMPT`, then tries the same write after `JMPT`; the
pre-`JMPT` write succeeds and the post-`JMPT` write raises a protection
exception. PennSim documentation also describes `PSR[15] = 1` as supervisor
mode.

Other LC-3/LC-3b references, including Patt-style LC-3b material and some
extended LC-3 notes, use the opposite polarity:

```text
PSR[15] = 0  supervisor mode
PSR[15] = 1  user mode
```

That means future interrupt/exception work should not bake privilege polarity
deeply into the core. Add a compatibility mode flag before supporting both
families of software:

```text
privilege_mode_pennsim = 1:
  supervisor when PSR[15] == 1
  user       when PSR[15] == 0

privilege_mode_pennsim = 0:
  supervisor when PSR[15] == 0
  user       when PSR[15] == 1
```

Use helper predicates such as `is_supervisor_psr(psr)` and
`is_user_psr(psr)` so `MPR`, `RTI`, `JMPT`, interrupt entry, exception entry,
and stack switching all share the same polarity policy.

Suggested implementation order:

```text
todo  add a reset-PC parameter so OS builds can reset to x0200
todo  add MPR xFE12 as a readable/writable device register
todo  implement JMPT as the OS's jump-to-user instruction
todo  add PSR/privilege state, initially without full protection enforcement
todo  factor privilege checks through a PennSim-vs-LC3b compatibility flag
todo  run a small program through the unmodified OS trap table
todo  add RTI and interrupt-entry mechanics
todo  enforce MPR user-mode protection after supervisor/user mode works
```

See `docs/os-compatibility.md` for the inventory of OS assumptions and missing
hardware behavior.

### 9.2 Invaders Hardware Smoke

Use Invaders as the main system checkpoint because it exercises nearly every
existing subsystem at once:

```text
LC-3 core
OS trap vectors
MCR halt
timer polling
keyboard polling
framebuffer writes
LCD scanout
UART console output
```

Concrete tasks:

```text
done  document the exact make commands for Invaders+OS
done  document the expected memory size override
done  add a short known-good hardware smoke note
todo  decide whether reset should clear framebuffer/game RAM or only CPU state
```

For now, a power cycle reloads initialized BRAM from the flashed bitstream.
Button reset resets logic state but does not reload modified memory contents.

### 9.3 On-Screen Text Console

Keep the graphics framebuffer and console text as separate concepts:

```text
xC000-xFDFF framebuffer graphics
xFE04/xFE06 console character output
```

The first text console should mirror `DDR` writes to both UART TX and an LCD
text layer. Start with an overlay or a separate text-only mode; do not make
ordinary `PUTS` routines draw directly into the graphics framebuffer.

Suggested split:

```text
text_console
  Consume ASCII bytes.
  Maintain cursor position.
  Handle newline, carriage return, backspace, and clear.
  Write character cells into text RAM.

font_rom
  8x8 or 8x16 bitmap font.

video_mixer
  Choose framebuffer pixel, text pixel, or border/background color.
```

If UART mirroring is enabled, `DSR` should still be limited by UART TX ready.
The text console itself should usually be ready every cycle or use a tiny input
FIFO.

### 9.4 PS/2 Keyboard Input

Add direct PS/2 support after the LCD text console because PS/2 depends on
external wiring and soldering. UART remains the development and debug input
path.

Suggested split:

```text
ps2_rx
  Synchronize PS/2 clock/data.
  Detect falling edges of PS/2 clock.
  Shift start bit, 8 data bits, parity, and stop bit.
  Emit one scan code plus valid pulse.

ps2_scancode_to_ascii
  Track break codes.
  Track shift state.
  Translate set-2 scan codes to ASCII.
  Ignore extended keys at first.

keyboard_input_mux
  Accept ASCII from UART RX and PS/2.
  Feed the existing lc3_keyboard module.
```

Start with lowercase letters, space, enter, and digits. Then add shifted
punctuation if course programs need it.

### 9.5 Reset And Memory Initialization Policy

Decide this deliberately before more demos pile up:

```text
soft reset:
  reset CPU/devices only
  keep RAM/framebuffer contents

reload reset:
  restore initialized RAM/framebuffer
  useful for demos and games
```

The simplest hardware implementation is to keep the current soft reset and use
power-cycle or reprogramming to reload BRAM init contents. A reload reset can
come later through a boot controller that rewrites RAM before releasing the
core.

### 9.6 SD Card Loader

Use the microSD slot as a loader, not as LC-3 working memory.

Start in SPI mode using the SDIO pins:

```text
SDIO_CLK -> SPI SCLK
SDIO_CMD -> SPI MOSI
SDIO_D0  -> SPI MISO
SDIO_D3  -> SPI CS
```

Recommended first format:

```text
sector 0:
  magic
  version
  entry_pc
  initial mode/privilege
  required feature flags
  display/console/keyboard policy
  section count
  checksum

following sectors:
  section records with LC-3 address + word count + raw 16-bit words
```

The SD image should be produced by a Mac-side builder that combines the selected
OS, user program, and manifest. The builder should validate the image against a
target hardware profile before writing it:

```text
program manifest says:
  requires framebuffer, timer, keyboard, real OS
  entry_pc x0200
  display framebuffer
  console uart

target profile says:
  supports framebuffer, timer, keyboard, real OS, lcd text

builder:
  accepts the image and writes the feature flags into the header
```

The FPGA loader should repeat only cheap checks:

```text
magic/version recognized
checksum passes
required feature bits are supported by this bitstream
sections fit in implemented memory ranges
```

Boot flow:

```text
power on
hold LC-3 reset
try SD image
if valid, copy sections into RAM/framebuffer as needed
if invalid, keep bitstream default image
release LC-3 reset
```

Add FAT/file menus only after the raw-sector loader works. A Mac-side formatter
tool is much simpler than implementing a filesystem in RTL.

### 9.7 Optional Keyboard FIFO

The LC-3-style keyboard device is a single-character register. That is simpler
and more faithful than a typeahead queue:

```text
keyboard event arrives -> KBDR gets character and KBSR[15] sets
program reads KBDR    -> KBSR[15] clears
```

If real use shows missed characters, add a FIFO as a platform enhancement:

```text
UART RX ASCII ----\
                  +--> small FIFO --> KBSR/KBDR
PS/2 ASCII  ------/
```

Depth 8 or 16 is enough for now. `KBDR` reads pop the FIFO. `KBSR[15]` is set
when the FIFO is not empty. This can be parameterized so the faithful mode is
depth 1 and the friendly standalone mode uses a deeper queue.

### 9.8 Memory Expansion

Only move to SDRAM when a concrete program needs more than internal BRAM can
comfortably provide.

Before SDRAM, consider cheaper intermediate options:

```text
reduce default RAM size for framebuffer builds
make framebuffer optional for text-only builds
load only the OS/program regions actually needed
use internal BRAM for active RAM and keep SD as load-only storage
```

When SDRAM becomes necessary, add it behind a ready/valid memory interface and
test it independently before connecting it to the LC-3 core.

### 9.9 Later / Optional

```text
native USB keyboard host
file picker / boot menu
audio
HDMI scanout
```

The LC-3 privilege, protection, `RTI`, and interrupt work moved into the OS
compatibility path above.
