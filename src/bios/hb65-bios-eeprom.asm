; hb65-bios-eepronm.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS EEPROM routines"

.INCLUDE    "../hb65-system.inc"

.IMPORT     I2C_START, I2C_STOP, I2C_ACK, I2C_NAK, I2C_CLR, I2C_READ_BYTE, I2C_SEND_BYTE

; EEPROM routines
.SEGMENT "BIOS"

; EEPROM_SEND_ADDRESS procedure
; Modifies: A
;
; Writes the data in A to the adderss specified in
; X (low) and Y (high).
.PROC EEPROM_SEND_ADDRESS
    PHA
    PHX
    PHY
    JSR I2C_START       ; Start transaction
    LDA #%10101100
    JSR I2C_SEND_BYTE   ; Address the device
    BMI DONE
    PLA
    JSR I2C_SEND_BYTE   ; Send address (high)
    BMI DONE
    PLA
    JSR I2C_SEND_BYTE   ; Send address (low)
    BMI DONE
    PLA
    JSR I2C_SEND_BYTE   ; Send value
    BMI DONE
    JSR I2C_STOP        ; Finish transaction
  DONE:
    RTS
.ENDPROC
.EXPORT EEPROM_SEND_ADDRESS

; EEPROM_READ_ADDRESS procedure
; Modifies: X
;
; Reads the data at the address specified in X (low)
; and Y (high) into X.
.PROC EEPROM_READ_ADDRESS
    PHX
    PHY
    JSR I2C_START       ; Start transaction
    LDA #%10101100
    JSR I2C_SEND_BYTE   ; Address the device
    BMI DONE
    PLA
    JSR I2C_SEND_BYTE   ; Send address (high)
    BMI DONE
    PLA
    JSR I2C_SEND_BYTE   ; Send address (low)
    BMI DONE
    JSR I2C_START       ; Restart transaction
    LDA #%10101101
    JSR I2C_SEND_BYTE   ; Address the device
    BMI DONE
    JSR I2C_READ_BYTE   ; Read the memory address
    JSR I2C_STOP        ; Finish transaction
DONE:
    RTS
.ENDPROC
.EXPORT EEPROM_READ_ADDRESS