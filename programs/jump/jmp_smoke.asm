        .ORIG x3000
        LEA R0, TARGET
        JMP R0
        ADD R1, R1, #15
TARGET
        ADD R2, R2, #2
        HALT
        .END
