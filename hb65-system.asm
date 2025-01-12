; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     EHBASIC_INIT, EHBASIC_NMI_HANDLER, EHBASIC_IRQ_HANDLER
.IMPORT     SYSTEM_INIT, UART_INIT

.INCLUDE    "hb65-registers.inc"

; Interrupt handlers
HandleNMI:
    JMP     EHBASIC_NMI_HANDLER

HandleIRQ:
    JMP     EHBASIC_IRQ_HANDLER

HandleRES:
    CLD
    CLI
    LDX #$FF
    TXS
    JSR      SYSTEM_INIT
    JSR        UART_INIT
    JMP     EHBASIC_INIT

; CPU vector table
.SEGMENT "VECTORS"
.WORD HandleNMI
.WORD HandleRES
.WORD HandleIRQ