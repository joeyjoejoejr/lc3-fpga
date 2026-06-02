        .ORIG x3000

MAIN    LEA R0, PAL_A
        JSR DRAW_BANDS
        JSR DELAY

        LEA R0, PAL_B
        JSR DRAW_BANDS
        JSR DELAY

        BRnzp MAIN

; Draws 128x124 pixels as four 32-pixel vertical color bands.
; R0 points at four RGB555 color words.
DRAW_BANDS
        ST R7, DB_R7
        LD R1, FB_START
        LD R5, ROWS

ROW     LDR R4, R0, #0
        LD R2, BAND_WIDTH
        JSR DRAW_RUN

        LDR R4, R0, #1
        LD R2, BAND_WIDTH
        JSR DRAW_RUN

        LDR R4, R0, #2
        LD R2, BAND_WIDTH
        JSR DRAW_RUN

        LDR R4, R0, #3
        LD R2, BAND_WIDTH
        JSR DRAW_RUN

        ADD R5, R5, #-1
        BRp ROW

        LD R7, DB_R7
        RET

; Writes R2 copies of color R4 starting at framebuffer pointer R1.
; Leaves R1 pointing just after the run.
DRAW_RUN
        STR R4, R1, #0
        ADD R1, R1, #1
        ADD R2, R2, #-1
        BRp DRAW_RUN
        RET

DELAY   ST R1, DLY_R1
        ST R2, DLY_R2
        ST R7, DLY_R7

        LD R1, OUTER_DELAY
DLY_O   LD R2, INNER_DELAY
DLY_I   ADD R2, R2, #-1
        BRp DLY_I
        ADD R1, R1, #-1
        BRp DLY_O

        LD R1, DLY_R1
        LD R2, DLY_R2
        LD R7, DLY_R7
        RET

FB_START
        .FILL xC000
ROWS
        .FILL #124
BAND_WIDTH
        .FILL #32
OUTER_DELAY
        .FILL #120
INNER_DELAY
        .FILL #30000

PAL_A   .FILL x7C00
        .FILL x03E0
        .FILL x001F
        .FILL x7FED

PAL_B   .FILL x7FED
        .FILL x001F
        .FILL x03E0
        .FILL x7C00

DB_R7   .FILL x0000
DLY_R1  .FILL x0000
DLY_R2  .FILL x0000
DLY_R7  .FILL x0000

        .END
