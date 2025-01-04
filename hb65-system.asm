; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     EHBASIC_INIT, EHBASIC_NMI_HANDLER, EHBASIC_IRQ_HANDLER
.IMPORT     UART_INIT

; Interrupt handlers
HandleNMI:
    JMP     EHBASIC_NMI_HANDLER

HandleIRQ:
    JMP     EHBASIC_IRQ_HANDLER

HandleRES:
    JSR        UART_INIT
    JMP     EHBASIC_INIT

; CPU vector table
.SEGMENT "VECTORS"
.WORD HandleNMI
.WORD HandleRES
.WORD HandleIRQ