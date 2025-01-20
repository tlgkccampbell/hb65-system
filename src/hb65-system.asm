; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     GPIO_INIT, GPIO_SET_LEDS, GPIO_BUZZER_BEEP
.IMPORT     LCD_INIT, LCD_CLEAR, LCD_PUTC
.IMPORT     UART_INIT
.IMPORT     PROC_INIT, PROC_NEW, PROC_YIELD
.IMPORT     EHBASIC_INIT
.IMPORT     STRM_PUTNL, STRM_PUTSTR, STRM_PUTSTR_IMM, STRM_PUTHEX, STRM_PUTHEX16
.IMPORT     JMP_SRA

.INCLUDE    "hb65-system.inc"

; Interrupt handlers
.SEGMENT "BIOS"

; LUT_BRK_MSG
; A lookup table containing the error messages for different break conditions.
LUT_BRK_MSG:
    .WORD BRK_MSG_GENERAL_ERROR
LUT_BRK_MSG_END:

        ; "--------------------" 
BRK_MSG_UNKNOWN:
    .BYTE "Unknown error", $00
BRK_MSG_GENERAL_ERROR:
    .BYTE "General system error", $00
BRK_MSG_COUNT = (LUT_BRK_MSG_END - LUT_BRK_MSG) / 2

; NMI_HANDLER procedure
; Modifies: n/a
;
; Handles non-maskable interrupts.
.PROC NMI_HANDLER
    RTI
.ENDPROC

; BRK_HANDLER procedure
; Modifies: n/a
;
; Handles software interrupts. Halts the processor.
.PROC BRK_HANDLER
    ; Move the return address into a scratch register.
    LDA $010A, X
    STA DECODER_SRCL
    LDA $010B, X
    STA DECODER_SRCH

    ; Decrement the return address.
    LDA DECODER_SRCL
    BNE :+
    DEC DECODER_SRCH
  : DEC DECODER_SRCL

    ; Read the padding byte into Scratch Register 6.
    LDA (DECODER_SRC)
    STA DECODER_SR6
    JSR GPIO_SET_LEDS

    ; Decrement the return address again.
    LDA DECODER_SRCL
    BNE :+
    DEC DECODER_SRCH
  : DEC DECODER_SRCL

    ; Set up our output stream.
    JSR LCD_CLEAR
 STADDR LCD_PUTC, DECODER_SRA

    ; Retrieve the padding byte, set the front panel
    ; LEDs to that value, and output an error message
    ; to the LCD panel.
    JSR STRM_PUTSTR_IMM
    .BYTE "Break $", $00
    LDA DECODER_SR6
    JSR STRM_PUTHEX
    JSR STRM_PUTSTR_IMM
    .BYTE " at $", $00
    JSR STRM_PUTHEX16
    JSR STRM_PUTNL

    ; Output the error message.
    LDA DECODER_SR6
    CMP #BRK_MSG_COUNT
    BCC LOAD_BRK_MESSAGE
    LDA #<BRK_MSG_UNKNOWN
    STA DECODER_SRBL
    LDA #>BRK_MSG_UNKNOWN
    STA DECODER_SRBH
    JMP PUTS_BRK_MESSAGE
LOAD_BRK_MESSAGE:
    LDX DECODER_SR6
    LDA LUT_BRK_MSG, X
    STA DECODER_SRBL
    INX
    LDA LUT_BRK_MSG, X
    STA DECODER_SRBH
    JMP PUTS_BRK_MESSAGE
PUTS_BRK_MESSAGE:
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

; IRQ_HANDLER procedure
; Modifies: n/a
;
; Handles interrupt requests.
.PROC IRQ_HANDLER
    ; Preserve registers.
    PHY
    PHX
    PHA
    TSX
    PHX
    LDA DECODER_WBR
    PHA
    LDA DECODER_RLR
    PHA
    LDA DECODER_MLR
    PHA
    LDA DECODER_DCR
    PHA

    ; Is this a BRK interrupt?
    TSX
    LDA $0109, X
    AND #%00010000
    BEQ IRQ
    JMP BRK_HANDLER

IRQ:
    ; TODO: IRQ handling.

    ; Restore registers and return.
    PLA
    PLX
    PLY
    RTI
.ENDPROC

; RES_HANDLER procedure
; Modifies: n/a
;
; Handles system reset.
.PROC RES_HANDLER
    ; Initialize processor.
    CLD
    CLI
    LDX #$FF
    TXS
    ; Initialize the Address Decoder.
    LDA #$00
    STA DECODER_DCR
    LDA #$00
    STA DECODER_MLR
    LDA #$FF
    STA DECODER_RLR
    LDA #$00
    STA DECODER_WBR
    LDA #$FF
    STA DECODER_SPR
    ; Initialize peripherals.
    JSR GPIO_INIT
    JSR LCD_INIT
    JSR UART_INIT
    ; Initialize process management.
    JSR PROC_INIT
    ; Initialize the system process.
 STADDR :+, DECODER_SR0
    JSR PROC_NEW
    JSR GPIO_BUZZER_BEEP
    ; Initialize the EhBASIC process.
 STADDR EHBASIC_INIT, DECODER_SR0
    JSR PROC_NEW
:   JSR PROC_YIELD
    JMP :-
.ENDPROC

; CPU vector table
.SEGMENT "VECTORS"

.WORD NMI_HANDLER
.WORD RES_HANDLER
.WORD IRQ_HANDLER

; Shared memory
.SEGMENT "SHAREDMEM"