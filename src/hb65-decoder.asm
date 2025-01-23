; hb65-wozmon.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Address Decoder interface subroutines"

.INCLUDE    "hb65-system.inc"

.SEGMENT "SHAREDPAGE"

DCRSTKPTR:  .RES 1
DCRSTK:     .RES 7

; TODO: Replace this
TMPSTORE    := $02FF

; Address Decoder interface subroutines
.SEGMENT "BIOS"

; DCRSTK_INIT
; Modifies: n/a
;
; Initializes the Decoder Control Register stack.
.PROC DCRSTK_INIT
    STZ DCRSTKPTR
    RTS
.ENDPROC
.EXPORT DCRSTK_INIT

; DCRSTK_SET_PUSH
; Modifies: A
;
; Pushes the value of the Decoder Control Register onto the Decoder Control
; Register Stack, then updates the Decoder Control Register by setting it to
; the value passed in the A register.
.PROC DCRSTK_SET_PUSH
    PHX
    STA TMPSTORE
    LDA DECODER_DCR
    LDX DCRSTKPTR
    STA DCRSTK, X
    INX
    STX DCRSTKPTR
    LDA TMPSTORE
    STA DECODER_DCR
    PLX
    RTS
.ENDPROC
.EXPORT DCRSTK_SET_PUSH

; DCRSTK_ORA_PUSH
; Modifies: A
;
; Pushes the value of the Decoder Control Register onto the Decoder Control
; Register Stack, then updates the Decoder Control Register by performing a
; bitwise OR with the contents of A.
.PROC DCRSTK_ORA_PUSH
    PHX
    STA TMPSTORE
    LDA DECODER_DCR
    LDX DCRSTKPTR
    STA DCRSTK, X
    INX
    STX DCRSTKPTR
    ORA TMPSTORE
    STA DECODER_DCR
    PLX
    RTS
.ENDPROC
.EXPORT DCRSTK_ORA_PUSH

; DCRSTK_POP
; Modifies: n/a
;
; Pops a value off of the Decoder Control Register Stack and writes
; it to the Decoder Control Register.
.PROC DCRSTK_POP
    PHA
    PHX
    LDX DCRSTKPTR
    DEX
    LDA DCRSTK, X
    STA DECODER_DCR
    STX DCRSTKPTR
    PLX
    PLA
    RTS
.ENDPROC