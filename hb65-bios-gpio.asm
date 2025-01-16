; hb65-bios-gpio.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS GPIO routines"

.INCLUDE    "hb65-system.inc"

; GPIO routines
.SEGMENT "BIOS"

; GPIO_INIT procedure
; Modifies; A, flags
;
; Initializes the system's GPIO devices.
.PROC GPIO_INIT
    ALTFN_START
        ; Set VIA1's ports as outputs.
        LDA #$FF
        STA SYSTEM_VIA_DDRA
        STA SYSTEM_VIA_DDRB
    ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_INIT

; GPIO_SET_LEDS procedure
; Modifies: A, flags
;
; Sets the state of the front panel LEDs to match the value passed in the A register.
.PROC GPIO_SET_LEDS
    PHA
    ALTFN_START
        ; Set PORTA on VIA1
        PLA
        STA SYSTEM_VIA_ORA
    ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_SET_LEDS
