; hb65-bios-rtc.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS RTC routines"

.INCLUDE    "../hb65-system.inc"
.INCLUDE    "hb65-bios-rtc.inc"

.IMPORT     I2C_START, I2C_STOP, I2C_ACK, I2C_NAK, I2C_CLR, I2C_READ_BYTE, I2C_SEND_BYTE

; RTC routines
.SEGMENT "BIOS"

; RTC_SEND_REGISTER procedure
; Modifies: A, X
;
; Writes a new value to an RTC register. The address of the register is
; passed in A, and the value to write is passed in X.
.PROC RTC_SEND_REGISTER
    PHX
    PHA
    JSR I2C_START
    LDA #%11010000
    JSR I2C_SEND_BYTE   ; Address the device
    BMI DONE    
    PLA
    JSR I2C_SEND_BYTE   ; Write the register address
    BMI DONE
    PLA
    JSR I2C_SEND_BYTE   ; Write register value
    BMI DONE
    JSR I2C_STOP
  DONE:
    RTS
.ENDPROC
.EXPORT RTC_SEND_REGISTER

; RTC_READ_REGISTER procedure
; Modifies: A, X
;
; Reads a value from an RTC register. The address of the register is
; passed in A, and the value of the register is returned in X.
.PROC RTC_READ_REGISTER
    PHA
    JSR I2C_START       ; Start transaction
    LDA #%11010000
    JSR I2C_SEND_BYTE   ; Address the device
    BMI DONE
    PLA
    JSR I2C_SEND_BYTE   ; Write the register address
    BMI DONE
    JSR I2C_START       ; Restart transaction
    LDA #%11010001
    JSR I2C_SEND_BYTE   ; Address the device
    BMI DONE
    JSR I2C_READ_BYTE   ; Read the register value
    JSR I2C_STOP        ; Finish transaction
  DONE:
    RTS
.ENDPROC
.EXPORT RTC_READ_REGISTER