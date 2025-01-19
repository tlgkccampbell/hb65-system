.IFNDEF _INCLUDE_SYSTEM_
_INCLUDE_SYSTEM_ = 1

.INCLUDE    "hb65-registers.inc"

; SFMODE_SYSCTX_ON macro
; Modifies: A
;
; Enters System Context Mode.
.MACRO SFMODE_SYSCTX_ON
    LDA #(~(1 << DECODER_SFR_BIT::SFWM0) & $F0) | (1 << DECODER_SFR_BIT::SYSCTX)
    STA DECODER_SFR
.ENDMAC

; SFMODE_SYSCTX_OFF macro
; Modifies: A
;
; Leaves System Context Mode.
.MACRO SFMODE_SYSCTX_OFF
    LDA #(~(1 << DECODER_SFR_BIT::SFWM0) & $F0)
    STA DECODER_SFR
.ENDMAC

; SFMODE_ALTFN_ON
; Modifies: A
;
; Enters Alternative Function Mode.
.MACRO SFMODE_ALTFN_ON
    LDA #(~(1 << DECODER_SFR_BIT::SFWM1) & $F0) | (1 << DECODER_SFR_BIT::ALTFN)
    STA DECODER_SFR
.ENDMAC

; SFMODE_ALTFN_OFF macro
; Modifies: A
;
; Leaves Alternative Function Mode.
.MACRO SFMODE_ALTFN_OFF
    LDA #(~(1 << DECODER_SFR_BIT::SFWM1) & $F0)
    STA DECODER_SFR
.ENDMAC

; SFMODE_SYSCTX_ALTFN_ON macro
; Modifies: A
;
; Enters System Context Mode and Alternative Function Mode.
.MACRO SFMODE_SYSCTX_ALTFN_ON
    LDA #(~((1 << DECODER_SFR_BIT::SFWM1) | (1 << DECODER_SFR_BIT::SFWM0)) & $F0) | (1 << DECODER_SFR_BIT::ALTFN) | (1 << DECODER_SFR_BIT::SYSCTX)
    STA DECODER_SFR
.ENDMACRO

; SFMODE_RESET
; Modifies: n/a
;
; Returns the Address Decoder to its standard operating mode.
.MACRO SFMODE_RESET
    STZ DECODER_SFR
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