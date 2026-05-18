        .ORIG x3000
        ADD R1, R1, #5
        ADD R2, R1, #3
        ADD R3, R2, R1
        ADD R4, R3, #-13
        ADD R5, R4, #-1
        HALT
        .END
