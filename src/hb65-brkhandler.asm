; hb65-brkhandler.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BRK handler for the HB65 Microcomputer System"

.INCLUDE    "hb65-system.inc"
.INCLUDE    "bios/hb65-bios-lcd.inc"

.IMPORT     GPIO_SET_LEDS, GPIO_BUZZER_BEEP
.IMPORT     LCD_CLEAR, LCD_PUTC
.IMPORT     STRM_PUTNL, STRM_PUTSTR, STRM_PUTSTR_IMM, STRM_PUTHEX, STRM_PUTHEX16

; Break handler
.SEGMENT "BIOS"

; LUT_BRK_MSG
; A lookup table containing pointers to the error messages for
; different break conditions.
LUT_BRK_MSG:
    .WORD BRK_MSG_GENERAL_ERROR
LUT_BRK_MSG_END:

; BRK_MSG macro
; Writes a BRK error message to the ROM, checking to ensure that
; its length does not exceed the size of the LCD display.
.MACRO BRK_MSG msg
    .ASSERT .STRLEN(msg) <= LCD_COLS, error, "BRK message too long"
    .BYTE msg, $00
.ENDMAC

; BRK messages
BRK_MSG_UNKNOWN:
    BRK_MSG "Unknown error"
BRK_MSG_GENERAL_ERROR:
    BRK_MSG "General system error"
BRK_MSG_COUNT = (LUT_BRK_MSG_END - LUT_BRK_MSG) / 2

; BRK_HANDLER procedure
; Modifies: n/a
;
; Handles software interrupts. Halts the processor.
.PROC BRK_HANDLER
  ; Move the return address into a scratch register.
    LDA $010A, X
    STA DECODER_SRBL
    LDA $010B, X
    STA DECODER_SRBH
    BNE :+
    DEC DECODER_SRBH
  : DEC DECODER_SRBL

    ; Read the padding byte into Y.
    LDA (DECODER_SRB)
    TAY
    JSR GPIO_SET_LEDS

    ; Decrement the return address again.
    LDA DECODER_SRBL
    BNE :+
    DEC DECODER_SRBH
  : DEC DECODER_SRBL

    ; Set up our output stream.
    JSR LCD_CLEAR
 STADDR LCD_PUTC, DECODER_SRA

    ; Retrieve the padding byte, set the front panel
    ; LEDs to that value, and output an error message
    ; to the LCD panel.
    JSR STRM_PUTSTR_IMM
    .BYTE "BRK $", $00
    TYA
    JSR STRM_PUTHEX
    JSR STRM_PUTSTR_IMM
    .BYTE " at $", $00
    LDA DECODER_WBR
    JSR STRM_PUTHEX    
    JSR STRM_PUTSTR_IMM    
    .BYTE "-$", $00
    JSR STRM_PUTHEX16
    JSR STRM_PUTNL
    
    ; Output the error message.
    TYA
    CMP #BRK_MSG_COUNT
    BCC BRK_MSG_EXISTS
 STADDR BRK_MSG_UNKNOWN, DECODER_SRB
    JMP BRK_MSG_PUTS
BRK_MSG_EXISTS:
    TAX
    LDA LUT_BRK_MSG, X
    STA DECODER_SRBL
    INX
    LDA LUT_BRK_MSG, X
    STA DECODER_SRBH
BRK_MSG_PUTS:
    JSR STRM_PUTSTR
    JSR STRM_PUTNL

    ; Output the Decoder Control Register.
    JSR STRM_PUTSTR_IMM
    .BYTE "D: $", $00
    PLA
    JSR STRM_PUTHEX

    ; Output the Memory Layout Register.
    JSR STRM_PUTSTR_IMM
    .BYTE " $", $00
    PLA
    JSR STRM_PUTHEX

    ; Output the Register Layout Register.
    JSR STRM_PUTSTR_IMM
    .BYTE " $", $00
    PLA
    JSR STRM_PUTHEX

    ; Output the WRAM Banking Register.
    JSR STRM_PUTSTR_IMM
    .BYTE " $", $00
    PLA
    JSR STRM_PUTHEX
    JSR STRM_PUTNL

    ; Output the STK register.
    JSR STRM_PUTSTR_IMM
    .BYTE "C: $", $00
    PLA
    JSR STRM_PUTHEX

    ; Output the A register.
    JSR STRM_PUTSTR_IMM
    .BYTE " $", $00
    PLA
    JSR STRM_PUTHEX

    ; Output the X register.
    JSR STRM_PUTSTR_IMM
    .BYTE " $", $00
    PLA
    JSR STRM_PUTHEX

    ; Output the Y register.
    JSR STRM_PUTSTR_IMM
    .BYTE " $", $00
    PLA
    JSR STRM_PUTHEX
    JSR STRM_PUTNL

    ; Halt the processor.
    JSR GPIO_BUZZER_BEEP
    STP
.ENDPROC
.EXPORT BRK_HANDLER