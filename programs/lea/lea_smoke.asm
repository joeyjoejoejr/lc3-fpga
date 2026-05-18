        .ORIG x3000
        LEA R1, TARGET
        LEA R2, NEXT
NEXT
        HALT
TARGET
        .FILL xBEEF
        .END
