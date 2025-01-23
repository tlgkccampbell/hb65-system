.IFNDEF _INCLUDE_BIOS_LCD_
_INCLUDE_BIOS_LCD_=1

; The number of visible columns in the LCD panel.
LCD_COLS    = 20

; The number of visible rows in the LCD panel.
LCD_ROWS    = 4

; _LCD_CONTROL_PINS enum
; Describes the pins of VIA1 PORTB that are used to control the LCD panel.
.ENUM _LCD_CONTROL_PINS
    EN = 7
    RW = 6
    RS = 5
    BL = 4
.ENDENUM

.ENDIF