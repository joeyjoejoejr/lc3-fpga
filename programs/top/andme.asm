;;;;;;;;;;
; Joe Jackson
; Submission Date: 10-27-2023
; andme.asm
; AndMe takes two 4 digit binary numbers as input entered sequentially. It then
; performs the AND operation on them and prints the results. The letter 'q'
; prints a message and halts the program, any other input other than '0' or '1'
; is ignored
;;;;;;;;;;

         .ORIG x3000
START    AND R6, R6, 0      ; Input counter
         ADD R6, R6, 2      ; Initialize input counter to 2

         LEA R5, INPUTS     ; Load R5 with the pointer to the inputs

         LEA R3, PRPTR      ; Load pointers to the strings into PRPTR
         LEA R1, PROMPT1
         STR R1, R3, 0
         LEA R1, PROMPT2
         STR R1, R3, 1

GETINPUT AND R4, R4, 0      ; Clear the digit counter
         ADD R4, R4, 4      ; Set the digit counter to 4
         LDR R0, R3, 0      ; Move the string pointer to R0 for printing
         PUTS               ; Print the first prompt to the screen

GETDIGIT GETC               ; Get a character from the keyboard
         OUT                ; Echo it

         LD R1, NEGq        ; Check if the value is 'q'
         ADD R1, R1, R0     ; Use R1 as destination so we can keep using R0
         BRz QUIT           ; if so, quit the program

         LD R1, NEG0        ; Adjust to digit offset
         ADD R0, R0, R1     ; Use R0 as actual number

         BRz ISBINARY       ; If zero, no more check needed
         ADD R1, R0, -1     ; Check if value is 1
         BRz ISBINARY       ; If zero, no more check needed
         BRnzp GETDIGIT     ; Otherwise ignore

ISBINARY STR R0, R5, 0      ; Store my number in input
         ADD R5, R5, 1      ; Increment my pointer
         ADD R4, R4, -1     ; Decrement the digit counter

         BRp GETDIGIT       ; get more input if not zero

         LD R0, NEWLINE     ; Print a newline
         OUT

         ADD R3, R3, 1      ; set the next prompt

         ADD R6, R6, -1     ; decrement inputs counter
         BRp GETINPUT       ; If we still need input jump to GETINPUT

         ; Output
         LEA R0, ANSWER     ; Print the answer prompt
         PUTS

         LEA R5, INPUTS    ; Load input 1 in R5
         ADD R6, R6, 4     ; Setup R6 as counter
PDIGIT   LDR R2, R5, 0     ; Load digit n of input 1 into R2
         LDR R3, R5, 4     ; Load digit n of input 2 into R3 -- Offset of 4

         ADD R4, R2, R3    ; Add the number
         AND R4, R4, 1     ; the lsb will be xor
         LD R2, ZERO       ; Load the ascii digit offset
         ADD R0, R4, R2    ; Load the ascii value into R0
         OUT

         ADD R5, R5, 1     ; Increment pointer
         ADD R6, R6, -1     ; Decrement counter
         BRp PDIGIT

         LD R0, NEWLINE     ; Print a newline
         OUT
         BRnzp START        ; If there is more to print, do so

QUIT     LEA R0, EXITMSG    ; Load the address of the exit message to R0
         PUTS 
         HALT

NEGq     .FILL -113
NEG0     .FILL -48
ZERO     .FILL x30
NEWLINE  .FILL xA
INPUTS   .BLKW 8
PRPTR    .BLKW 2            ; reserve two locations for string pointer array
PROMPT1  .STRINGZ "\nEnter First Binary Number: "
PROMPT2  .STRINGZ "Enter Second Binary Number: "
EXITMSG  .STRINGZ "\nThank you for playing!"
ANSWER   .STRINGZ "The XOR function of the two numbers is: "

.END
