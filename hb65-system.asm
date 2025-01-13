; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     EHBASIC_INIT, EHBASIC_NMI_HANDLER, EHBASIC_IRQ_HANDLER
.IMPORT     PROC_INIT, PROC_NEW, PROC_SWITCH, UART_INIT
.IMPORT     SYSCDAT_JMP_ADDR

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
    STA DECODER_ALR
    LDA #$FF
    STA DECODER_ZPLR
    LDA #$00
    STA DECODER_WRBR
    ; Initialize the system process
    JSR PROC_INIT
    JSR PROC_NEW
 STADDR :+, SYSCDAT_JMP_ADDR
    JSR PROC_SWITCH
    ; Initialize peripherals
:   JSR UART_INIT
    ; Initialize the EhBASIC process
    JSR PROC_NEW
 STADDR :+, SYSCDAT_JMP_ADDR
    JSR PROC_SWITCH
:   JMP EHBASIC_INIT

; CPU vector table
.SEGMENT "VECTORS"
.WORD HandleNMI
.WORD HandleRES
.WORD HandleIRQ

; Shared memory
.SEGMENT "SHAREDMEM"