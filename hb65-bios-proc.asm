; hb65-bios-proc.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS process management routines"

.IMPORT     SYSCDAT_JMP_ADDR, SYSCDAT_RET_ADDR

.INCLUDE    "hb65-system.inc"

; TODO: Merge SWITCH into YIELD
; TODO: How are we going to handle interrupts? (specifically, NMI)?
;   do we include IRQEN and NMIEN in the system context? maybe!

; Process metadata table
PROC_MAX_COUNT          := $00
PROC_CURRENT_IX         := $01
PROC_METADATA_STATUS    := $0300
PROC_METADATA_DCR       := $0310
PROC_METADATA_MLR       := $0320
PROC_METADATA_RLR       := $0330
PROC_METADATA_STK       := $0340
PROC_METADATA_PC        := $0350

.ENUM PROC_STATUS_BIT
    VALID = 7 
.ENDENUM

; Process management routines
.SEGMENT "BIOS"

; PROC_INIT procedure
; Modifies: A, X, flags
;
; Initializes the process metadata table.
.PROC PROC_INIT
    ; Switch to the system context
    LDA #$01
    STA DECODER_SCR
    
    ; Check whether we have 128K or 512K of WRAM, which changes
    ; how many processes we can run simultaneously.
PROC_INIT_RAM_CHECK:
    LDA DECODER_DCR
    AND #(1 << DECODER_DCR_BIT::WRAM512K)
    BEQ PROC_INIT_128K
    LDA #$10
    JMP PROC_INIT_TBL
PROC_INIT_128K:
    LDA #$04

    ; Initialize the process metadata table by setting the
    ; maximum process count and then clearing the status flags
    ; for all processes.
PROC_INIT_TBL:
    STA PROC_MAX_COUNT
    STZ PROC_CURRENT_IX
    TAX
:   DEX
    STZ PROC_METADATA_STATUS, X
    BNE :-

    ; Exit system context and return
    STZ DECODER_SCR
    RTS
.ENDPROC
.EXPORT PROC_INIT

; PROC_NEW procedure
; Modifies: A, X, flags
;
; Attempts to allocate a new process. If successful, the accumulator contains the
; process index on return. Otherwise, the accumulator contains FF to indicate
; that there is insufficient memory for new processes.
;
; The initial program counter for the new process should be stored in SR0.
.PROC PROC_NEW
    ; Switch to the system context.
    LDA #$01
    STA DECODER_SCR

    ; Find an unused process slot in the metadata table.
PROC_NEW_FIND_UNUSED:
    LDX #$00
:   BIT PROC_METADATA_STATUS, X
    BPL PROC_NEW_ALLOC
    INX
    CPX PROC_MAX_COUNT
    BNE :-

    ; Failed to find an open slot, so exit with $FF in A.
    LDA #$FF
    JMP PROC_NEW_DONE

    ; Found an open slot, set its valid bit, and store its
    ; initial program counter and register values in the metadata table.
    ; Return the new process index in the A register.
PROC_NEW_ALLOC:
    LDA #(1 << PROC_STATUS_BIT::VALID)
    STA PROC_METADATA_STATUS, X
    STZ PROC_METADATA_DCR, X
    STZ PROC_METADATA_MLR, X
    STZ PROC_METADATA_RLR, X
    LDA #$FF
    STA PROC_METADATA_STK, X
    TXA
    PHA
    ASL
    TAX
    LDA DECODER_SR0L
    STA PROC_METADATA_PC, X
    LDA DECODER_SR0H
    INX
    STA PROC_METADATA_PC, X
    PLA

PROC_NEW_DONE:
    STZ DECODER_SCR
    RTS
.ENDPROC
.EXPORT PROC_NEW

; PROC_YIELD procedure
; Modifies: A, X, Y, flags
;
; Yields execution to the process scheduler, allowing another idle process
; to resume execution.
.PROC PROC_YIELD
    ; Pull the return address off the process stack.
    PLX
    PLY

    ; Switch to the system context.
    LDA #$01
    STA DECODER_SCR

    ; Store the return address in SR0.
    STX DECODER_SR0L
    STY DECODER_SR0H
    INC DECODER_SR0L
    BNE :+
    INC DECODER_SR0H
:

    ; Update the process' stack pointer in the metadata table.
    TSX
    TXA
    LDX PROC_CURRENT_IX
    STA PROC_METADATA_STK, X

    ; Save the Address Decoder registers.
    LDA DECODER_DCR
    STA PROC_METADATA_DCR, X
    LDA DECODER_MLR
    STA PROC_METADATA_MLR, X
    LDA DECODER_RLR
    STA PROC_METADATA_RLR, X

    ; Save the return address.
    TXA
    ASL
    TAX
    LDA DECODER_SR0L    
    STA PROC_METADATA_PC, X
    LDA DECODER_SR0H
    INX
    STA PROC_METADATA_PC, X 

    ; Find the next valid process and switch to it.
PROC_YIELD_FIND_PROC:
    LDX PROC_CURRENT_IX
:   INX
    CPX PROC_MAX_COUNT
    BNE :+
    LDX #$00
:   BIT PROC_METADATA_STATUS, X
    BPL :--

    ; Restore the Address Decoder registers.
PROC_SWITCH:
    LDA PROC_METADATA_DCR, X
    STA DECODER_DCR
    LDA PROC_METADATA_MLR, X
    STA DECODER_MLR
    LDA PROC_METADATA_RLR, X
    STA DECODER_RLR

    ; Get the process' stack pointer from the metadata table and
    ; store it in the Y register.
    LDA PROC_METADATA_STK, X
    TAY

    ; Get the process' program counter from the metadata table and
    ; store it in SR0.
    PHX
    TXA
    ASL
    TAX
    LDA PROC_METADATA_PC, X
    STA DECODER_SR0L
    INX
    LDA PROC_METADATA_PC, X
    STA DECODER_SR0H

    ; Update the current process index
    PLX
    STX PROC_CURRENT_IX

    ; Switch to the process' memory space, set its stack pointer,
    ; and exit the system context.
    STX DECODER_WBR
    TYA
    TAX
    TXS
    STZ DECODER_SCR

    ; Jump to the process' return address.
    JMP (DECODER_SR0)
.ENDPROC
.EXPORT PROC_YIELD

; PROC_TERM procedure
; Modifies: A, X, flags
;
; Terminates the current process and switches to another running process.
.PROC PROC_TERM
    ; Switch to the system context.
    LDA #$01
    STA DECODER_SCR

    ; Clear the current process' status bits
    LDX PROC_CURRENT_IX
    STZ PROC_METADATA_STATUS, X

    ; Switch to the system process.
    LDX #$00
    JMP PROC_YIELD::PROC_SWITCH
.ENDPROC
.EXPORT PROC_TERM
