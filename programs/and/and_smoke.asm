        .ORIG x3000
        ADD R1, R1, #7
        ADD R2, R2, #3
        AND R3, R1, R2
        AND R4, R1, #0
        AND R5, R1, #-1
        HALT
        .END
