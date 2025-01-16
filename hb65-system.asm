; hb65-system.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "System ROM for the HB65 Microcomputer System"

.IMPORT     GPIO_INIT, GPIO_SET_LEDS, UART_INIT
.IMPORT     PROC_INIT, PROC_NEW, PROC_YIELD
.IMPORT     EHBASIC_INIT

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
    LDA $0104, X
    STA DECODER_SR0L
    LDA $0105, X
    STA DECODER_SR0H

    ; Decrement the return address.
    LDA DECODER_SR0L
    BNE :+
    DEC DECODER_SR0H
 :  DEC DECODER_SR0L

    ; Retrieve the padding byte, set the front panel
    ; LEDs to that value, and halt the processor.
    LDA (DECODER_SR0)
    JSR GPIO_SET_LEDS
    STP
.ENDPROC

; IRQ_HANDLER procedure
; Modifies: n/a
;
; Handles interrupt requests.
.PROC IRQ_HANDLER
    ; Preserve registers.
    PHA
    PHX

    ; Is this a BRK interrupt?
    TSX
    LDA $0103, X
    AND #%00010000
    BNE BRK_HANDLER

    ; TODO: IRQ handling.

    ; Restore registers and return.
    PLX
    PLA
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
    STZ DECODER_SCR
    STZ DECODER_AFR
    ; Initialize peripherals.
    JSR GPIO_INIT
    JSR UART_INIT
    ; Initialize process management.
    JSR PROC_INIT
    ; Initialize the system process.
 STADDR :+, DECODER_SR0
    JSR PROC_NEW
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