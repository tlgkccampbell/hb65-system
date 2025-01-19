.IFNDEF _INCLUDE_SYSTEM_
_INCLUDE_SYSTEM_ = 1

.INCLUDE    "hb65-registers.inc"

; SYSCTX_START macro
; Modifies: A, flags
;
; Enters System Context Mode.
.MACRO SYSCTX_START
    LDA #(~(1 << DECODER_SFR_BIT::SFWM0) & $F0) | (1 << DECODER_SFR_BIT::SYSCTX)
    STA DECODER_SFR
.ENDMAC

; SYSCTX_END macro
; Modifies: A, flags
;
; Leaves System Context Mode.
.MACRO SYSCTX_END
    LDA #(~(1 << DECODER_SFR_BIT::SFWM0) & $F0)
    STA DECODER_SFR
.ENDMAC

; ALTFN_START macro
; Modifies: A, flags
;
; Enters Alternative Function Mode.
.MACRO ALTFN_START
    LDA #(~(1 << DECODER_SFR_BIT::SFWM1) & $F0) | (1 << DECODER_SFR_BIT::ALTFN)
    STA DECODER_SFR
.ENDMAC

; ALTFN_END macro
; Modifies: A, flags
;
; Leaves Alternative Function Mode.
.MACRO ALTFN_END
    LDA #(~(1 << DECODER_SFR_BIT::SFWM1) & $F0)
    STA DECODER_SFR
.ENDMAC

; SYSCTX_ALTFN_START macro
; Modifies: A, flags
;
; Enters System Context Mode and Alternative Function Mode.
.MACRO SYSCTX_ALTFN_START
    LDA #(~((1 << DECODER_SFR_BIT::SFWM1) | (1 << DECODER_SFR_BIT::SFWM0)) & $F0) | (1 << DECODER_SFR_BIT::ALTFN) | (1 << DECODER_SFR_BIT::SYSCTX)
    STA DECODER_SFR
.ENDMACRO

; SYSCTX_ALTFN_END
; Modifies: n/a
;
; Leaves System Context Mode and Alternative Function Mode.
.MACRO SYSCTX_ALTFN_END
    STZ DECODER_SFR
.ENDMACRO

; STADDR macro
; Modifies: A, flags
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