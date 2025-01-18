; hb65-bios-gpio.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS GPIO routines"

.INCLUDE    "hb65-system.inc"

.IMPORT     TIME_DELAY_50US, TIME_DELAY_1MS, TIME_DELAY_50MS

; GPIO routines
.SEGMENT "BIOS"

; _GPIO_CONTROL_PINS enum
; Describes the pins of VIA1 PORTB that are used to control the LCD panel.
.ENUM _LCD_CONTROL_PINS
    EN = 7
    RW = 6
    RS = 5
    BL = 4
.ENDENUM

; GPIO_SET_LEDS procedure
; Modifies: A, flags
;
; Sets the state of the front panel LEDs to match the value passed in the A register.
.PROC GPIO_SET_LEDS
    PHA
    SYSCTX_ALTFN_START
        ; Set PORTA on VIA1
        PLA
        STA SYSTEM_VIA_ORA
    SYSCTX_ALTFN_END
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

; _LCD_TOGGLE_ENABLE
; Modifies: A, SR7, flags
;
; Toggles the LCD's enable line by pulling it high, then low.
.PROC _LCD_TOGGLE_ENABLE
    LDA SYSTEM_VIA_ORB
    AND #$F0
    ORA #(1 << _LCD_CONTROL_PINS::EN)
    ORA DECODER_SR7
    STA SYSTEM_VIA_ORB
    AND #<~(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB
    RTS
.ENDPROC

; _LCD_READ_NIBBLE procedure
; Modifies: A, X, flags
;
; Reads a nibble from the LCD.
.PROC _LCD_READ_NIBBLE
    ; Pull enable line high
    LDA SYSTEM_VIA_ORB
    ORA #(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB
    PHA

    ; Read nibble
    LDA SYSTEM_VIA_IRB
    AND #$0F
    TAX

    ; Pull enable line low
    PLA
    AND #<~(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB

    TXA
    RTS
.ENDPROC

; GPIO_LCD_START_DATARD
; Modifies: A, flags
;
; Prepares VIA1 to read data from the LCD panel.
.PROC GPIO_LCD_START_DATARD
    SYSCTX_ALTFN_START
        ; Set lower nibble of VIA1 PORTB to inputs.
        LDA #$F0
        STA SYSTEM_VIA_DDRB

        ; Pull RW high, RS high.
        LDA SYSTEM_VIA_ORB
        ORA #(1 << _LCD_CONTROL_PINS::RW)
        ORA #(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_START_DATARD

; GPIO_LCD_START_DATAWR
; Modifies: A, flags
;
; Prepares VIA1 to write data to the LCD panel.
.PROC GPIO_LCD_START_DATAWR
    SYSCTX_ALTFN_START
        ; Set lower nibble of VIA1 PORTB to outputs.
        LDA #$FF
        STA SYSTEM_VIA_DDRB

        ; Pull RW low, RS high.
        LDA SYSTEM_VIA_ORB
        AND #<~(1 << _LCD_CONTROL_PINS::RW)
        ORA #(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_START_DATAWR

; GPIO_LCD_START_INSTRRD
; Modifies: A, flags
;
; Prepares VIA1 to read instructions from the LCD panel.
.PROC GPIO_LCD_START_INSTRRD
    SYSCTX_ALTFN_START
        ; Set lower nibble of VIA1 PORTB to inputs.
        LDA #$F0
        STA SYSTEM_VIA_DDRB

        ; Pull RW high, RS low.
        LDA SYSTEM_VIA_ORB
        ORA #(1 << _LCD_CONTROL_PINS::RW)
        AND #<~(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_START_INSTRWR

; GPIO_LCD_START_INSTRWR
; Modifies: A, flags
;
; Prepares VIA1 to write instructions to the LCD panel.
.PROC GPIO_LCD_START_INSTRWR
    SYSCTX_ALTFN_START
        ; Set lower nibble of VIA1 PORTB to outputs.
        LDA #$FF
        STA SYSTEM_VIA_DDRB

        ; Pull RW low, RS low.
        LDA SYSTEM_VIA_ORB
        AND #<~(1 << _LCD_CONTROL_PINS::RW)
        AND #<~(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_START_INSTRWR

; GPIO_LCD_ENABLE_LIGHT
; Modifies: A, flags
;
; Turns on the LCD's white backlight.
.PROC GPIO_LCD_ENABLE_LIGHT
    SYSCTX_ALTFN_START
        LDA SYSTEM_VIA_ORB
        AND #<~(1 << _LCD_CONTROL_PINS::BL)
        STA SYSTEM_VIA_ORB
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_ENABLE_LIGHT

; GPIO_LCD_DISABLE_LIGHT
; Modifies: A, flags
;
; Turns off the LCD's white backlight.
.PROC GPIO_LCD_DISABLE_LIGHT
    SYSCTX_ALTFN_START
        LDA SYSTEM_VIA_ORB
        ORA #(1 << _LCD_CONTROL_PINS::BL)
        STA SYSTEM_VIA_ORB
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_DISABLE_LIGHT

; GPIO_LCD_WAIT procedure
; Modifies: A, flags
;
; Waits for the LCD panel to become ready.
.PROC GPIO_LCD_WAIT
    SYSCTX_ALTFN_START
        ; Preserve the current state of the LCD port.
        LDA SYSTEM_VIA_DDRB
        PHA
        LDA SYSTEM_VIA_ORB
        PHA
    SYSCTX_ALTFN_END

    ; Read until bit 7 is clear.
  : JSR GPIO_LCD_GETC
    BIT #%10000000
    BMI :-

    SYSCTX_ALTFN_START
        ; Restore the LCD port's state.
        PLA
        STA SYSTEM_VIA_ORB
        PLA
        STA SYSTEM_VIA_DDRB
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_WAIT

; GPIO_LCD_GETC procedure
; Modifies: A, X, SR7, flags
;
; Reads a byte from the LCD panel and places it into the A register.
.PROC GPIO_LCD_GETC
    JSR GPIO_LCD_START_INSTRRD
    SYSCTX_ALTFN_START
        ; Read the high nibble.
        JSR _LCD_READ_NIBBLE
        ASL
        ASL
        ASL
        ASL
        STA DECODER_SR7

        ; Read the low nibble.
        JSR _LCD_READ_NIBBLE
        ORA DECODER_SR7
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_GETC

; GPIO_LCD_PUTC procedure
; Modifies: A, X, SR7, flags
;
; Writes the byte passed in the A register to the LCD panel.
.PROC GPIO_LCD_PUTC
    ; Wait for the LCD to become ready.
    PHA
    JSR GPIO_LCD_WAIT
    JSR GPIO_LCD_START_DATAWR
    SYSCTX_ALTFN_START
        PLA
      NO_WAIT:
        ; Present the high nibble.
        PHA
        ROR
        ROR
        ROR
        ROR
        AND #$0F
        STA DECODER_SR7
        JSR _LCD_TOGGLE_ENABLE

        ; Present the low nibble.
        PLA
      WRITE_NIBBLE:
        AND #$0F
        STA DECODER_SR7
        JSR _LCD_TOGGLE_ENABLE
    SYSCTX_ALTFN_END
    RTS
.ENDPROC
.EXPORT GPIO_LCD_PUTC

; GPIO_LCD_CLR procedure
; Modifies: A, X, flags
;
; Clears the LCD panel.
.PROC GPIO_LCD_CLR
    JSR GPIO_LCD_WAIT
    JSR GPIO_LCD_START_INSTRWR

    SYSCTX_ALTFN_START
    LDA #%00000001
    JSR GPIO_LCD_PUTC::NO_WAIT

    RTS
.ENDPROC
.EXPORT GPIO_LCD_CLR

; GPIO_LCD_SET_DDRAM_SDDR
; Modifies: A, X, flags
; 
; Sets the LCD panel's current DDRAM address to the value stored in the A register.
.PROC GPIO_LCD_SET_DDRAM_ADDR
    PHA
    JSR GPIO_LCD_WAIT
    JSR GPIO_LCD_START_INSTRWR

    SYSCTX_ALTFN_START
    PLA
    ORA #%10000000
    JSR GPIO_LCD_PUTC::NO_WAIT

    RTS
.ENDPROC
.EXPORT GPIO_LCD_SET_DDRAM_ADDR

; GPIO_INIT procedure
; Modifies; A, flags
;
; Initializes the system's GPIO devices.
.PROC GPIO_INIT
    ; Initialize VIA1.
    SYSCTX_ALTFN_START
        LDA #$FF
        STA SYSTEM_VIA_DDRA
    SYSCTX_ALTFN_END

    ; Initialize the character LCD.
    JSR GPIO_LCD_DISABLE_LIGHT
    JSR GPIO_LCD_START_INSTRWR

    ; Function set (8-bit mode, 1st try)
    SYSCTX_ALTFN_START
    LDA #%0011
    JSR GPIO_LCD_PUTC::WRITE_NIBBLE
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS

    ; Function set (8-bit mode, 2nd try)
    SYSCTX_ALTFN_START
    LDA #%0011
    JSR GPIO_LCD_PUTC::WRITE_NIBBLE
    JSR TIME_DELAY_50US

    ; Function set (8-bit mode, 3rd try)
    SYSCTX_ALTFN_START
    LDA #%0011
    JSR GPIO_LCD_PUTC::WRITE_NIBBLE
    JSR TIME_DELAY_50US

    ; Function set (4-bit mode)
    SYSCTX_ALTFN_START
    LDA #%0010
    JSR GPIO_LCD_PUTC::WRITE_NIBBLE
    JSR TIME_DELAY_50US

    ; Function set (4 lines, 5x8 font)
    SYSCTX_ALTFN_START
    LDA #%00101000
    JSR GPIO_LCD_PUTC::NO_WAIT
    JSR TIME_DELAY_1MS

    ; Display on, cursor on, blinking on
    SYSCTX_ALTFN_START
    LDA #%00001111
    JSR GPIO_LCD_PUTC::NO_WAIT
    JSR TIME_DELAY_1MS

    ; Clear display
    SYSCTX_ALTFN_START
    LDA #%00000001
    JSR GPIO_LCD_PUTC::NO_WAIT
    JSR TIME_DELAY_1MS

    ; Entry mode set
    SYSCTX_ALTFN_START
    LDA #%00000110
    JSR GPIO_LCD_PUTC::NO_WAIT
    JSR TIME_DELAY_1MS
    RTS
.ENDPROC
.EXPORT GPIO_INIT