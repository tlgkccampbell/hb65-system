; hb65-bios-lcd.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS LCD routines"

.INCLUDE    "../hb65-system.inc"

.IMPORT     TIME_DELAY_50US, TIME_DELAY_1MS, TIME_DELAY_50MS

; LCD state
.SEGMENT "SYSZP"

_LCD_COLS                = 20
_LCD_ROWS                = 4
_LCD_CURSOR_X:           .RES 1
_LCD_CURSOR_Y:           .RES 1 

; LCD routines
.SEGMENT "BIOS"

; _LCD_DDRAM_OFFSETS
; A lookup table mapping LCD rows to DDRAM offsets.
_LCD_DDRAM_OFFSETS:
  .BYTE $00
  .BYTE $40
  .BYTE $14
  .BYTE $54
  
; _LCD_CONTROL_PINS enum
; Describes the pins of VIA1 PORTB that are used to control the LCD panel.
.ENUM _LCD_CONTROL_PINS
    EN = 7
    RW = 6
    RS = 5
    BL = 4
.ENDENUM

; _LCD_TOGGLE_ENABLE
; Modifies: n/a
;
; Toggles the LCD's enable line by pulling it high, then low.
.PROC _LCD_TOGGLE_ENABLE
    PHA

    ; Store the bottom nibble of A in Scratch Register 7.
    AND #$0F
    STA DECODER_SR7

    ; Load the top nibble of VIA1 ORB into A, then OR it
    ; with the bottom nibble we stored in Scratch Register 7.
    LDA SYSTEM_VIA_ORB
    AND #$F0
    ORA DECODER_SR7

    ; Pull the enable pin high, then low.
    ORA #(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB
    AND #<~(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB

    PLA
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

    ; Read nibble
    LDA SYSTEM_VIA_IRB
    AND #$0F
    PHA

    ; Pull enable line low
    LDA SYSTEM_VIA_ORB
    AND #<~(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
.ENDPROC

; _LCD_READ_BYTE procedure
; Modifies: A
;
; Reads a byte from the LCD panel and places it into the A register.
.PROC _LCD_READ_BYTE
    PHX
    SFMODE_SYSCTX_ALTFN_ON
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
    SFMODE_RESET
    PLX
    RTS
.ENDPROC

; _LCD_WRITE_BYTE procedure
; Modifies: A
;
; Writes a byte from the A register to the LCD panel.
.PROC _LCD_WRITE_BYTE
    ; Present the high nibble.
    PHA
    ROR
    ROR
    ROR
    ROR
    AND #$0F
    JSR _LCD_TOGGLE_ENABLE

    ; Present the low nibble.
    PLA
    AND #$0F
    JSR _LCD_TOGGLE_ENABLE
    RTS
.ENDPROC

; _LCD_START_DATA_RD
; Modifies: n/a
;
; Prepares VIA1 to read data from the LCD panel.
.PROC _LCD_START_DATA_RD
    PHX
    PHA
    SFMODE_SYSCTX_ALTFN_ON
        ; Set lower nibble of VIA1 PORTB to inputs.
        LDA #$F0
        STA SYSTEM_VIA_DDRB

        ; Pull RW high, RS high.
        LDA SYSTEM_VIA_ORB
        ORA #(1 << _LCD_CONTROL_PINS::RW)
        ORA #(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    PLA
    PLX
    RTS
.ENDPROC

; _LCD_START_DATA_WR
; Modifies: n/a
;
; Prepares VIA1 to write data to the LCD panel.
.PROC _LCD_START_DATA_WR
    PHX
    PHA
    SFMODE_SYSCTX_ALTFN_ON
        ; Set lower nibble of VIA1 PORTB to outputs.
        LDA #$FF
        STA SYSTEM_VIA_DDRB

        ; Pull RW low, RS high.
        LDA SYSTEM_VIA_ORB
        AND #<~(1 << _LCD_CONTROL_PINS::RW)
        ORA #(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    PLA
    PLX
    RTS
.ENDPROC

; _LCD_START_INSTR_RD
; Modifies: n/a
;
; Prepares VIA1 to read instruction data from the LCD panel.
.PROC _LCD_START_INSTR_RD
    PHX
    PHA
    SFMODE_SYSCTX_ALTFN_ON
        ; Set lower nibble of VIA1 PORTB to inputs.
        LDA #$F0
        STA SYSTEM_VIA_DDRB

        ; Pull RW high, RS low.
        LDA SYSTEM_VIA_ORB
        ORA #(1 << _LCD_CONTROL_PINS::RW)
        AND #<~(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    PLA
    PLX
    RTS
.ENDPROC

; _LCD_START_INSTR_WR
; Modifies: n/a
;
; Prepares VIA1 to write instructions to the LCD panel.
.PROC _LCD_START_INSTR_WR
    PHX
    PHA
    SFMODE_SYSCTX_ALTFN_ON
        ; Set lower nibble of VIA1 PORTB to outputs.
        LDA #$FF
        STA SYSTEM_VIA_DDRB

        ; Pull RW low, RS low.
        LDA SYSTEM_VIA_ORB
        AND #<~(1 << _LCD_CONTROL_PINS::RW)
        AND #<~(1 << _LCD_CONTROL_PINS::RS)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    PLA
    PLX
    RTS
.ENDPROC

; LCD_ENABLE_LIGHT
; Modifies: A, flags
;
; Turns on the LCD's white backlight.
.PROC LCD_ENABLE_LIGHT
    PHX
    PHA
    SFMODE_SYSCTX_ALTFN_ON
        LDA SYSTEM_VIA_ORB
        AND #<~(1 << _LCD_CONTROL_PINS::BL)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    PLA
    PLX
    RTS
.ENDPROC
.EXPORT LCD_ENABLE_LIGHT

; LCD_DISABLE_LIGHT
; Modifies: A, flags
;
; Turns off the LCD's white backlight.
.PROC LCD_DISABLE_LIGHT
    PHX
    PHA
    SFMODE_SYSCTX_ALTFN_ON
        LDA SYSTEM_VIA_ORB
        ORA #(1 << _LCD_CONTROL_PINS::BL)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    PLA
    PLX
    RTS
.ENDPROC
.EXPORT LCD_DISABLE_LIGHT

; _LCD_WAIT procedure
; Modifies: n/a
;
; Waits for the LCD panel to become ready.
.PROC _LCD_WAIT
    PHX
    PHA
    SFMODE_SYSCTX_ALTFN_ON
        ; Preserve the current state of the LCD port.
        LDA SYSTEM_VIA_DDRB
        PHA
        LDA SYSTEM_VIA_ORB
        PHA
    SFMODE_RESET

    ; Read until bit 7 is clear.
    JSR _LCD_START_INSTR_RD
  : JSR _LCD_READ_BYTE
    AND #%10000000
    BMI :-

    SFMODE_SYSCTX_ALTFN_ON
        ; Restore the LCD port's state.
        PLA
        STA SYSTEM_VIA_ORB
        PLA
        STA SYSTEM_VIA_DDRB
    SFMODE_RESET
    PLA
    PLX    
    RTS
.ENDPROC

; _LCD_CHECK_NEWLINE procedure
; Modifies: n/a
; 
; Checks the contents of A to determine whether it represents a newline character.
; If so, advances the LCD cursor to the next line. On return, the carry flag indicates
; whether a newline was handled.
.PROC _LCD_CHECK_NEWLINE
    ; Is A equal to \n ($0A)? If not, clear carry and immediately return.
    CMP #$0A
    BEQ TRY_ADVANCE_LINE
    CLC
    RTS

    ; Advance to the next line.
  TRY_ADVANCE_LINE:
    PHA
    PHX
    SFMODE_SYSCTX_ALTFN_ON
      ADVANCE:
        ; Make sure we haven't reached the last line of the display.
        ; If we have, immediately return.
        LDA _LCD_CURSOR_Y
        CMP #_LCD_ROWS-1
        BEQ ADVANCE_DONE

        ; Advance to the next line and update the cursor position.
        STZ _LCD_CURSOR_X
        INC _LCD_CURSOR_Y
        JSR _LCD_UPDATE_CURSOR
      ADVANCE_DONE:
    SFMODE_RESET
    PLX
    PLA
    SEC
    RTS
.ENDPROC

; _LCD_CHECK_OVERFLOW procedure
; Modifies: n/a
;
; Check the LCD cursor position to determine if printing a character will
; overflow the current line. If so, advances the LCD cursor to the next line.
; On return, the carry flag is set if the display is full.
.PROC _LCD_CHECK_OVERFLOW
    PHA
    PHX
    SFMODE_SYSCTX_ALTFN_ON
        ; Make sure we're at the last column of the display.
        ; If not, immediately return.
        LDA _LCD_CURSOR_X
        CMP #_LCD_COLS
        BNE ADVANCE_DONE

        ; Make sure we haven't reached the last line of the display.
        ; If we have, set the carry flag and return.
        LDA _LCD_CURSOR_Y
        CMP #_LCD_ROWS-1
        BNE ADVANCE_FAIL

        ; Move the cursor to the next line.
        STZ _LCD_CURSOR_X
        INC _LCD_CURSOR_Y
        JSR _LCD_UPDATE_CURSOR
  ADVANCE_DONE:
    SFMODE_RESET
    PLX
    PLA
    CLC
    RTS
  ADVANCE_FAIL:
    SFMODE_RESET
    PLX
    PLA
    SEC
    RTS
.ENDPROC

; LCD_PUTC procedure
; Modifies: n/a
;
; Writes the byte passed in the A register to the LCD panel.
.PROC LCD_PUTC
    ; Advance the cursor if necessary.
    JSR _LCD_CHECK_NEWLINE
    BCS DONE
    JSR _LCD_CHECK_OVERFLOW
    BCS DONE

    ; Wait for the LCD to become ready.
    PHA
    JSR _LCD_WAIT
    JSR _LCD_START_DATA_WR
    SFMODE_SYSCTX_ALTFN_ON
        INC _LCD_CURSOR_X

        ; Present the high nibble.
        PHA
        ROR
        ROR
        ROR
        ROR
        AND #$0F
        JSR _LCD_TOGGLE_ENABLE

        ; Present the low nibble.
        PLA
        AND #$0F
        JSR _LCD_TOGGLE_ENABLE
    SFMODE_RESET
    PLA

  DONE:
    RTS
.ENDPROC
.EXPORT LCD_PUTC

; LCD_CLEAR procedure
; Modifies: A, X, flags
;
; Clears the LCD panel.
.PROC LCD_CLEAR
    JSR _LCD_WAIT
    JSR _LCD_START_INSTR_WR

    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00000001
        JSR _LCD_WRITE_BYTE
        STZ _LCD_CURSOR_X
        STZ _LCD_CURSOR_Y
    SFMODE_RESET
    JSR _LCD_UPDATE_CURSOR

    RTS
.ENDPROC
.EXPORT LCD_CLEAR

; LCD_INIT procedure
; Modifies: n/a
;
; Initializes the front panel LCD.
.PROC LCD_INIT
    PHA
    PHX

    ; Initialize the character LCD.
    JSR LCD_DISABLE_LIGHT
    STZ _LCD_CURSOR_X
    STZ _LCD_CURSOR_Y
    JSR _LCD_START_INSTR_WR

    ; Function set (8-bit mode, 1st try)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%0011
        JSR _LCD_TOGGLE_ENABLE
    SFMODE_RESET
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS

    ; Function set (8-bit mode, 2nd try)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%0011
        JSR _LCD_TOGGLE_ENABLE
    SFMODE_RESET
    JSR TIME_DELAY_50US

    ; Function set (8-bit mode, 3rd try)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%0011
        JSR _LCD_TOGGLE_ENABLE
    SFMODE_RESET
    JSR TIME_DELAY_50US

    ; Function set (4-bit mode)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%0010
        JSR _LCD_TOGGLE_ENABLE
    SFMODE_RESET
    JSR TIME_DELAY_50US

    ; Function set (4 lines, 5x8 font)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00101000
        JSR _LCD_WRITE_BYTE
    SFMODE_RESET
    JSR TIME_DELAY_1MS

    ; Display on, cursor on, blinking on
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00001111
        JSR _LCD_WRITE_BYTE
    SFMODE_RESET
    JSR TIME_DELAY_1MS

    ; Clear display
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00000001
        JSR _LCD_WRITE_BYTE
    SFMODE_RESET
    JSR TIME_DELAY_1MS

    ; Entry mode set
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00000110
        JSR _LCD_WRITE_BYTE
    SFMODE_RESET
    JSR TIME_DELAY_1MS

    PLX
    PLA
    RTS    
.ENDPROC
.EXPORT LCD_INIT

; _LCD_UPDATE_CURSOR
; Modifies: n/a
; 
; Sets the LCD panel's current DDRAM address to match the values stored
; for the cursor in LCD_CURSOR_X and LCD_CURSOR_Y.
.PROC _LCD_UPDATE_CURSOR
    PHA
    PHX

    JSR _LCD_WAIT
    JSR _LCD_START_INSTR_WR

    SFMODE_SYSCTX_ALTFN_ON
        LDX _LCD_CURSOR_Y
        LDA _LCD_DDRAM_OFFSETS, X
        ADC _LCD_CURSOR_X

        ORA #%10000000
        JSR _LCD_WRITE_BYTE
    SFMODE_RESET

    PLX
    PLA
    RTS
.ENDPROC