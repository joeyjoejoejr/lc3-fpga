# Implementation Roadmap

This order keeps each new instruction small while reusing pieces that already
work.

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

## 9. Later / Optional

```text
RTI
privilege mode
memory protection
interrupts
SD card loader
HDMI scanout
keyboard bridge
```

Leave these until the basic ISA and memory-mapped I/O are trustworthy.
