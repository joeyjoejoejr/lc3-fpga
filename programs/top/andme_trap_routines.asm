; Minimal LC-3 trap support for programs/top/andme.asm.
;
; This is intentionally smaller than the course OS because the FPGA core does
; not currently implement privilege, interrupts, RTI, or JMPT. It provides the
; traps AndMe uses: GETC, OUT, PUTS, and HALT.

        .ORIG x3100
T_GETC ST R1, SAVE_R1
GETC_W LDI R1, KBSR_PTR
       BRzp GETC_W
       LDI R0, KBDR_PTR
       LD R1, SAVE_R1
       RET

T_OUT  ST R1, SAVE_R1
OUT_W  LDI R1, DSR_PTR
       BRzp OUT_W
       STI R0, DDR_PTR
       LD R1, SAVE_R1
       RET

T_PUTS ST R0, SAVE_R0
       ST R1, SAVE_R1
       ST R7, SAVE_R7
       ADD R1, R0, #0
PUTS_L LDR R0, R1, #0
       BRz PUTS_D
       OUT
       ADD R1, R1, #1
       BRnzp PUTS_L
PUTS_D LD R0, SAVE_R0
       LD R1, SAVE_R1
       LD R7, SAVE_R7
       RET

BAD_TRAP
T_HALT AND R0, R0, #0
       STI R0, MCR_PTR
HALT_L BRnzp HALT_L

SAVE_R0 .FILL x0000
SAVE_R1 .FILL x0000
SAVE_R7 .FILL x0000
KBSR_PTR .FILL xFE00
KBDR_PTR .FILL xFE02
DSR_PTR  .FILL xFE04
DDR_PTR  .FILL xFE06
MCR_PTR  .FILL xFFFE
        .END
