        .ORIG x3000
        LEA R0, BASE
        ADD R1, R1, #7
        STR R1, R0, #1
        ADD R2, R2, #-1
        LEA R3, AFTER
        STR R2, R3, #-1
        HALT
BASE
        .FILL x0000
        .FILL x0000
        .FILL x0000
AFTER
        .END
