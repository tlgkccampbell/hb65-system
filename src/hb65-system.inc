.IFNDEF _INCLUDE_SYSTEM_
_INCLUDE_SYSTEM_ = 1

.INCLUDE    "hb65-registers.inc"

.GLOBAL     DSTK_PUSH_A, DSTK_PUSH_X, DSTK_PUSH_Y, DSTK_PUSH_AND_SET_DCR, DSTK_PUSH_AND_ORA_DCR, DSTK_PULL_A, DSTK_PULL_X, DSTK_PULL_Y, DSTK_PULL_DCR

; GLOBAL_INTERRUPT_MASK_OFF macro
; Modifies: n/a
;
; Disables the Address Decoder's global interrupt mask.
.MACRO GLOBAL_INTERRUPT_MASK_OFF
    INC DECODER_ICR
.ENDMAC

; GLOBAL_INTERRUPT_MASK_ON macro
; Modifies: n/a
;
; Enables the Address Decoder's global interrupt mask.
.MACRO GLOBAL_INTERRUPT_MASK_ON
    DEC DECODER_ICR
.ENDMAC

; GLOBAL_INTERRUPT_MASK_IMPLIED macro
; Modifies: n/a
;
; This macro does nothing. It is intended to be used to indicate that the
; global interrupt mask will be disabled by code in another branch.
.MACRO GLOBAL_INTERRUPT_MASK_IMPLIED
    ; Intentionally left blank
.ENDMAC

; SFMODE_PUSH_AND_SET macro
; Modifies: A
;
; Pushes the current value of the Decoder Control Register onto the shared
; data stack, then sets the Decoder Control Register to the value specified by `bits`.
.MACRO SFMODE_PUSH_AND_SET bits
    PHA
    LDA #bits & ((1 << DECODER_DCR_BIT::ALTFN) | (1 << DECODER_DCR_BIT::SYSCTX))
    JSR DSTK_PUSH_AND_SET_DCR
    PLA
.ENDMAC

; SFMODE_PUSH_AND_ORA macro
; Modifies: A
;
; Pushes the current value of the Decoder Control Register onto the shared
; data stack, then sets the Decoder Control Register to its current value
; bitwise OR'ed with the value specified by `bits`.
.MACRO SFMODE_PUSH_AND_ORA bits
    PHA
    LDA #bits & ((1 << DECODER_DCR_BIT::ALTFN) | (1 << DECODER_DCR_BIT::SYSCTX))
    JSR DSTK_PUSH_AND_ORA_DCR
    PLA
.ENDMAC

; SFMODE_POP macro
; Modifies: n/a
;
; Pulls the value off the top of the shared data stack into the Decoder
; Control Register and decrements the stack pointer.
.MACRO SFMODE_POP
    JSR DSTK_PULL_DCR
.ENDMAC

; SFMODE_POP_IMPLIED macro
; Modifies: n/a
;
; This macro does nothing. It is intended to be used to indicate that the
; SFMODE_POP macro will be called in another branch.
.MACRO SFMODE_POP_IMPLIED
    ; Intentionally left blank
.ENDMAC

; DPHA macro
; Modifies: n/a
;
; Pushes the contents of the A register onto the shared data stack
; and increments the stack pointer.
.MACRO DPHA
    JSR DSTK_PUSH_A
.ENDMAC

; DPHX macro
; Modifies: n/a
;
; Pushes the contents of the X register onto the shared data stack
; and increments the stack pointer.
.MACRO DPHX
    JSR DSTK_PUSH_X
.ENDMAC

; DPHY macro
; Modifies: n/a
;
; Pushes the contents of the Y register onto the shared data stack
; and increments the stack pointer.
.MACRO DPHY
    JSR DSTK_PUSH_Y
.ENDMAC

; DPLA macro
; Modifies: A
;
; Pulls the value on top of the shared data stack into the A register
; and decrements the stack pointer.
.MACRO DPLA
    JSR DSTK_PULL_A
.ENDMAC

; DPLX macro
; Modifies: X
;
; Pulls the value on top of the shared data stack into the X register
; and decrements the stack pointer.
.MACRO DPLX
    JSR DSTK_PULL_X
.ENDMAC

; DPLY macro
; Modifies: Y
;
; Pulls the value on top of the shared data stack into the Y register
; and decrements the stack pointer.
.MACRO DPLY
    JSR DSTK_PULL_Y
.ENDMAC

; STADDR macro
; Modifies: A
;
; Loads the specified address `addr` into the A register and then
; transfers it to the memory location `dest`.
.MACRO STADDR addr, dest
    LDA #<addr
    STA dest
    LDA #>addr
    STA dest+1
.ENDMAC

.ENDIF