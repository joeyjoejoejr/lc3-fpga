        .ORIG x3000
EARLY_PTR
        .FILL EARLY_SLOT
        ADD R1, R1, #7
        STI R1, FORWARD_PTR
        ADD R2, R2, #-1
        STI R2, EARLY_PTR
        HALT
FORWARD_PTR
        .FILL FORWARD_SLOT
EARLY_SLOT
        .FILL x0000
FORWARD_SLOT
        .FILL x0000
        .END
