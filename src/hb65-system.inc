.IFNDEF _INCLUDE_SYSTEM_
_INCLUDE_SYSTEM_ = 1

.INCLUDE    "hb65-registers.inc"

.GLOBAL     DECODER_INTEN_ON, DECODER_INTEN_OFF
.GLOBAL     DECODER_SYSCTX_ON, DECODER_SYSCTX_OFF
.GLOBAL     DECODER_ALTFN_ON, DECODER_ALTFN_OFF

; GLOBAL_INTERRUPT_MASK_OFF macro
; Modifies: n/a
;
; Disables the Address Decoder's global interrupt mask.
.MACRO GLOBAL_INTERRUPT_MASK_OFF
    JSR DECODER_INTEN_ON
.ENDMAC

; GLOBAL_INTERRUPT_MASK_ON macro
; Modifies: n/a
;
; Enables the Address Decoder's global interrupt mask.
.MACRO GLOBAL_INTERRUPT_MASK_ON
    JSR DECODER_INTEN_OFF
.ENDMAC

; SFMODE_SYSCTX_ON macro
; Modifies: n/a
;
; Enters System Context Mode.
.MACRO SFMODE_SYSCTX_ON
    JSR DECODER_SYSCTX_ON
.ENDMAC

; SFMODE_SYSCTX_OFF macro
; Modifies: n/a
;
; Leaves System Context Mode.
.MACRO SFMODE_SYSCTX_OFF
    JSR DECODER_SYSCTX_OFF
.ENDMAC

; SFMODE_ALTFN_ON
; Modifies: n/a
;
; Enters Alternative Function Mode.
.MACRO SFMODE_ALTFN_ON
    JSR DECODER_ALTFN_ON
.ENDMAC

; SFMODE_ALTFN_OFF macro
; Modifies: n/a
;
; Leaves Alternative Function Mode.
.MACRO SFMODE_ALTFN_OFF
    JSR DECODER_ALTFN_OFF
.ENDMAC

; SFMODE_SYSCTX_ALTFN_ON macro
; Modifies: X
;
; Enters System Context Mode and Alternative Function Mode.
.MACRO SFMODE_SYSCTX_ALTFN_ON
    JSR DECODER_SYSCTX_ON
    JSR DECODER_ALTFN_ON
.ENDMACRO

; SFMODE_RESET
; Modifies: X
;
; Returns the Address Decoder to its standard operating mode.
.MACRO SFMODE_RESET
    JSR DECODER_ALTFN_OFF
    JSR DECODER_SYSCTX_OFF
.ENDMACRO

; SFMODE_IMPLIED
; Modifies: n/a
;
; This macro does nothing. It can be used to indicate a position in source code where a change to the
; Address Decoder's operating mode is implied by another operation occurring elsewhere.
.MACRO SFMODE_IMPLIED
    ; Intentionally left blank
.ENDMACRO

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