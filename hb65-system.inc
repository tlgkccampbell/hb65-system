.IFNDEF _INCLUDE_SYSTEM_
_INCLUDE_SYSTEM_ = 1

.INCLUDE    "hb65-registers.inc"

; SYSCTX_START macro
; Modifies: A, flags
;
; Enters the system context.
.MACRO SYSCTX_START
    LDA #$01
    STA DECODER_SCR
.ENDMAC

; SYSCTX_END macro
; Modifies: n/a
;
; Leaves the system context.
.MACRO SYSCTX_END
    STZ DECODER_SCR
.ENDMAC

; ALTFN_START macro
; Modifies: A, flags
;
; Enters Alternative Function mode.
.MACRO ALTFN_START
    LDA #$01
    STA DECODER_AFR
.ENDMAC

; ALTFN_END macro
; Modifies: n/a
;
; Leaves Alternative Function mode.
.MACRO ALTFN_END
    STZ DECODER_AFR
.ENDMAC

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