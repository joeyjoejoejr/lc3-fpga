        .ORIG x3000
EARLY_VALUE
        .FILL x00AA
        LD R1, POS_VALUE
        LD R2, NEG_VALUE
        LD R3, ZERO_VALUE
        LD R4, EARLY_VALUE
        HALT
POS_VALUE
        .FILL x1234
NEG_VALUE
        .FILL x8000
ZERO_VALUE
        .FILL x0000
        .END
