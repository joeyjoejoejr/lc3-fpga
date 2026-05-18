        .ORIG x3000
        AND R0, R0, #0
        ADD R0, R0, #1
        BRp POS_TAKEN
        ADD R1, R1, #15
POS_TAKEN
        ADD R2, R2, #2
        BRz BAD_ZERO
        ADD R3, R3, #3
        AND R4, R4, #0
        BRz ZERO_TAKEN
BAD_ZERO
        ADD R1, R1, #15
ZERO_TAKEN
        ADD R5, R5, #-1
        BRn NEG_TAKEN
        ADD R1, R1, #15
NEG_TAKEN
        HALT
        .END
