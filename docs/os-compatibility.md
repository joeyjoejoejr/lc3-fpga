# Course OS Compatibility

The new compatibility target is to run the same course OS image used by PennSim,
then load user programs at `x3000` without patching the OS for this FPGA.

The local OS file inspected for this project is:

```text
/Users/josephjackson/src/ECE-109-Pogram-1-main/lc3os.asm
```

The matching object and symbol files show:

```text
OS_START   x0200
GETC       x0020 -> x021D
OUT        x0021 -> x0221
PUTS       x0022 -> x0227
IN         x0023 -> x0234
PUTSP      x0024 -> x0240
HALT       x0025 -> x025F
BAD_TRAP          x0264
BAD_INT           x0265
```

## Memory Map Assumed By The OS

The OS and the Georgetown LC-3 extended microarchitecture notes agree on this
layout:

```text
x0000-x00FF  trap vector table
x0100-x01FF  interrupt vector table
x0200-x2FFF  operating system
x3000-xBFFF  user program and stack
xC000-xFDFF  video framebuffer
xFE00-xFFFF  device registers
```

The OS writes these device registers during normal startup or traps:

```text
xFE00 KBSR
xFE02 KBDR
xFE04 DSR
xFE06 DDR
xFE08 TMR
xFE0A TMI
xFE12 MPR
xFFFE MCR
```

The current system already has the keyboard, display, timer, framebuffer, and
MCR paths. The important missing device-register piece is `MPR` at `xFE12`.

Reference: the Georgetown extended LC-3 notes describe the same memory ranges,
device registers, PSR fields, and MPR page layout:

```text
https://people.cs.georgetown.edu/~squier/Teaching/HardwareFundamentals/LC3-trunk/docs/LC3-uArch-extended.html
```

## OS Boot Sequence

The OS starts at `x0200`. Its startup sequence is:

```text
write x0FF8 to MPR
write #40 to TMI
load R7 with x3000
JMPT R7
```

That means the FPGA needs a way to reset the LC-3 core to `x0200` when running
the real OS image. The current core reset path starts at `x3000`, which is
right for bare user programs but skips OS initialization.

`JMPT R7` is the first non-standard instruction needed by this OS. The assembled
object contains:

```text
JMP  R7  -> xC1C0
JMPT R7  -> xC1C1
```

So this OS uses the normal `JMP` encoding with bit 0 set as the `JMPT` variant.
The OS comment says `JMPT` clears the privilege bit while jumping into user
code.

## Privilege And Protection Work

For a first compatibility pass, it is reasonable to add the state before
enforcing every rule:

```text
PSR[15]    privilege: 1 supervisor, 0 user
PSR[10:8] interrupt priority
PSR[2:0]  condition codes
MPR[n]     user access allowed for page n, where each page is x1000 words
```

Suggested staged behavior:

1. Add `MPR` as a readable/writable register, but do not enforce it yet.
2. Add `JMPT` so the OS can jump to `x3000` and clear the privilege bit.
3. Patch OS trap-return `RET` instructions to `RTT` for FPGA smoke images.
4. Keep existing condition-code registers, but document their PSR mapping.
5. Add memory-protection checks once supervisor/user mode exists.
6. Add exceptions only after there is a working supervisor entry path.

The course OS family commonly uses plain `RET` (`xC1C0`) in trap handlers.
PennSim shows that this leaves execution in supervisor mode after trap return.
For stricter protected-mode compatibility, FPGA smoke images are built from OS
artifacts where those `RET` words are changed to `RTT` (`xC1C1`). The course
`lc3os` source is kept in-repo as `programs/os/lc3os_rtt.asm` with those edits.
For `p3os`, only an object file is available locally, so
`scripts/patch_os_ret_to_rtt.py` generates the patched object mechanically.

The OS writes `MPR = x0FF8`, which permits user access to `x3000-xBFFF`. That
matches normal user code and stack, but it deliberately excludes OS memory,
trap vectors, device registers, and video framebuffer from user-mode direct
access. Programs that write the video framebuffer directly may need either a
different MPR value or a course-specific policy decision.

## RTI And Interrupts

The inspected OS does not enable a real interrupt handler during normal startup,
but it does place `BAD_INT` in the interrupt vector table, and `BAD_INT`
contains `RTI`.

That makes `RTI` part of the compatibility surface even if it is not on the
shortest path to booting simple trap-based programs.

The interrupt-compatible design needs:

```text
RTI opcode x8000
supervisor/user mode transitions
R6 as user stack pointer vs supervisor stack pointer
interrupt vector table at x0100-x01FF
interrupt priority bits in PSR[10:8]
keyboard interrupt enable via KBSR[14]
timer interrupt policy, if enabled later
```

The current keyboard and timer devices are polling-compatible. Interrupts can
come after the real OS boot path, trap calls, and MPR register behavior are
working.

### Interrupt Reference Findings

The main open-source LC-3 simulators that clearly implement interrupts agree on
the architectural outline but differ in policy details:

```text
common behavior:
  accept an interrupt only if its priority is higher than PSR[10:8]
  save PC and PSR on the supervisor stack
  enter supervisor mode
  set the new priority
  load PC from the interrupt vector table
  return with RTI by restoring PC and PSR
```

Useful reference points:

```text
PennSim:
  strongest compatibility reference for OS layout, MPR, device addresses,
  privilege polarity, and timer polling, but its interrupt delivery behavior is
  weak or difficult to observe in the available jar.

lc3web:
  implements keyboard and display interrupts directly in JavaScript. Keyboard
  uses IVT entry x0180. It checks interrupts after instruction execution and
  pushes PC/PSR onto the current R6, without modeling separate user and
  supervisor stack pointers.

lc3tools:
  implements interrupt and exception entry as event/micro-op chains, with
  interrupt enter/exit callbacks and deterministic keyboard interrupt support.
  It follows the Patt/LC3Tools polarity where PSR[15]=1 means user mode.

complx-tools:
  implements pending interrupts, priorities, keyboard interrupt vector x80 at
  priority 4, explicit saved user/supervisor stack pointers, and RTI stack
  bookkeeping. This is the best source found for stack switching behavior.
```

For this FPGA, the recommended baseline is:

```text
keyboard interrupt vector:   x80
keyboard IVT entry:          x0180
keyboard priority:           4
keyboard interrupt enable:   KBSR[14]
interrupt timing:            check at instruction boundary before next fetch
stack model:                 add saved USP/SSP and swap R6 on privilege change
timer interrupts:            defer; keep timer polling as the compatibility path
```

## Recommended Implementation Order

1. Add a core/top parameter for reset PC, then run the OS image from `x0200`.
2. Add a test that executes the OS boot sequence through `JMPT R7`.
3. Add `MPR` read/write support at `xFE12`, initially without enforcement.
4. Add `JMPT` decode/execute as a `JMP` variant that also enters user mode
   by clearing `PSR[15]`.
5. Add a PSR/privilege skeleton and map existing NZP flags into PSR bits.
6. Replace temporary trap-vector shims with the generated RTT-patched OS object.
7. Add tests for GETC, OUT, PUTS, PUTSP, and HALT through the real OS.
8. Add `RTI` and interrupt-entry mechanics.
9. Add memory-protection enforcement and exception behavior.

This keeps the next steps testable while avoiding a jump straight into a large
interrupt/exception implementation.

## Multiple OS Images

Do not hard-code one OS layout as the only possible boot policy. Course
materials may use more than one OS image, and later user programs may run
without an OS at all.

The long-term SD boot image should carry metadata that describes how the image
wants to boot:

```text
entry_pc
initial supervisor/user mode
memory sections
required hardware features
display mode
console routing
keyboard source policy
```

That means an OS image can start at `x0200`, a bare program can start at
`x3000`, and a future test image can choose another entry point without changing
the synthesized CPU.

The Mac-side image builder should do the friendly validation. It can know that
one image requires a framebuffer and timer while another only needs text
console traps. The FPGA loader should keep a small hardware feature mask and
reject images whose required bits are not supported by the current bitstream.
