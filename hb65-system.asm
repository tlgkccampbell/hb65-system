; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     EHBASIC_INIT, EHBASIC_NMI_HANDLER, EHBASIC_IRQ_HANDLER, WOZ_ENTER
.IMPORT     PROC_INIT, PROC_NEW, PROC_YIELD, UART_INIT

.INCLUDE    "hb65-system.inc"

; Interrupt handlers
HandleNMI:
    ; TODO: This needs some kind of indirection based on the current WRAM bank
    JMP EHBASIC_NMI_HANDLER

HandleIRQ:
    ; TODO: This needs some kind of indirection based on the current WRAM bank
    JMP EHBASIC_IRQ_HANDLER

HandleRES:
    ; Initialize processor
    CLD
    CLI
    LDX #$FF
    TXS
    ; Initialize the Address Decoder
    LDA #$00
    STA DECODER_DCR
    LDA #$00
    STA DECODER_MLR
    LDA #$FF
    STA DECODER_RLR
    LDA #$00
    STA DECODER_WBR
    STZ DECODER_SCR
    STZ DECODER_AFR
    ; Initialize peripherals
    JSR UART_INIT
    ; Initialize process management
    JSR PROC_INIT
    ; Initialize the system process
 STADDR HandleSYS, DECODER_SR0
    JSR PROC_NEW
    ; Initialize the EhBASIC process
 STADDR EHBASIC_INIT, DECODER_SR0
    JSR PROC_NEW

HandleSYS:
    JSR PROC_YIELD
    JMP HandleSYS

; CPU vector table
.SEGMENT "VECTORS"
.WORD HandleNMI
.WORD HandleRES
.WORD HandleIRQ

; Shared memory
.SEGMENT "SHAREDMEM"