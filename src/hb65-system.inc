.IFNDEF _INCLUDE_SYSTEM_
_INCLUDE_SYSTEM_ = 1

.INCLUDE    "hb65-registers.inc"

.GLOBAL     SYSCTX_START, SYSCTX_END, ALTFN_START, ALTFN_END

; SFMODE_SYSCTX_ON macro
; Modifies: X
;
; Enters System Context Mode.
.MACRO SFMODE_SYSCTX_ON
    JSR SYSCTX_START
.ENDMAC

; SFMODE_SYSCTX_OFF macro
; Modifies: X
;
; Leaves System Context Mode.
.MACRO SFMODE_SYSCTX_OFF
    JSR SYSCTX_END
.ENDMAC

; SFMODE_ALTFN_ON
; Modifies: n/a
;
; Enters Alternative Function Mode.
.MACRO SFMODE_ALTFN_ON
    JSR ALTFN_START
.ENDMAC

; SFMODE_ALTFN_OFF macro
; Modifies: n/a
;
; Leaves Alternative Function Mode.
.MACRO SFMODE_ALTFN_OFF
    JSR ALTFN_END
.ENDMAC

; SFMODE_SYSCTX_ALTFN_ON macro
; Modifies: X
;
; Enters System Context Mode and Alternative Function Mode.
.MACRO SFMODE_SYSCTX_ALTFN_ON
    JSR SYSCTX_START
    JSR ALTFN_START
.ENDMACRO

; SFMODE_RESET
; Modifies: X
;
; Returns the Address Decoder to its standard operating mode.
.MACRO SFMODE_RESET
    JSR ALTFN_END
    JSR SYSCTX_END
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