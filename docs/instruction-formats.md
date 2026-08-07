# LC-3 Instruction Formats

Bit numbering:

```text
15                              0
```

All instructions use bits `[15:12]` as the opcode.

## BR

```text
15   12 11 10 9 8                     0
+-------+--+--+-+----------------------+
| 0000  | n| z|p| PCoffset9            |
+-------+--+--+-+----------------------+
```

```text
if (condition matches CC) PC <- PC + SEXT(PCoffset9)
```

## ADD

Register:

```text
15   12 11   9 8    6 5   3 2    0
+-------+------+-------+-----+------+
| 0001  | DR   | SR1   | 000 | SR2  |
+-------+------+-------+-----+------+
```

Immediate:

```text
15   12 11   9 8    6 5 4        0
+-------+------+-------+-+----------+
| 0001  | DR   | SR1   |1| imm5     |
+-------+------+-------+-+----------+
```

```text
DR <- SR1 + SR2
DR <- SR1 + SEXT(imm5)
set CC
```

## LD

```text
15   12 11   9 8                     0
+-------+------+----------------------+
| 0010  | DR   | PCoffset9            |
+-------+------+----------------------+
```

```text
DR <- MEM[PC + SEXT(PCoffset9)]
set CC
```

## ST

```text
15   12 11   9 8                     0
+-------+------+----------------------+
| 0011  | SR   | PCoffset9            |
+-------+------+----------------------+
```

```text
MEM[PC + SEXT(PCoffset9)] <- SR
```

## JSR / JSRR

JSR:

```text
15   12 11 10                    0
+-------+--+----------------------+
| 0100  |1 | PCoffset11           |
+-------+--+----------------------+
```

```text
R7 <- PC
PC <- PC + SEXT(PCoffset11)
```

JSRR:

```text
15   12 11 9 8    6 5             0
+-------+----+------+--------------+
| 0100  |000 | BaseR| 000000       |
+-------+----+------+--------------+
```

```text
R7 <- PC
PC <- BaseR
```

## AND

Register:

```text
15   12 11   9 8    6 5   3 2    0
+-------+------+-------+-----+------+
| 0101  | DR   | SR1   | 000 | SR2  |
+-------+------+-------+-----+------+
```

Immediate:

```text
15   12 11   9 8    6 5 4        0
+-------+------+-------+-+----------+
| 0101  | DR   | SR1   |1| imm5     |
+-------+------+-------+-+----------+
```

```text
DR <- SR1 & SR2
DR <- SR1 & SEXT(imm5)
set CC
```

## LDR

```text
15   12 11   9 8    6 5             0
+-------+------+-------+--------------+
| 0110  | DR   | BaseR | offset6      |
+-------+------+-------+--------------+
```

```text
DR <- MEM[BaseR + SEXT(offset6)]
set CC
```

## STR

```text
15   12 11   9 8    6 5             0
+-------+------+-------+--------------+
| 0111  | SR   | BaseR | offset6      |
+-------+------+-------+--------------+
```

```text
MEM[BaseR + SEXT(offset6)] <- SR
```

## RTI

```text
15   12 11                         0
+-------+---------------------------+
| 1000  | 000000000000              |
+-------+---------------------------+
```

```text
return from interrupt
```

RTI is privileged in the LC-3. It is not needed for the first OS boot path, but
it is part of the course OS compatibility surface because the OS interrupt table
can vector to a handler that executes `RTI`.

## NOT

```text
15   12 11   9 8    6 5             0
+-------+------+-------+--------------+
| 1001  | DR   | SR   | 111111       |
+-------+------+-------+--------------+
```

```text
DR <- ~SR
set CC
```

## LDI

```text
15   12 11   9 8                     0
+-------+------+----------------------+
| 1010  | DR   | PCoffset9            |
+-------+------+----------------------+
```

```text
DR <- MEM[MEM[PC + SEXT(PCoffset9)]]
set CC
```

## STI

```text
15   12 11   9 8                     0
+-------+------+----------------------+
| 1011  | SR   | PCoffset9            |
+-------+------+----------------------+
```

```text
MEM[MEM[PC + SEXT(PCoffset9)]] <- SR
```

## JMP / RET

```text
15   12 11 9 8    6 5             0
+-------+----+------+--------------+
| 1100  |000 | BaseR| 000000       |
+-------+----+------+--------------+
```

```text
PC <- BaseR
```

`RET` is:

```text
JMP R7
```

## JMPT

`JMPT` is a PennSim/course-OS extension used by the local `lc3os.asm` startup
code to jump from supervisor OS code into user code.

For the inspected OS object:

```text
JMP  R7  -> xC1C0
JMPT R7  -> xC1C1
```

So the instruction shape appears to be the normal `JMP` format with bit 0 set:

```text
15   12 11 9 8    6 5            1 0
+-------+----+------+-------------+-+
| 1100  |000 | BaseR| 00000       |1|
+-------+----+------+-------------+-+
```

Expected behavior for this project:

```text
PC <- BaseR
enter user mode
```

The exact privilege state should be represented through the PSR model described
in `docs/os-compatibility.md`.

## Reserved

```text
15   12 11                         0
+-------+---------------------------+
| 1101  | reserved                  |
+-------+---------------------------+
```

Opcode `1101` is unused in the standard LC-3 ISA.

## LEA

```text
15   12 11   9 8                     0
+-------+------+----------------------+
| 1110  | DR   | PCoffset9            |
+-------+------+----------------------+
```

```text
DR <- PC + SEXT(PCoffset9)
set CC
```

## TRAP

```text
15   12 11 8 7                     0
+-------+----+----------------------+
| 1111  |0000| trapvect8            |
+-------+----+----------------------+
```

```text
R7 <- PC
PC <- MEM[ZEXT(trapvect8)]
```

Common trap vectors:

```text
x20 GETC
x21 OUT
x22 PUTS
x23 IN
x24 PUTSP
x25 HALT
```

## Common Field Helpers

```systemverilog
logic [3:0] opcode;
logic [2:0] dr;
logic [2:0] sr;
logic [2:0] sr1;
logic [2:0] sr2;
logic [2:0] base_r;
logic [15:0] imm5;
logic [15:0] offset6;
logic [15:0] pc_offset9;
logic [15:0] pc_offset11;
logic [15:0] trapvect8;

assign opcode      = ir[15:12];
assign dr          = ir[11:9];
assign sr          = ir[11:9];
assign sr1         = ir[8:6];
assign sr2         = ir[2:0];
assign base_r      = ir[8:6];
assign imm5        = {{11{ir[4]}}, ir[4:0]};
assign offset6     = {{10{ir[5]}}, ir[5:0]};
assign pc_offset9  = {{7{ir[8]}}, ir[8:0]};
assign pc_offset11 = {{5{ir[10]}}, ir[10:0]};
assign trapvect8   = {8'h00, ir[7:0]};
```
