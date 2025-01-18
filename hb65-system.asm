; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     GPIO_INIT, GPIO_SET_LEDS, GPIO_BUZZER_BEEP, GPIO_LCD_CLR, GPIO_LCD_PUTC, GPIO_LCD_SET_DDRAM_ADDR
.IMPORT     UART_INIT
.IMPORT     PROC_INIT, PROC_NEW, PROC_YIELD
.IMPORT     EHBASIC_INIT
.IMPORT     GPIO_LCD_PUTSTR_IMM, GPIO_LCD_PUTHEX, GPIO_LCD_PUTHEX16

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
    STA DECODER_SRAL
    LDA $0106, X
    STA DECODER_SRAH

    ; Decrement the return address.
    LDA DECODER_SRAL
    BNE :+
    DEC DECODER_SRAH
  : DEC DECODER_SRAL

    ; Read the padding byte into A.
    LDA (DECODER_SRA)
    PHA
    JSR GPIO_SET_LEDS

    ; Decrement the return address again.
    LDA DECODER_SRAL
    BNE :+
    DEC DECODER_SRAH
  : DEC DECODER_SRAL
  
    ; Retrieve the padding byte, set the front panel
    ; LEDs to that value, and output an error message
    ; to the LCD panel.
    JSR GPIO_LCD_CLR
    JSR GPIO_LCD_PUTSTR_IMM
    .BYTE "Break $", 0
    PLA
    JSR GPIO_LCD_PUTHEX
    JSR GPIO_LCD_PUTSTR_IMM
    .BYTE " at $", 0
    JSR GPIO_LCD_PUTHEX16

    LDA #$40
    JSR GPIO_LCD_SET_DDRAM_ADDR
    JSR GPIO_LCD_PUTSTR_IMM
    .BYTE "A: $", 0
    PLA
    JSR GPIO_LCD_PUTHEX

    LDA #$14
    JSR GPIO_LCD_SET_DDRAM_ADDR
    JSR GPIO_LCD_PUTSTR_IMM
    .BYTE "X: $", 0
    PLX
    TXA
    JSR GPIO_LCD_PUTHEX

    LDA #$54
    JSR GPIO_LCD_SET_DDRAM_ADDR
    JSR GPIO_LCD_PUTSTR_IMM
    .BYTE "Y: $", 0
    PLY
    TYA
    JSR GPIO_LCD_PUTHEX

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