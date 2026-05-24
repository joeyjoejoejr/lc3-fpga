        .ORIG x3000

        LD R0, START_PATTERN
        STI R0, LED_PTR

        LD R1, OUTER_DELAY
OUTER   LD R2, INNER_DELAY
INNER   ADD R2, R2, #-1
        BRp INNER
        ADD R1, R1, #-1
        BRp OUTER

        LD R0, RUN_PATTERN
        STI R0, LED_PTR

DONE    BRnzp DONE

START_PATTERN
        .FILL x0001

RUN_PATTERN
        .FILL x002A

OUTER_DELAY
        .FILL #200

INNER_DELAY
        .FILL #30000

LED_PTR
        .FILL xFE10
        .END
