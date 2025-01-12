; hb65-bios.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Basic input/output system for the HB65 Microcomputer System"

.INCLUDE    "hb65-registers.inc"

.IMPORT     WOZ_ENTER, WOZ_EXIT

; BIOS jumptable
.SEGMENT "BIOSTBL"

BIOSTBL:
JMP WOZ_ENTER       ; $00
JMP WOZ_EXIT        ; $03

; BIOS routines
.SEGMENT "BIOS"

; System routines

; SYSTEM_INIT procedure
; Modifies: A, X, flags
;
; Initializes the system state upon reset.
.PROC SYSTEM_INIT
    LDA #$00
    STA DECODER_DCR
    LDA #$00
    STA DECODER_ALR
    LDA #$FF
    STA DECODER_ZPLR
    LDA #$00
    STA DECODER_WRBR
    RTS
.ENDPROC
.EXPORT SYSTEM_INIT

; UART routines

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
    .ELSE
        .WARNING "No UARTs are configured in this system."
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
    .ELSE
        .WARNING "No UARTs are configured in this system."
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
    .ELSE
        .WARNING "No UARTs are configured in this system."
    .ENDIF
    RTS
.ENDPROC
.EXPORT UART_PUTCH

; End UART routines