; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     GPIO_INIT, GPIO_SET_LEDS, GPIO_BUZZER_BEEP, GPIO_LCD_CLR, GPIO_LCD_PUTC, GPIO_LCD_SET_DDRAM_ADDR
.IMPORT     UART_INIT
.IMPORT     PROC_INIT, PROC_NEW, PROC_YIELD
.IMPORT     EHBASIC_INIT
.IMPORT     STRM_PUTSTR_IMM, STRM_PUTHEX, STRM_PUTHEX16
.IMPORT     JMP_SRA

.INCLUDE    "hb65-system.inc"

; Interrupt handlers

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
    LDA $0105, X
    STA DECODER_SRCL
    LDA $0106, X
    STA DECODER_SRCH

    ; Decrement the return address.
    LDA DECODER_SRCL
    BNE :+
    DEC DECODER_SRCH
  : DEC DECODER_SRCL

    ; Read the padding byte into A.
    LDA (DECODER_SRC)
    PHA
    JSR GPIO_SET_LEDS

    ; Decrement the return address again.
    LDA DECODER_SRCL
    BNE :+
    DEC DECODER_SRCH
  : DEC DECODER_SRCL

    ; Set up our output stream.
    JSR GPIO_LCD_CLR
 STADDR GPIO_LCD_PUTC, DECODER_SRA

    ; Retrieve the padding byte, set the front panel
    ; LEDs to that value, and output an error message
    ; to the LCD panel.
    JSR STRM_PUTSTR_IMM
    .BYTE "Break $", 0
    PLA
    JSR STRM_PUTHEX
    JSR STRM_PUTSTR_IMM
    .BYTE " at $", 0
    JSR STRM_PUTHEX16

    LDA #$40
    JSR GPIO_LCD_SET_DDRAM_ADDR
    JSR STRM_PUTSTR_IMM
    .BYTE "A: $", 0
    PLA
    JSR STRM_PUTHEX

    LDA #$14
    JSR GPIO_LCD_SET_DDRAM_ADDR
    JSR STRM_PUTSTR_IMM
    .BYTE "X: $", 0
    PLX
    TXA
    JSR STRM_PUTHEX

    LDA #$54
    JSR GPIO_LCD_SET_DDRAM_ADDR
    JSR STRM_PUTSTR_IMM
    .BYTE "Y: $", 0
    PLY
    TYA
    JSR STRM_PUTHEX

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

    ; Is this a BRK interrupt?
    TSX
    LDA $0104, X
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
    LDA #$F0
    STA DECODER_SFR
    ; Initialize peripherals.
    JSR GPIO_INIT
    JSR UART_INIT
    ; Initialize process management.
    JSR PROC_INIT
    ; Initialize the system process.
 STADDR :+, DECODER_SR0
    JSR PROC_NEW
    JSR GPIO_BUZZER_BEEP
    LDA #$AA
    LDX #$BB
    LDY #$CC
    BRK
    .BYTE $AA
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