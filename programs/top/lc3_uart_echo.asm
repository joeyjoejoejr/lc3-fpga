; Echo characters from KBDR to the UART-backed console.
;
; The program polls KBSR/KBDR directly. Output uses TRAP x21 so the low-memory
; trap vector has to point at the small OUT routine below.

        .ORIG x0021
        .FILL OUT

        .ORIG x3000
POLL    LDI R0, KBSR_PTR
        BRzp POLL
        LDI R0, KBDR_PTR
        TRAP x21
        BRnzp POLL

KBSR_PTR .FILL xFE00
KBDR_PTR .FILL xFE02

        .ORIG x3100
OUT     ST R1, SAVE_R1
WAIT    LDI R1, DSR_PTR
        BRzp WAIT
        STI R0, DDR_PTR
        LD R1, SAVE_R1
        RET

SAVE_R1 .FILL x0000
DSR_PTR .FILL xFE04
DDR_PTR .FILL xFE06
        .END
