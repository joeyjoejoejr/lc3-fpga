        .ORIG x3000
        LEA R0, BASE
        LDR R1, R0, #1
        LDR R2, R0, #2
        LEA R3, AFTER
        LDR R4, R3, #-1
        HALT
BASE
        .FILL x1111
        .FILL x1234
        .FILL x8000
AFTER
        .END
