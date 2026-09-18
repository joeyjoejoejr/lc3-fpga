; 2,003,001 instructions before reaching STOP (for COUNT = 1000).
; The invalid opcode lets the RTL halt without loading an OS. PennSim stops
; at a breakpoint on STOP, before executing the invalid opcode.
.ORIG x3000
        LD R0, COUNT
OUTER   LD R1, COUNT
INNER   ADD R1, R1, #-1
        BRp INNER
        ADD R0, R0, #-1
        BRp OUTER
STOP    .FILL xD000
COUNT   .FILL #1000
.END
