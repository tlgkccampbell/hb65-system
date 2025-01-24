.IFNDEF _BIOS_RTC_
_BIOS_RTC_ = 1

; RTC_REGISTERS enum
; The set of registers provided by the real-time clock (RTC). Registers between
; RAMSTART and RAMEND are general-purpose battery-backed SRAM memory locations.
.ENUM RTC_REGISTERS
    SECONDS     = $00
    MINUTES     = $01
    HOURS       = $02
    DAY         = $03
    DATE        = $04
    MONTH       = $05
    YEAR        = $06
    CONTROL     = $07
    RAMSTART    = $08
    RAMEND      = $3F
.ENDENUM

; RTC_RAM_SIZE
; The number of bytes of battery-backed RAM available in the RTC.
RTC_RAM_SIZE = RTC_REGISTERS::RAMEND - RTC_REGISTERS::RAMSTART

.ENDIF