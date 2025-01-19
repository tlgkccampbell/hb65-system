; hb65-bios-uart.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS UART routines"

.INCLUDE    "../hb65-system.inc"

; UART routines
.SEGMENT "BIOS"

; UART_INIT procedure
; Modifies: flags, A
;
; Initializes the system's UARTs, if it has any.
.PROC UART_INIT
    .IFDEF ACIA_REGISTERS
        LDA     #$1E                ; 8-N-1, 9600 baud.
        STA     ACIA_CTRL
        LDA     #$0B                ; No parity, no echo, no interrupts.
        STA     ACIA_CMD
    .ENDIF
    RTS
.ENDPROC
.EXPORT UART_INIT

; UART_GETCH procedure
; Modifies: flags, A
;
; Attempts to read the next character from the system's first
; UART. If a character was read, the carry bit is set. Otherwise,
; the carry bit is cleared.
.PROC UART_GETCH
    .IFDEF ACIA_REGISTERS
        LDA     ACIA_STATUS
        AND     #$08
        BEQ     NOKEY
        LDA     ACIA_DATA
        SEC
        RTS
    .ENDIF
NOKEY:
    CLC
    RTS
.ENDPROC
.EXPORT UART_GETCH

; UART_PUTCH
; Modifies: flags
;
; Writes the value in A to the system's first UART.
.PROC UART_PUTCH
    PHA
    .IFDEF ACIA_REGISTERS
    LOOP:
        LDA     ACIA_STATUS
        AND     #$10
        BEQ     LOOP
        PLA
        STA ACIA_DATA
    .ENDIF
    RTS
.ENDPROC
.EXPORT UART_PUTCH