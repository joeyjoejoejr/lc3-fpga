        .ORIG x3000
        JSR SUBROUTINE
RETURN
        ADD R2, R2, #2
        HALT
SUBROUTINE
        ADD R1, R1, #1
        RET
        ADD R3, R3, #3
        .END
