.IFNDEF _INCLUDE_SYSTEM_
_INCLUDE_SYSTEM_ = 1

.INCLUDE    "hb65-registers.inc"

.GLOBAL     DCRSTK_ORA_PUSH, DCRSTK_POP

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

; DECODER_DCR_SET_PUSH macro
; Modifies: A
;
; Pushes the value of the Decoder Control Register onto the Decoder Control
; Register Stack, then updates the Decoder Control Register by setting it to
; the value of `bits`.
.MACRO DECODER_DCR_SET_PUSH bits
    LDA #bits
    JSR DCRSTK_SET_PUSH
.ENDMAC

; DECODER_DCR_ORA_PUSH macro
; Modifies: A
;
; Pushes the value of the Decoder Control Register onto the Decoder Control
; Register Stack, then updates the Decoder Control Register by performing a
; bitwise OR with the value of `bits`.
.MACRO DECODER_DCR_ORA_PUSH bits
    LDA #bits
    JSR DCRSTK_ORA_PUSH
.ENDMAC

; DECODER_DCR_POP macro
; Modifies: n/a
;
; Pops a value off of the Decoder Control Register Stack and writes
; it to the Decoder Control Register. The popped value is returned
; in the A register.
.MACRO DECODER_DCR_POP
    JSR DCRSTK_POP
.ENDMAC

; DECODER_DCR_POP_IMPLIED macro
; Modifies: n/a
;
; This macro does nothing. It is intended to be used to indicate that the
; Decoder Control Register Stack will be popped by code in another branch.
.MACRO DECODER_DCR_POP_IMPLIED
    ; Intentionally left blank
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