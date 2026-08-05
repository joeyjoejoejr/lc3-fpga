;;;;;;;;;;
; Joe Jackson
; Submission Date: 11-27-2023
; invaders.asm
; The invaders program is a game where the player controls a ship at the bottom
; of the screen and shoots lasers at aliens at the top of the screen. The player
; can move left and right and change the color of the ship. The aliens are
; colored red if they have been hit and blue if they have not. The player wins
; if all the aliens are hit.
;
; Movement/player controls
; -----------------
; a - move left
; d - move right
; space - shoot laser
;
; Color controls
; --------------
; r - turn player red
; g - turn player green
; b - turn player blue
; y - turn player yellow
; w - turn player white
;
; Other controls
; --------------
; q - quit
;;;;;;;;;;

                .ORIG x3000
;Initialize
START           AND R0, R0, 0         ; Initialization: Clear R0-R7
                AND R1, R1, 0
                AND R2, R2, 0
                AND R3, R3, 0
                AND R4, R4, 0
                AND R5, R5, 0
                AND R6, R6, 0
                AND R7, R7, 0

                LD R0, TICK_INTERVAL  ; Setup timer to roughly 1/30th of a second
                STI R0, TIRptr

                JSR CLEAR_SCREEN
                JSR DRAW_ALIENS
                JSR DRAW_PLAYER

MAIN_LOOP       LDI R0, TSRptr
                BRzp MAIN_LOOP

                LDI R0, KBSRptr
                BRzp SKIP_KBD

                LDI R0, KBDRptr       ; Load the pressed key
                ADD R1, R0, #0        ; Move R0 to R1 for later use

; Movement
                LD R2, NEG_a          ; Handle a
                ADD R2, R2, R1
                BRnp SKIP_a

                JSR MOVE_PLAYER_L

SKIP_a          LD R2, NEG_d          ; Handle d
                ADD R2, R2, R1
                BRnp SKIP_d

                JSR MOVE_PLAYER_R

SKIP_d          LD R2, NEG_r      ; Handle r
                ADD R2, R2, R1
                BRnp SKIP_r

                AND R0, R0, #0
                ADD R0, R0, #0    ; Color 1 is red
                ST R0, PLAYER_COLOR
                JSR DRAW_PLAYER

SKIP_r          LD R2, NEG_g      ; Handle g
                ADD R2, R2, R1
                BRnp SKIP_g

                AND R0, R0, #0
                ADD R0, R0, #1    ; Color 2 is green
                ST R0, PLAYER_COLOR
                JSR DRAW_PLAYER

SKIP_g          LD R2, NEG_b      ; Handle b
                ADD R2, R2, R1
                BRnp SKIP_b

                AND R0, R0, #0
                ADD R0, R0, #2    ; Color 3 is blue
                ST R0, PLAYER_COLOR
                JSR DRAW_PLAYER

SKIP_b          LD R2, NEG_y      ; Handle y
                ADD R2, R2, R1
                BRnp SKIP_y

                AND R0, R0, #0
                ADD R0, R0, #3    ; Color 4 is yellow
                ST R0, PLAYER_COLOR
                JSR DRAW_PLAYER

SKIP_y          LD R2, NEG_w     ; Handle w
                ADD R2, R2, R1
                BRnp SKIP_w

                AND R0, R0, #0
                ADD R0, R0, #4    ; Color 5 is white
                ST R0, PLAYER_COLOR
                JSR DRAW_PLAYER

SKIP_w          LD R2, NEG_sp         ; Handle space
                ADD R2, R2, R1
                BRnp SKIP_sp

                LD R0, PLAYER_POS
                LD R1, PLAYER_WIDTH
                JSR LAUNCH_LASER

SKIP_sp         LD R2, NEG_q          ; Handle q
                ADD R2, R2, R1
                BRnp SKIP_KBD

                BRnzp QUIT

SKIP_KBD        JSR MOVE_LASER
                JSR CHECK_GAME_OVER
                BRnzp MAIN_LOOP

QUIT            HALT

KBSRptr         .FILL xFE00
KBDRptr         .FILL xFE02
TSRptr          .FILL xFE08
TIRptr          .FILL xFE0A
TICK_INTERVAL   .FILL #33

NEG_a           .FILL #-97
NEG_d           .FILL #-100
NEG_q           .FILL #-113

NEG_r           .FILL #-114
NEG_g           .FILL #-103
NEG_b           .FILL #-98
NEG_y           .FILL #-121
NEG_w           .FILL #-119

NEG_sp          .FILL #-32

; DRAW_PLAYER Subroutine
; Draw the player box. This routine takes no input and returns nothing
DRAW_PLAYER     ST R0, DP_R0
                ST R1, DP_R1
                ST R2, DP_R2
                ST R3, DP_R3
                ST R4, DP_R4
                ST R7, DP_R7

                LD R1, PLAYER_POS
                LD R2, PLAYER_WIDTH
                AND R3, R3, #0        ; Setup height
                ADD R3, R3, #12
                LD R4, PLAYER_COLOR   ; Setup color
                JSR DRAW_BOX

                LD R0, DP_R0
                LD R1, DP_R1
                LD R2, DP_R2
                LD R3, DP_R3
                LD R4, DP_R4
                LD R7, DP_R7
                RET

DP_R0           .FILL x0
DP_R1           .FILL x0
DP_R2           .FILL x0
DP_R3           .FILL x0
DP_R4           .FILL x0
DP_R7           .FILL x0

PLAYER_POS      .FILL xF3B3
PLAYER_COLOR    .FILL #0
PLAYER_WIDTH    .FILL #24

; MOVE_PLAYER_L Subroutine
; Moves the player left
; Arguments: None
; Returns: Nothing
MOVE_PLAYER_L   ST R0, MPL_R0
                ST R1, MPL_R1
                ST R2, MPL_R2
                ST R3, MPL_R3
                ST R4, MPL_R4
                ST R5, MPL_R5
                ST R7, MPL_R7

                AND R4, R4, #0
                ADD R4, R4, #-4        ; Setup up movement of -4

                LD R1, PLAYER_POS     ; Add the offset to the player position
                ADD R5, R4, R1

                ADD R0, R5, #0        ; Setup bounds check
                LD R2, PLAYER_WIDTH
                JSR IS_ON_SCREEN_X    ; Check Bounds
                ADD R0, R0, #0
                BRn END_MPL

                ADD R1, R5, #0        ; Set up draw box for the new portion on
                AND R2, R2, #0        ; the left
                ADD R2, R2, #4
                AND R3, R3, #0
                ADD R3, R3, #12
                LD R4, PLAYER_COLOR
                JSR DRAW_BOX

                ADD R1, R5, #0        ; Set up draw box for the old portion on
                LD R0, PLAYER_WIDTH   ; the right -- clearing
                ADD R1, R1, R0
                AND R2, R2, #0
                ADD R2, R2, #4
                AND R3, R3, #0
                ADD R3, R3, #12
                AND R4, R4, #0
                ADD R4, R4, #5        ; Color is black
                JSR DRAW_BOX

                ST R5, PLAYER_POS     ; Update the player position

END_MPL         LD R0, MPL_R0
                LD R1, MPL_R1
                LD R2, MPL_R2
                LD R3, MPL_R3
                LD R4, MPL_R4
                LD R5, MPL_R5
                LD R7, MPL_R7
                RET

MPL_R0          .FILL x0
MPL_R1          .FILL x0
MPL_R2          .FILL x0
MPL_R3          .FILL x0
MPL_R4          .FILL x0
MPL_R5          .FILL x0
MPL_R7          .FILL x0

; MOVE_PLAYER_R Subroutine
; Moves the player left
; Arguments: None
; Returns: Nothing
MOVE_PLAYER_R   ST R0, MPR_R0
                ST R1, MPR_R1
                ST R2, MPR_R2
                ST R3, MPR_R3
                ST R4, MPR_R4
                ST R5, MPR_R5
                ST R7, MPR_R7

                AND R4, R4, #0
                ADD R4, R4, #4        ; Setup up movement of -4

                LD R1, PLAYER_POS     ; Add the offset to the player position
                ADD R5, R4, R1

                ADD R0, R5, #0        ; Setup bounds check
                LD R2, PLAYER_WIDTH
                JSR IS_ON_SCREEN_X    ; Check Bounds
                ADD R0, R0, #0
                BRn END_MPR

                ADD R1, R5, #0        ; Set up draw box for the new portion on
                ADD R1, R1, #-4
                LD R0, PLAYER_WIDTH   ; the right
                ADD R1, R1, R0
                AND R2, R2, #0
                ADD R2, R2, #4
                AND R3, R3, #0
                ADD R3, R3, #12
                LD R4, PLAYER_COLOR
                JSR DRAW_BOX

                ADD R1, R5, #0        ; Setup up draw box for clearing old
                ADD R1, R1, #-4       ;portion
                AND R2, R2, #0
                ADD R2, R2, #4
                AND R3, R3, #0
                ADD R3, R3, #12
                AND R4, R4, #0        ; Black
                ADD R4, R4, #5        ; Black
                JSR DRAW_BOX

                ST R5, PLAYER_POS     ; Update the player position

END_MPR         LD R0, MPR_R0
                LD R1, MPR_R1
                LD R2, MPR_R2
                LD R3, MPR_R3
                LD R4, MPR_R4
                LD R5, MPR_R5
                LD R7, MPR_R7
                RET

MPR_R0          .FILL x0
MPR_R1          .FILL x0
MPR_R2          .FILL x0
MPR_R3          .FILL x0
MPR_R4          .FILL x0
MPR_R5          .FILL x0
MPR_R7          .FILL x0

; DRAW_ALIENS Subroutine
; Draws all 4 aliens based on their location and hit status. Takes no arguments
; and returns nothing
DRAW_ALIENS     ST R0, DA_R0
                ST R1, DA_R1
                ST R2, DA_R2
                ST R3, DA_R3
                ST R4, DA_R4
                ST R5, DA_R5
                ST R6, DA_R6
                ST R7, DA_R7
                AND R5, R5, #0
                ADD R5, R5, #4
                LEA R6, ALIEN1_POS


DA_LOOP         LDR R1, R6, #0        ; Load position
                AND R2, R2, #0        ; Setup width
                ADD R2, R2, #14
                AND R3, R3, #0        ; Setup height
                ADD R3, R3, #14
                LDR R4, R6, #1        ; Load the hit field
                BRnz DA_SKIP_RED

                AND R4, R4, #0
                ADD R4, R4, #0       ; Color is red if hit
                BRnzp DA_SKIP
DA_SKIP_RED     AND R4, R4, #0
                ADD R4, R4, #2       ; Color is blue if not hit

DA_SKIP         JSR DRAW_BOX

                ADD R6, R6, #2
                ADD R5, R5, #-1
                BRp DA_LOOP

                LD R0, DA_R0
                LD R1, DA_R1
                LD R2, DA_R2
                LD R3, DA_R3
                LD R4, DA_R4
                LD R5, DA_R5
                LD R6, DA_R6
                LD R7, DA_R7
                RET

DA_R0           .FILL x0
DA_R1           .FILL x0
DA_R2           .FILL x0
DA_R3           .FILL x0
DA_R4           .FILL x0
DA_R5           .FILL x0
DA_R6           .FILL x0
DA_R7           .FILL x0

; WILL_HIT_ALIEN subroutine
; checks if the laser will hit an alien
; Arguments:
; R0 Position of the laser
; R1 Width of laser
; Returns:
; R0 The address of the alien that this laser will hit
WILL_HIT_ALIEN  ST R1, WHA_R1
                ST R2, WHA_R2
                ST R3, WHA_R3
                ST R4, WHA_R4
                ST R5, WHA_R5
                ST R6, WHA_R6
                ST R7, WHA_R7

                ADD R2, R0, #0        ; Store pos
                LEA R3, ALIEN1_POS
                AND R4, R4, #0
                ADD R4, R4, #4        ; Alien count

WHA_LOOP        LDR R5, R3, #0         ; Check the left
                LD R0, X_MASK         ; just check the x
                AND R5, R5, R0

                ADD R6, R2, R1        ; Get the right side of the laser to
                ADD R6, R6, #-1       ; compare against the left side alien
                AND R6, R6, R0        ; just check the x

                NOT R5, R5            ; If it's negative, can't be a hit
                ADD R5, R5, #1
                ADD R6, R6, R5
                BRn WHA_ZERO

                LDR R5, R3, #0         ; Check the right
                ADD R5, R5, #14
                AND R5, R5, R0        ; just check the x

                ADD R6, R2, #0        ; Get the left side of the laser
                AND R6, R6, R0        ; just check the x

                NOT R6, R6            ; If it's negative it can't be a hit
                ADD R6, R6, #1
                ADD R6, R6, R5
                BRn SKIP_WHA

                ADD R0, R3, #0        ; Return the alien address
                BRnzp WHA_END

SKIP_WHA        ADD R3, R3, #2        ; check next alien
                ADD R4, R4, #-1
                BRp WHA_LOOP

WHA_ZERO        AND R0, R0, #0
WHA_END         LD R1, WHA_R1
                LD R2, WHA_R2
                LD R3, WHA_R3
                LD R4, WHA_R4
                LD R5, WHA_R5
                LD R6, WHA_R6
                LD R7, WHA_R7
                RET

WHA_R1          .FILL x0
WHA_R2          .FILL x0
WHA_R3          .FILL x0
WHA_R4          .FILL x0
WHA_R5          .FILL x0
WHA_R6          .FILL x0
WHA_R7          .FILL x0

; CHECK_GAME_OVER subroutine
; Checks if all aliens hit. Quits game if so
CHECK_GAME_OVER ST R0, CGO_R0
                ST R1, CGO_R1
                ST R2, CGO_R1
                ST R7, CGO_R7

                LEA R0, ALIEN1_POS
                AND R1, R1, #0
                ADD R1, R1, #4        ; Load aliens for loop

CGO_LOOP        LDR R2, R0, #1        ; Is it hit?
                BRnz CGO_END          ; If one is not hit, game is over
                ADD R0, R0, #2        ; Next alien
                ADD R1, R1, #-1
                BRp CGO_LOOP

                LEA R0, GOODBYE
                PUTS
                BRnzp QUIT              ; If we make it through the loop quit

CGO_END         LD R0, CGO_R0
                LD R1, CGO_R1
                LD R2, CGO_R1
                LD R7, CGO_R7
                RET

CGO_R0          .FILL x0
CGO_R1          .FILL x0
CGO_R2          .FILL x0
CGO_R7          .FILL x0

GOODBYE         .STRINGZ "\nGAME OVER!\n"

; IS_COLLISION subroutine
; Checks if there is a collision with one of the aliens
; Arguments:
; Position to check R0 (assuming top of box moving up)
; Address of alien R1
; Returns:
; 1 on R0 if collision
; 0 on R0 if not collision
IS_COLLISION    ST R1, IC_R1
                ST R2, IC_R2
                ST R3, IC_R3
                ST R4, IC_R4
                ST R5, IC_R5
                ST R6, IC_R6
                ST R7, IC_R7

                LDR R2, R1, #0         ; Load the position
                LD R3, ALIEN_ROWS
                ADD R2, R2, R3        ; Set to the bottom row
                NOT R2, R2
                ADD R2, R2, #1        ; Negate
                ADD R2, R2, R0        ; Check if it's high enough to collide
                BRp SKIP_IC

                AND R0, R0, #0        ; It's a hit set R0 to 1
                ADD R0, R0, #1
                STR R0, R1, #1        ; Set the alien to hit
                BRnzp END_IC          ; Return early with the hit

SKIP_IC         AND R0, R0, #0
END_IC          LD R1, IC_R1
                LD R2, IC_R2
                LD R3, IC_R3
                LD R4, IC_R4
                LD R5, IC_R5
                LD R6, IC_R6
                LD R7, IC_R7
                RET

IC_R1           .FILL x0
IC_R2           .FILL x0
IC_R3           .FILL x0
IC_R4           .FILL x0
IC_R5           .FILL x0
IC_R6           .FILL x0
IC_R7           .FILL x0
ALIEN_ROWS      .FILL #1792
X_MASK          .FILL x007F

ALIEN1_POS      .FILL xC18A
ALIEN1_HIT      .FILL x0
ALIEN2_POS      .FILL xC1A8
ALIEN2_HIT      .FILL x0
ALIEN3_POS      .FILL xC1C6
ALIEN3_HIT      .FILL x0
ALIEN4_POS      .FILL xC1E4
ALIEN4_HIT      .FILL x0

; DRAW_BOX Subroutine
; Draw a box at the origin with width, height and color (0-5)
; Arguments:
; ORIGIN R1
; WIDTH R2
; HEIGHT R3
; COLOR R4
; Returns: Nothing

DRAW_BOX        ST R0, DB_R0
                ST R1, DB_R1
                ST R3, DB_R3
                ST R4, DB_R4
                ST R5, DB_R5
                ST R7, DB_R7

                LEA R5, RED
                ADD R5, R5, R4      ; Load the color at offset in R4
                LDR R4, R5, #0

                ADD R5, R2, #0      ; Load the width in R5 as a reusable counter

DRAW_LOOP       LD R0, MIN_SCREEN   ; Check bounds for drawing
                NOT R0, R0
                ADD R0, R0, #1
                ADD R0, R0, R1
                BRn SKIP_DRAW

                LD R0, MAX_SCREEN   ; Check bounds for drawing
                NOT R0, R0
                ADD R0, R0, #1
                ADD R0, R0, R1
                BRp SKIP_DRAW

                STR R4, R1, #0
SKIP_DRAW       ADD R1, R1, #1      ; next column
                ADD R5, R5, #-1     ; Decrement column counter
                BRp DRAW_LOOP

                LD R5, ROW_SIZE
                ADD R1, R1, R5
                NOT R5, R2          ; Set back to the beginning of column
                ADD R5, R5, #1
                ADD R1, R1, R5

                ADD R5, R2, #0      ; Reset column counter for next row
                ADD R3, R3, #-1     ; Decrement row counter
                BRp DRAW_LOOP

                LD R0, DB_R0
                LD R1, DB_R1
                LD R3, DB_R3
                LD R4, DB_R4
                LD R5, DB_R5
                LD R7, DB_R7
                RET

DB_R0           .FILL x0
DB_R1           .FILL x0
DB_R3           .FILL x0
DB_R4           .FILL x0
DB_R5           .FILL x0
DB_R7           .FILL x0

ROW_SIZE        .FILL #128
MIN_SCREEN      .FILL xC000
MAX_SCREEN      .FILL xFDFF

RED             .FILL x7C00       ; Color 0
GREEN           .FILL x03E0
BLUE            .FILL x001F
YELLOW          .FILL x7FED
WHITE           .FILL x7FFF
BLACK           .FILL x0000       ; Color 5


; IS_ON_SCREEN_X
; Takes the new position on R0
; Takes the former position on R1
; Takes the box width on R2
; Returns a negative value in R0 if out of bounds
IS_ON_SCREEN_X  ST R1, IOS_R1
                ST R2, IOS_R2
                ST R3, IOS_R3
                ST R4, IOS_R4
                ST R7, IOS_R7

                ADD R3, R0, #0        ; Mv R0 to R3

                LD R4, ROW_MASK
                AND R0, R1, R4        ; Apply the mask to the current pos
                NOT R0, R0
                ADD R0, R0, #1        ; Negate R0

                AND R4, R3, R4        ; Apply mask to new pos

                ADD R0, R0, R4        ; Compare them
                BRz SKIP_RIGHT_OOB

                AND R0, R0, #0        ; Set R0 negative
                ADD R0, R0, #-1
                BRnzp END_IOS_X

SKIP_RIGHT_OOB  ADD R3, R3, R2        ; Check the right side of the box
                LD R0, ROW_MASK
                AND R0, R3, R0        ; Apply the mask
                NOT R0, R0
                ADD R0, R0, #1        ; Negate R0

                ADD R0, R0, R4        ; Compare them
                BRz END_IOS_X

                AND R0, R0, #0        ; Set R0 negative
                ADD R0, R0, #-1

END_IOS_X       LD R1, IOS_R1
                LD R2, IOS_R2
                LD R3, IOS_R3
                LD R4, IOS_R4
                LD R7, IOS_R7
                RET

IOS_R1          .FILL x0
IOS_R2          .FILL x0
IOS_R3          .FILL x0
IOS_R4          .FILL x0
IOS_R7          .FILL x0
ROW_MASK        .FILL xFF80

; LAUNCH_LASER subroutine
; launces a laser from the player's current position
; Arguments:
; R0 player pos
; R1 player_width
; Returns Nothing
LAUNCH_LASER  ST R1, LL_R1
              ST R2, LL_R2
              ST R3, LL_R3
              ST R7, LL_R7

              ADD R3, R0, #0          ; Store the position
              LD R2, LASER_ON
              BRzp END_LL             ; Only launch the laser if off

              AND R2, R2, #0          ; set the laser on
              ST R2, LASER_ON

              ADD R0, R1, #0          ; Divide width by 2
              JSR DIV_2
              ADD R0, R0, #-1         ; Offset by laser width
              ADD R0, R0, R3
              ST R0, LASER_POS

              AND R1, R1, #0
              ADD R1, R1, #3
              JSR WILL_HIT_ALIEN      ; Check if this shot will hit an alien
              ADD R0, R0, #0
              ST R0, ALIEN_TO_HIT

END_LL        LD R1, LL_R1
              LD R2, LL_R2
              LD R3, LL_R3
              LD R7, LL_R7
              RET

LL_R1         .FILL x0
LL_R2         .FILL x0
LL_R3         .FILL x0
LL_R7         .FILL x0

LASER_ON      .FILL x8000             ; Negative if off
LASER_POS     .FILL x0
ALIEN_TO_HIT  .FILL x0                ; Address of alien we will hit

; MOVE_LASER subroutine
; Moves the laser up
; No arguments or return value
MOVE_LASER    ST R1, ML_R1
              ST R2, ML_R2
              ST R3, ML_R3
              ST R4, ML_R3
              ST R7, ML_R7

              LD R1, LASER_ON
              BRn END_ML

              LD R1, LASER_POS
              LD R2, NEG_rows
              ADD R1, R1, R2
              ST R1, LASER_POS

              AND R2, R2, #0          ; Setup top box
              ADD R2, R2, #3
              AND R3, R3, #0
              ADD R3, R3, #2
              AND R4, R4, #0
              ADD R4, R4, #1
              JSR DRAW_BOX

              LD R2, LASER_ROWS
              ADD R1, R1, R2

              LD R2, ROW_MASK
              AND R2, R2, R1
              LD R3, START_ERASING
              NOT R3, R3
              ADD R3, R3, #1
              ADD R2, R2, R3
              BRzp END_ML

              AND R2, R2, #0          ; Setup bottom box
              ADD R2, R2, #3
              AND R3, R3, #0
              ADD R3, R3, #2
              AND R4, R4, #0
              ADD R4, R4, #5          ; Set to black
              JSR DRAW_BOX

              LD R2, ROW_MASK         ; Check if top of screen
              AND R2, R2, R1
              LD R3, MIN_SCREEN
              NOT R3, R3
              ADD R3, R3, #1
              ADD R2, R2, R3
              BRn SKIP_ML


              LD R0, LASER_POS        ; Check if collision
              LD R1, ALIEN_TO_HIT
              BRnz END_ML
              JSR IS_COLLISION
              ADD R0, R0, #0
              BRnz END_ML

              LD R1, LASER_POS        ; Load the position
              AND R2, R2, #0          ; Setup clear box
              ST R2, ALIEN_TO_HIT     ; Clear the alien
              ADD R2, R2, #3
              AND R3, R3, #0
              ADD R3, R3, #14
              AND R4, R4, #0
              ADD R4, R4, #5          ; Set to black
              JSR DRAW_BOX
              JSR DRAW_ALIENS         ; Draw the aliens to update color

SKIP_ML       AND R2, R2, #0
              ADD R2, R2, #-1
              ST R2, LASER_ON         ; Set the laser off

END_ML        LD R1, ML_R1
              LD R2, ML_R2
              ST R3, ML_R3
              ST R4, ML_R4
              LD R7, ML_R7
              RET

ML_R1         .FILL x0
ML_R2         .FILL x0
ML_R3         .FILL x0
ML_R4         .FILL x0
ML_R7         .FILL x0

NEG_rows      .FILL #-256
ROWS_2        .FILL #256
LASER_ROWS    .FILL #1536             ; 12 Rows
START_ERASING .FILL xF380

; DIV_2 subroutine
; Divides the number passed in by 2
; Arguments:
; R0 the number to divide by
; Returns:
; R0 the result
DIV_2         ST R1, D2_R1
              ST R7, D2_R7

              AND R1, R1, #0

D2_LOOP       ADD R1, R1, #1          ; Increment the counter
              ADD R0, R0, #-2         ; Subtract 2
              BRzp D2_LOOP

              ADD R0, R1, #-1         ; Add one back

              LD R1, D2_R1
              LD R7, D2_R7
              RET

D2_R1         .FILL x0
D2_R7         .FILL x0

; CLEAR_SCREEN Subroutine
; Clears the screen to black
CLEAR_SCREEN    ST R1, CS_R1
                ST R2, CS_R2
                ST R3, CS_R3
                ST R7, CS_R7

                LD R1, SCREEN_START
                LD R2, SCREEN_SIZE
                LD R3, BLACK

CLEAR           STR R3, R1, #0        ; draw black to current pixel
                ADD R1, R1, #1
                ADD R2, R2, #-1
                BRp CLEAR

                LD R1, CS_R1
                LD R2, CS_R2
                LD R3, CS_R3
                LD R7, CS_R7
                RET

CS_R1           .FILL x0
CS_R2           .FILL x0
CS_R3           .FILL x0
CS_R7           .FILL x0
SCREEN_START    .FILL xC000
SCREEN_SIZE     .FILL 15872
                .END
