# Architecture Notes

## Behavioral vs. Textbook Datapath

For a first FPGA LC-3, prefer a synthesizable behavioral RTL design over a
literal reproduction of the textbook datapath.

Good first shape:

```text
registers + PC + IR + condition codes
        |
        v
multi-cycle control FSM
        |
        v
single memory interface
```

This still builds real hardware. It just lets SystemVerilog express some muxing
and control decisions directly instead of forcing every textbook bus and gate to
be named on day one.

The textbook datapath is still useful as the reference for state transitions:

```text
FETCH -> DECODE -> EVAL_ADDR/EXECUTE -> MEMORY -> WRITEBACK
```

## First CPU Feature

Start with `ADD` register/immediate form. It exercises:

- instruction decoding
- register reads
- ALU operation
- register writeback
- condition-code update

Then add `AND`, because it has the same instruction shape. Then add `NOT`,
because it is the simplest unary operation.

After that, add `BR`; branches force you to trust the condition codes and PC
update path.
