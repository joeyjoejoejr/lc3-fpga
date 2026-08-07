; PennSim privilege probe.
;
; Load this together with the course lc3os.obj, start the OS at x0200, and
; single-step around TRAP x21. Useful addresses:
;
;   x0200  OS startup
;   x021D  GETC trap handler
;   x0221  OUT trap handler
;   x0226  OUT trap RET/JMP R7 in the inspected lc3os.obj
;   x3000  user program entry after OS JMPT R7
;   x3002  instruction immediately after TRAP x21 returns
;   x3003  stable spin loop after the trap
;
; Registers to watch:
;
;   PC   proves where execution is
;   PSR  shows supervisor/user mode and NZP
;   R7   should hold x3002 while inside TRAP x21
;   R0   contains the character sent to OUT

        .ORIG x3000

USER_START
        LD   R0, CHAR_A        ; x3000
        TRAP x21               ; x3001: OUT, should enter OS/supervisor
AFTER_TRAP
        ADD  R2, R2, #1        ; x3002: first user instruction after return
SPIN
        BRnzp SPIN             ; x3003: stable post-return inspection point

CHAR_A  .FILL x0041

        .END
