        .ORIG x3000
EARLY_SLOT
        .FILL x0000
        ADD R1, R1, #7
        ST R1, LATE_SLOT
        ADD R2, R2, #-1
        ST R2, EARLY_SLOT
        HALT
LATE_SLOT
        .FILL x0000
        .END
