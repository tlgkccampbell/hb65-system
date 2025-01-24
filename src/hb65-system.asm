; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     BRK_HANDLER
.IMPORT     DSTK_INIT
.IMPORT     GPIO_INIT, GPIO_BUZZER_BEEP
.IMPORT     LCD_INIT
.IMPORT     UART_INIT
.IMPORT     I2C_INIT
.IMPORT     RTC_READ_SEC, RTC_READ_REGISTER, STRM_PUTHEX, TIME_DELAY_50MS
.IMPORT     PROC_INIT, PROC_NEW, PROC_YIELD
.IMPORT     EHBASIC_INIT

.IMPORT     LCD_CLEAR, LCD_PUTC, STRM_PUTSTR_IMM

.INCLUDE    "hb65-system.inc"
.INCLUDE    "bios/hb65-bios-rtc.inc"

; Interrupt handlers
.SEGMENT "BIOS"

; NMI_HANDLER procedure
; Modifies: n/a
;
; Handles non-maskable interrupts.
.PROC NMI_HANDLER
    RTI
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
    ; Initialize system modules.
    JSR DSTK_INIT
    JSR GPIO_INIT
    JSR  LCD_INIT
    JSR UART_INIT
    JSR  I2C_INIT
    JSR PROC_INIT
    ; Initialize the system process.
 STADDR :+, DECODER_SRA
    JSR PROC_NEW
    JSR GPIO_BUZZER_BEEP
    ; Initialize the EhBASIC process.
 STADDR EHBASIC_INIT, DECODER_SRA
    JSR PROC_NEW
:   JSR PROC_YIELD
    JMP :-
.ENDPROC

; CPU vector table
.SEGMENT "VECTORS"

.WORD NMI_HANDLER
.WORD RES_HANDLER
.WORD IRQ_HANDLER