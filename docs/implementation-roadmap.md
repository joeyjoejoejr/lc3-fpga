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

The remaining work is mostly system integration: better physical input,
optional text rendering, program loading, and eventually a larger memory story.

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

For a 480x272 LCD, scale the LC-3 128x128 framebuffer by 2:

```text
128x128 -> 256x256
left/right margin: 112 pixels
top/bottom margin: 8 pixels
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
enough for the initial LC-3 RAM plus a 128x128 16-bit framebuffer.

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

### 9.1 Invaders Hardware Smoke

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

### 9.2 PS/2 Keyboard Input

Add direct PS/2 support after the UART keyboard path, not before it. UART remains
the development and debug input path.

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

### 9.3 Keyboard FIFO

The current keyboard path is intentionally small. A FIFO makes it much harder
to lose typed characters while the LC-3 is busy drawing:

```text
UART RX ASCII ----\
                  +--> small FIFO --> KBSR/KBDR
PS/2 ASCII  ------/
```

Depth 8 or 16 is enough for now. `KBDR` reads pop the FIFO. `KBSR[15]` is set
when the FIFO is not empty.

### 9.4 On-Screen Text Console

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

### 9.5 SD Card Loader

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
  section count
  entry/start policy
  checksum or simple version field

following sectors:
  section records with LC-3 address + word count + raw 16-bit words
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

### 9.6 Reset And Memory Initialization Policy

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

### 9.7 Memory Expansion

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

### 9.8 Later / Optional

```text
RTI
privilege mode
memory protection
interrupts
native USB keyboard host
file picker / boot menu
audio
HDMI scanout
```

Leave these until the basic standalone system is pleasant to use.
