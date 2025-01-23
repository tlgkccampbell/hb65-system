; hb65-bios-datastack.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS data stack routines"

.INCLUDE    "../hb65-system.inc"

; Data stack data
.SEGMENT "SHAREDPAGE"

; TODO: Replace this with a Scratch Register after cleaning up elsewhere
_DSTKBUF:   .RES 1
_DSTKPTR:   .RES 1
_DSTK:      .RES 30

; Data stack routines
.SEGMENT "BIOS"

; DSTK_INIT
; Modifies: n/a
;
; Initializes the shared data stack.
.PROC DSTK_INIT
    STZ _DSTKPTR
    RTS
.ENDPROC
.EXPORT DSTK_INIT

; DSTK_PUSH_A procedure
; Modifies: n/a
;
; Pushes the contents of the A register onto the shared data stack
; and increments the stack pointer.
.PROC DSTK_PUSH_A
    PHX
    LDX _DSTKPTR
    STA _DSTK, X
    INX
    STX _DSTKPTR
    PLX
    RTS
.ENDPROC
.EXPORT DSTK_PUSH_A

; DSTK_PUSH_X procedure
; Modifies: n/a
;
; Pushes the contents of the X register onto the shared data stack
; and increments the stack pointer.
.PROC DSTK_PUSH_X
    PHX
    PHA
    TXA
    LDX _DSTKPTR
    STA _DSTK, X
    INX
    STX _DSTKPTR
    PLA
    PLX
    RTS
.ENDPROC
.EXPORT DSTK_PUSH_X

; DSTK_PUSH_Y procedure
; Modifies: n/a
;
; Pushes the contents of the Y register onto the shared data stack
; and increments the stack pointer.
.PROC DSTK_PUSH_Y
    PHX
    PHA
    TYA
    LDX _DSTKPTR
    STA _DSTK, X
    INX
    STX _DSTKPTR
    PLA
    PLX
    RTS
.ENDPROC
.EXPORT DSTK_PUSH_Y

; DSTK_PUSH_AND_SET_DCR procedure
; Modifies: n/a
;
; Pushes the current value of the Decoder Control Register onto the shared
; data stack, then sets the Decoder Control Register to the value in A.
.PROC DSTK_PUSH_AND_SET_DCR
    STA _DSTKBUF
    LDA DECODER_DCR
   DPHA
    LDA _DSTKBUF
    STA DECODER_DCR
    RTS
.ENDPROC
.EXPORT DSTK_PUSH_AND_SET_DCR

; DSTK_PUSH_AND_ORA_DCR procedure
; Modifies: A
;
; Pushes the current value of the Decoder Control Register onto the shared
; data stack, then sets the Decoder Control Register to its current value
; bitwise OR'ed with the value in A.
.PROC DSTK_PUSH_AND_ORA_DCR
    STA _DSTKBUF
    LDA DECODER_DCR
   DPHA
    ORA _DSTKBUF
    STA DECODER_DCR
    RTS
.ENDPROC
.EXPORT DSTK_PUSH_AND_ORA_DCR

; DSTK_PULL_A procedure
; Modifies: A
;
; Pulls the value on top of the shared data stack into the A register
; and decrements the stack pointer.
.PROC DSTK_PULL_A
    PHX
    LDX _DSTKPTR
    DEX
    LDA _DSTK, X
    STX _DSTKPTR
    PLX
    RTS
.ENDPROC
.EXPORT DSTK_PULL_A

; DSTK_PULL_X procedure
; Modifies: X
;
; Pulls the value on top of the shared data stack into the X register
; and decrements the stack pointer.
.PROC DSTK_PULL_X
    PHA
    LDX _DSTKPTR
    DEX
    LDA _DSTK, X
    STX _DSTKPTR
    TAX
    PLA
    RTS
.ENDPROC
.EXPORT DSTK_PULL_X

; DSTK_PULL_Y procedure
; Modifies: Y
;
; Pulls the value on top of the shared data stack into the Y register
; and decrements the stack pointer.
.PROC DSTK_PULL_Y
    PHX
    LDX _DSTKPTR
    DEX
    LDY _DSTK, X
    STX _DSTKPTR
    PLX
    RTS
.ENDPROC
.EXPORT DSTK_PULL_Y

; DSTK_PULL_DCR
; Modifies: 
;
; Pulls the value off the top of the shared data stack into the Decoder
; Control Register and decrements the stack pointer.
.PROC DSTK_PULL_DCR
    PHA
   DPLA
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT DSTK_PULL_DCR