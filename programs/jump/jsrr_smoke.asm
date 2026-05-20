        .ORIG x3000
        LEA R0, SUBROUTINE
        JSRR R0
RETURN
        ADD R4, R7, #0
        ADD R2, R2, #2
        HALT
SUBROUTINE
        ADD R1, R1, #1
        RET
        ADD R3, R3, #3
        .END
