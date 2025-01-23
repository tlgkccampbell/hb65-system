; hb65-bios-lcd.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS LCD routines"

.INCLUDE    "../hb65-system.inc"
.INCLUDE    "hb65-bios-lcd.inc"

.IMPORT     TIME_DELAY_50US, TIME_DELAY_1MS, TIME_DELAY_50MS

; LCD state
.SEGMENT "SYSZP": zeropage

_LCD_DATA_BUFFER:   .RES 1
_LCD_CURSOR_X:      .RES 1
_LCD_CURSOR_Y:      .RES 1 

; LCD routines
.SEGMENT "BIOS"

; _LCD_DDRAM_OFFSETS
; A lookup table mapping LCD rows to DDRAM offsets.
_LCD_DDRAM_OFFSETS:
  .BYTE $00
  .BYTE $40
  .BYTE $14
  .BYTE $54

; LCD_PROC_START macro
; Modifies: n/a
;
; Declares the start of an LCD API procedure. This macro creates two versions of the procedure:
; a public version called `name` and a private version called `_name`. Only the former is exported.
; The public procedure wraps the private procedure in code that enables System Context Mode and
; Alternative Function mode.
; Must be paired with a call to LCD_PROC_END.
.MACRO LCD_PROC_START name
.PROC name
    SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX) | (1 << DECODER_DCR_BIT::ALTFN)
        JSR .IDENT(.CONCAT("_", .STRING(name)))
    SFMODE_POP
    RTS
.ENDPROC
.EXPORT name
.PROC .IDENT(.CONCAT("_", .STRING(name)))
.ENDMAC

; LCD_PROC_END macro
; Modifies: n/a
;
; Declares the end of an LCD API procedure.
.MACRO LCD_PROC_END
.ENDPROC
.ENDMAC

; LCD_INIT procedure
; Modifies: n/a
;
; Initializes the front panel LCD.
LCD_PROC_START LCD_INIT
    PHA

    ; Initialize the character LCD.
    JSR _LCD_DISABLE_LIGHT
    STZ _LCD_CURSOR_X
    STZ _LCD_CURSOR_Y
    JSR _LCD_START_INSTR_WR

    ; Function set (8-bit mode, 1st try)
    LDA #%0011
    JSR _LCD_TOGGLE_ENABLE
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS
    JSR TIME_DELAY_1MS

    ; Function set (8-bit mode, 2nd try)
    LDA #%0011
    JSR _LCD_TOGGLE_ENABLE
    JSR TIME_DELAY_50US

    ; Function set (8-bit mode, 3rd try)
    LDA #%0011
    JSR _LCD_TOGGLE_ENABLE
    JSR TIME_DELAY_50US

    ; Function set (4-bit mode)
    LDA #%0010
    JSR _LCD_TOGGLE_ENABLE
    JSR TIME_DELAY_50US

    ; Function set (4 lines, 5x8 font)
    LDA #%00101000
    JSR _LCD_WRITE_BYTE
    JSR TIME_DELAY_1MS

    ; Display on, cursor on, blinking on
    LDA #%00001111
    JSR _LCD_WRITE_BYTE
    JSR TIME_DELAY_1MS

    ; Clear display
    LDA #%00000001
    JSR _LCD_WRITE_BYTE
    JSR TIME_DELAY_1MS

    ; Entry mode set
    LDA #%00000110
    JSR _LCD_WRITE_BYTE
    JSR TIME_DELAY_1MS

    PLA
    RTS    
LCD_PROC_END

; LCD_WAIT procedure
; Modifies: n/a
;
; Waits for the LCD panel to become ready.
LCD_PROC_START LCD_WAIT
    PHA

    ; Preserve the current state of the LCD port.
    LDA SYSTEM_VIA_DDRB
    PHA
    LDA SYSTEM_VIA_ORB
    PHA

    ; Read until bit 7 is clear.
    JSR _LCD_START_INSTR_RD
  : JSR _LCD_READ_BYTE
    AND #%10000000
    BMI :-

    ; Restore the LCD port's state.
    PLA
    STA SYSTEM_VIA_ORB
    PLA
    STA SYSTEM_VIA_DDRB

    PLA
    RTS
LCD_PROC_END

; LCD_CLEAR procedure
; Modifies: n/a
;
; Clears the LCD panel.
LCD_PROC_START LCD_CLEAR
    PHA
    JSR _LCD_WAIT
    JSR _LCD_START_INSTR_WR
    LDA #%00000001
    JSR _LCD_WRITE_BYTE
    STZ _LCD_CURSOR_X
    STZ _LCD_CURSOR_Y
    JSR _LCD_UPDATE_CURSOR
    PLA
    RTS
LCD_PROC_END

; LCD_UPDATE_CURSOR
; Modifies: n/a
; 
; Sets the LCD panel's current DDRAM address to match the values stored
; for the cursor in _LCD_CURSOR_X and _LCD_CURSOR_Y.
LCD_PROC_START LCD_UPDATE_CURSOR
    PHA
    PHX

    JSR _LCD_WAIT
    JSR _LCD_START_INSTR_WR
    LDX _LCD_CURSOR_Y
    LDA _LCD_DDRAM_OFFSETS, X
    ADC _LCD_CURSOR_X
    ORA #%10000000
    JSR _LCD_WRITE_BYTE

    PLX
    PLA
    RTS
LCD_PROC_END

; LCD_TOGGLE_ENABLE
; Modifies: n/a
;
; Toggles the LCD's enable line by pulling it high, then low.
LCD_PROC_START LCD_TOGGLE_ENABLE
    PHA

    ; Store the bottom nibble of A in the data buffer.
    AND #$0F
    STA _LCD_DATA_BUFFER

    ; Load the top nibble of VIA1 ORB into A, then OR it
    ; with the bottom nibble we stored in the data buffer.
    LDA SYSTEM_VIA_ORB
    AND #$F0
    ORA _LCD_DATA_BUFFER

    ; Pull the enable pin high, then low.
    ORA #(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB
    AND #<~(1 << _LCD_CONTROL_PINS::EN)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
LCD_PROC_END

; LCD_READ_NIBBLE procedure
; Modifies: A
;
; Reads a nibble from the LCD and places it into the A register.
LCD_PROC_START LCD_READ_NIBBLE
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
LCD_PROC_END

; LCD_READ_BYTE procedure
; Modifies: A
;
; Reads a byte from the LCD panel and places it into the A register.
LCD_PROC_START LCD_READ_BYTE
    ; Read the high nibble.
    JSR _LCD_READ_NIBBLE
    ASL
    ASL
    ASL
    ASL
    STA _LCD_DATA_BUFFER

    ; Read the low nibble.
    JSR _LCD_READ_NIBBLE
    ORA _LCD_DATA_BUFFER
    RTS
LCD_PROC_END

; LCD_WRITE_BYTE procedure
; Modifies: n/a
;
; Writes a byte from the A register to the LCD panel.
LCD_PROC_START LCD_WRITE_BYTE
    ; Present the high nibble.
    PHA
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
    PLA
    RTS
LCD_PROC_END

; LCD_START_DATA_RD
; Modifies: n/a
;
; Prepares VIA1 to read data from the LCD panel.
LCD_PROC_START LCD_START_DATA_RD
    PHA

    ; Set lower nibble of VIA1 PORTB to inputs.
    LDA #$F0
    STA SYSTEM_VIA_DDRB

    ; Pull RW high, RS high.
    LDA SYSTEM_VIA_ORB
    ORA #(1 << _LCD_CONTROL_PINS::RW)
    ORA #(1 << _LCD_CONTROL_PINS::RS)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
LCD_PROC_END

; LCD_START_DATA_WR
; Modifies: n/a
;
; Prepares VIA1 to write data to the LCD panel.
LCD_PROC_START LCD_START_DATA_WR
    PHA
        
    ; Set lower nibble of VIA1 PORTB to outputs.
    LDA #$FF
    STA SYSTEM_VIA_DDRB

    ; Pull RW low, RS high.
    LDA SYSTEM_VIA_ORB
    AND #<~(1 << _LCD_CONTROL_PINS::RW)
    ORA #(1 << _LCD_CONTROL_PINS::RS)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
LCD_PROC_END

; LCD_START_INSTR_RD
; Modifies: n/a
;
; Prepares VIA1 to read instruction data from the LCD panel.
LCD_PROC_START LCD_START_INSTR_RD
    PHA
  
    ; Set lower nibble of VIA1 PORTB to inputs.
    LDA #$F0
    STA SYSTEM_VIA_DDRB

    ; Pull RW high, RS low.
    LDA SYSTEM_VIA_ORB
    ORA #(1 << _LCD_CONTROL_PINS::RW)
    AND #<~(1 << _LCD_CONTROL_PINS::RS)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
LCD_PROC_END

; LCD_START_INSTR_WR
; Modifies: n/a
;
; Prepares VIA1 to write instructions to the LCD panel.
LCD_PROC_START LCD_START_INSTR_WR
    PHA

    ; Set lower nibble of VIA1 PORTB to outputs.
    LDA #$FF
    STA SYSTEM_VIA_DDRB

    ; Pull RW low, RS low.
    LDA SYSTEM_VIA_ORB
    AND #<~(1 << _LCD_CONTROL_PINS::RW)
    AND #<~(1 << _LCD_CONTROL_PINS::RS)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
LCD_PROC_END

; LCD_ENABLE_LIGHT
; Modifies: n/a
;
; Turns on the LCD's white backlight.
LCD_PROC_START LCD_ENABLE_LIGHT
    PHA

    LDA SYSTEM_VIA_ORB
    AND #<~(1 << _LCD_CONTROL_PINS::BL)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
LCD_PROC_END

; LCD_DISABLE_LIGHT
; Modifies: n/a
;
; Turns off the LCD's white backlight.
LCD_PROC_START LCD_DISABLE_LIGHT
    PHA

    LDA SYSTEM_VIA_ORB
    ORA #(1 << _LCD_CONTROL_PINS::BL)
    STA SYSTEM_VIA_ORB

    PLA
    RTS
LCD_PROC_END

; LCD_CHECK_NEWLINE procedure
; Modifies: n/a
; 
; Checks the contents of A to determine whether it represents a newline character.
; If so, advances the LCD cursor to the next line. On return, the carry flag indicates
; whether a newline was handled.
LCD_PROC_START LCD_CHECK_NEWLINE
    ; Is A equal to \n ($0A)? If not, clear carry and immediately return.
    CMP #$0A
    BEQ TRY_ADVANCE_LINE
    CLC
    RTS

    ; Advance to the next line.
  TRY_ADVANCE_LINE:
    PHA
    PHX

  ADVANCE:
    ; Make sure we haven't reached the last line of the display.
    ; If we have, immediately return.
    LDA _LCD_CURSOR_Y
    CMP #LCD_ROWS-1
    BEQ ADVANCE_DONE

    ; Advance to the next line and update the cursor position.
    STZ _LCD_CURSOR_X
    INC _LCD_CURSOR_Y
    JSR _LCD_UPDATE_CURSOR

  ADVANCE_DONE:
    PLX
    PLA
    SEC
    RTS
LCD_PROC_END

; LCD_CHECK_OVERFLOW procedure
; Modifies: n/a
;
; Check the LCD cursor position to determine if printing a character will
; overflow the current line. If so, advances the LCD cursor to the next line.
; On return, the carry flag is set if the display is full.
LCD_PROC_START LCD_CHECK_OVERFLOW
    PHA
    PHX

    ; Make sure we're at the last column of the display.
    ; If not, immediately return.
    LDA _LCD_CURSOR_X
    CMP #LCD_COLS
    BNE ADVANCE_DONE

    ; Make sure we haven't reached the last line of the display.
    ; If we have, set the carry flag and return.
    LDA _LCD_CURSOR_Y
    CMP #LCD_ROWS-1
    BNE ADVANCE_FAIL

    ; Move the cursor to the next line.
    STZ _LCD_CURSOR_X
    INC _LCD_CURSOR_Y
    JSR _LCD_UPDATE_CURSOR

  ADVANCE_DONE:
    PLX
    PLA
    CLC
    RTS

  ADVANCE_FAIL:
    PLX
    PLA
    SEC
    RTS
LCD_PROC_END

; LCD_PUTC procedure
; Modifies: n/a
;
; Writes the byte passed in the A register to the LCD panel.
LCD_PROC_START LCD_PUTC
    PHA

    ; Advance the cursor if necessary.
    JSR _LCD_CHECK_NEWLINE
    BCS DONE
    JSR _LCD_CHECK_OVERFLOW
    BCS DONE

    ; Wait for the LCD to become ready.
    PHA
    PHA
    JSR _LCD_WAIT
    JSR _LCD_START_DATA_WR
    INC _LCD_CURSOR_X

    ; Present the high nibble.
    PLA
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

  DONE:
    PLA
    RTS
LCD_PROC_END