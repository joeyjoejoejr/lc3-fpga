        .ORIG x3000
        ADD R1, R1, #1
        TRAP x40
        ADD R2, R2, #2
DONE
        BRnzp DONE
HANDLER
        ADD R3, R3, #3
        RET
        .END
