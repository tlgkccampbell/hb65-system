; hb65-bios-gpio.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS GPIO routines"

.INCLUDE    "../hb65-system.inc"

.IMPORT     TIME_DELAY_50MS

; GPIO routines
.SEGMENT "BIOS"

; GPIO_SET_LEDS procedure
; Modifies: n/a
;
; Sets the state of the front panel LEDs to match the value passed in the A register.
.PROC GPIO_SET_LEDS
    PHA
    PHY
    TAY

    LDA DECODER_RLR
    PHA
    ORA #(1 << DECODER_RLR_BIT::SDEFREN)
    STA DECODER_RLR 

    SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::ALTFN)
        STY SYSTEM_VIA_ORA
    SFMODE_POP

    PLA
    STA DECODER_RLR

    PLY
    PLA
    RTS
.ENDPROC
.EXPORT GPIO_SET_LEDS

; GPIO_BUZZER_ON procedure
; Modifies: A, flags
;
; Turns the buzzer on.
.PROC GPIO_BUZZER_ON
    LDA DECODER_DCR
    ORA #(1 << DECODER_DCR_BIT::BUZZ)
    STA DECODER_DCR
    RTS
.ENDPROC
.EXPORT GPIO_BUZZER_ON

; GPIO_BUZZER_OFF procedure
; Modifies: A, flags
;
; Turns the buzzer off.
.PROC GPIO_BUZZER_OFF
    LDA DECODER_DCR
    AND #<~(1 << DECODER_DCR_BIT::BUZZ)
    STA DECODER_DCR
    RTS
.ENDPROC
.EXPORT GPIO_BUZZER_OFF

; GPIO_BUZZER_BEEP procedure
; Modifies: A, flags
;
; Beeps the buzzer.
.PROC GPIO_BUZZER_BEEP
    JSR GPIO_BUZZER_ON
    JSR TIME_DELAY_50MS
    JSR TIME_DELAY_50MS
    JSR GPIO_BUZZER_OFF
    RTS
.ENDPROC
.EXPORT GPIO_BUZZER_BEEP

; GPIO_INIT procedure
; Modifies; A, flags
;
; Initializes the system's GPIO devices.
.PROC GPIO_INIT
    ; Initialize VIA1.
    SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX) | (1 << DECODER_DCR_BIT::ALTFN)
        LDA #$FF
        STA SYSTEM_VIA_DDRA
        STA SYSTEM_VIA_DDRB
    SFMODE_POP
    RTS
.ENDPROC
.EXPORT GPIO_INIT