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

; _LCD_START_DATA_RD
; Modifies: A, flags
;
; Prepares VIA1 to read data from the LCD panel.
.PROC _LCD_START_DATA_RD
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
    RTS
.ENDPROC

; _LCD_START_DATA_WR
; Modifies: A, flags
;
; Prepares VIA1 to write data to the LCD panel.
.PROC _LCD_START_DATA_WR
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
    RTS
.ENDPROC

; _LCD_START_INSTR_RD
; Modifies: A, flags
;
; Prepares VIA1 to read instructions from the LCD panel.
.PROC _LCD_START_INSTR_RD
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
    RTS
.ENDPROC

; _LCD_START_INSTR_WR
; Modifies: A, flags
;
; Prepares VIA1 to write instructions to the LCD panel.
.PROC _LCD_START_INSTR_WR
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
    RTS
.ENDPROC

; LCD_ENABLE_LIGHT
; Modifies: A, flags
;
; Turns on the LCD's white backlight.
.PROC LCD_ENABLE_LIGHT
    SFMODE_SYSCTX_ALTFN_ON
        LDA SYSTEM_VIA_ORB
        AND #<~(1 << _LCD_CONTROL_PINS::BL)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    RTS
.ENDPROC
.EXPORT LCD_ENABLE_LIGHT

; LCD_DISABLE_LIGHT
; Modifies: A, flags
;
; Turns off the LCD's white backlight.
.PROC LCD_DISABLE_LIGHT
    SFMODE_SYSCTX_ALTFN_ON
        LDA SYSTEM_VIA_ORB
        ORA #(1 << _LCD_CONTROL_PINS::BL)
        STA SYSTEM_VIA_ORB
    SFMODE_RESET
    RTS
.ENDPROC
.EXPORT LCD_DISABLE_LIGHT

; _LCD_WAIT procedure
; Modifies: A, flags
;
; Waits for the LCD panel to become ready.
.PROC _LCD_WAIT
    SFMODE_SYSCTX_ALTFN_ON
        ; Preserve the current state of the LCD port.
        LDA SYSTEM_VIA_DDRB
        PHA
        LDA SYSTEM_VIA_ORB
        PHA
    SFMODE_RESET

    ; Read until bit 7 is clear.
  : JSR LCD_GETC
    BIT #%10000000
    BMI :-

    SFMODE_SYSCTX_ALTFN_ON
        ; Restore the LCD port's state.
        PLA
        STA SYSTEM_VIA_ORB
        PLA
        STA SYSTEM_VIA_DDRB
    SFMODE_RESET
    RTS
.ENDPROC

; LCD_GETC procedure
; Modifies: A, X, SR7, flags
;
; Reads a byte from the LCD panel and places it into the A register.
.PROC LCD_GETC
    JSR _LCD_START_INSTR_RD
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
    RTS
.ENDPROC
.EXPORT LCD_GETC

; _LCD_CHECK_NEWLINE procedure
; Modifies: X, Y, flags
; 
; Checks the contents of A to determine whether it represents a newline character.
; If so, advances the LCD cursor to the next line. On return, the carry flag indicates
; whether a newline was handled.
.PROC _LCD_CHECK_NEWLINE
    ; Is A equal to \n ($0A)?
    PHA
    CMP #$0A
    BNE RET_NO_NEWLINE

    ; Advance to the next line.
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
    PLA
    SEC
    RTS
RET_NO_NEWLINE:
    PLA
    CLC
    RTS
.ENDPROC

; _LCD_CHECK_OVERFLOW procedure
; Modifies: X, Y, flags
;
; Check the LCD cursor position to determine if printing a character will
; overflow the current line. If so, advances the LCD cursor to the next line.
; On return, the carry flag is set if the display is full.
.PROC _LCD_CHECK_OVERFLOW
    ; Is LCD_CURSOR_X past the edge of the display? If not,
    ; clear the carry flag and return.
    PHA
    PHY
    SFMODE_SYSCTX_ALTFN_ON
        LDA _LCD_CURSOR_X
        CMP #_LCD_COLS
        BEQ TRY_ADVANCE
    SFMODE_RESET
    PLY
    PLA
    CLC
    RTS

    ; Attempt to advance to the next line, if there's enough room.
  TRY_ADVANCE:
        ; Make sure we haven't reached the last line of the display.
        ; If we have, set the carry flag and return.
        LDA _LCD_CURSOR_Y
        CMP #_LCD_ROWS-1
        BNE ADVANCE
    SFMODE_RESET
        PLY
        PLA
        SEC
        RTS
      ADVANCE:
        STZ _LCD_CURSOR_X
        INC _LCD_CURSOR_Y
        JSR _LCD_UPDATE_CURSOR
    SFMODE_RESET
    PLY
    PLA
    CLC
    RTS
.ENDPROC

; LCD_PUTC procedure
; Modifies: A, X, Y, SR7, flags
;
; Writes the byte passed in the A register to the LCD panel.
.PROC LCD_PUTC
    ; Advance the cursor if necessary.
    JSR _LCD_CHECK_NEWLINE
    BCS DONE
    JSR _LCD_CHECK_OVERFLOW
    BCS DONE

    ; Output the character in A.
OUTPUT:
    PHA
    ; Wait for the LCD to become ready.
    JSR _LCD_WAIT
    JSR _LCD_START_DATA_WR
    SFMODE_SYSCTX_ALTFN_ON
        PLA
        INC _LCD_CURSOR_X
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
    SFMODE_RESET
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
    JSR LCD_PUTC::NO_WAIT

    STZ _LCD_CURSOR_X
    STZ _LCD_CURSOR_Y
    JSR _LCD_UPDATE_CURSOR

    RTS
.ENDPROC
.EXPORT LCD_CLEAR

; LCD_INIT procedure
; Modifies:
;
; Initializes the front panel LCD.
.PROC LCD_INIT
    ; Initialize the character LCD.
    JSR LCD_DISABLE_LIGHT
    STZ _LCD_CURSOR_X
    STZ _LCD_CURSOR_Y
    JSR _LCD_START_INSTR_WR

    ; Function set (8-bit mode, 1st try)
    SFMODE_SYSCTX_ALTFN_ON
    LDA #%0011
    JSR LCD_PUTC::WRITE_NIBBLE
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS

    ; Function set (8-bit mode, 2nd try)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%0011
        JSR LCD_PUTC::WRITE_NIBBLE
    SFMODE_IMPLIED
    JSR TIME_DELAY_50US

    ; Function set (8-bit mode, 3rd try)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%0011
        JSR LCD_PUTC::WRITE_NIBBLE
    SFMODE_IMPLIED
    JSR TIME_DELAY_50US

    ; Function set (4-bit mode)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%0010
        JSR LCD_PUTC::WRITE_NIBBLE
    SFMODE_IMPLIED
    JSR TIME_DELAY_50US

    ; Function set (4 lines, 5x8 font)
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00101000
        JSR LCD_PUTC::NO_WAIT
    SFMODE_IMPLIED
    JSR TIME_DELAY_1MS

    ; Display on, cursor on, blinking on
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00001111
        JSR LCD_PUTC::NO_WAIT
    SFMODE_IMPLIED
    JSR TIME_DELAY_1MS

    ; Clear display
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00000001
        JSR LCD_PUTC::NO_WAIT
    SFMODE_IMPLIED
    JSR TIME_DELAY_1MS

    ; Entry mode set
    SFMODE_SYSCTX_ALTFN_ON
        LDA #%00000110
        JSR LCD_PUTC::NO_WAIT
    SFMODE_IMPLIED
    JSR TIME_DELAY_1MS
.ENDPROC
.EXPORT LCD_INIT

; _LCD_UPDATE_CURSOR
; Modifies: A, X, flags
; 
; Sets the LCD panel's current DDRAM address to match the values stored
; for the cursor in LCD_CURSOR_X and LCD_CURSOR_Y.
.PROC _LCD_UPDATE_CURSOR
    JSR _LCD_WAIT
    JSR _LCD_START_INSTR_WR

    SFMODE_SYSCTX_ALTFN_ON
        LDX _LCD_CURSOR_Y
        LDA _LCD_DDRAM_OFFSETS, X
        ADC _LCD_CURSOR_X

        ORA #%10000000
        JSR LCD_PUTC::NO_WAIT
    SFMODE_IMPLIED

    RTS
.ENDPROC