.IFNDEF _INCLUDE_BIOS_LCD_
_INCLUDE_BIOS_LCD_=1

; _LCD_CONTROL_PINS enum
; Describes the pins of VIA1 PORTB that are used to control the LCD panel.
.ENUM _LCD_CONTROL_PINS
    EN = 7
    RW = 6
    RS = 5
    BL = 4
.ENDENUM

.ENDIF