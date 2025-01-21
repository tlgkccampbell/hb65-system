; hb65-bios-proc.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS process management routines"

.INCLUDE    "../hb65-system.inc"

; Process metadata table
.SEGMENT "SYSZP"
PROC_MAX_COUNT:         .RES 1
PROC_CURRENT_IX:        .RES 1

.SEGMENT "SYSWRAM"
PROC_METADATA_STATUS:   .RES 16
PROC_METADATA_MLR:      .RES 16
PROC_METADATA_RLR:      .RES 16
PROC_METADATA_PC:       .RES 32

.ENUM PROC_STATUS_BIT
    VALID = 7 
.ENDENUM

; Process management routines
.SEGMENT "BIOS"

; PROC_INIT procedure
; Modifies: n/a
;
; Initializes the process metadata table.
.PROC PROC_INIT
    PHA
    PHX

    SFMODE_SYSCTX_ON
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
      : DEX
        STZ PROC_METADATA_STATUS, X
        BNE :-
    SFMODE_SYSCTX_OFF
    
    PLX
    PLA
    RTS
.ENDPROC
.EXPORT PROC_INIT

; PROC_NEW procedure
; Modifies: n/a
;
; Attempts to allocate a new process. If successful, the accumulator contains the
; process index on return. Otherwise, the accumulator contains FF to indicate
; that there is insufficient memory for new processes.
;
; The initial program counter for the new process should be stored in Scratch Register A.
.PROC PROC_NEW
    PHA
    PHX

    SFMODE_SYSCTX_ON
        ; Find an unused process slot in the metadata table.
      PROC_NEW_FIND_UNUSED:
        LDX #$00
      : BIT PROC_METADATA_STATUS, X
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
        STZ PROC_METADATA_MLR, X
        STZ PROC_METADATA_RLR, X
        TXA
        PHA
        ASL
        TAX
        LDA DECODER_SRAL
        STA PROC_METADATA_PC, X
        INX
        LDA DECODER_SRAH
        STA PROC_METADATA_PC, X
        PLA
PROC_NEW_DONE:
    SFMODE_SYSCTX_OFF

    PLX
    PLA
    RTS
.ENDPROC
.EXPORT PROC_NEW

; PROC_YIELD procedure
; Modifies: A, X, Y
;
; Yields execution to the process scheduler, allowing another idle process
; to resume execution.
.PROC PROC_YIELD
    ; Pull the return address off the process stack.
    PLA
    PLY

    ; Switch to the system context.
    SFMODE_SYSCTX_ON
        ; Store the return address in Scratch Register A.
        STA DECODER_SRAL
        STY DECODER_SRAH
        INC DECODER_SRAL
        BNE :+
        INC DECODER_SRAH
      :

        ; Save the Address Decoder registers.
        LDX PROC_CURRENT_IX
        LDA DECODER_MLR
        STA PROC_METADATA_MLR, X
        LDA DECODER_RLR
        STA PROC_METADATA_RLR, X

        ; Save the return address.
        TXA
        ASL
        TAX
        LDA DECODER_SRAL    
        STA PROC_METADATA_PC, X
        LDA DECODER_SRAH
        INX
        STA PROC_METADATA_PC, X 

        ; Find the next valid process and switch to it.
      PROC_YIELD_FIND_PROC:
        LDX PROC_CURRENT_IX
      : INX
        CPX PROC_MAX_COUNT
        BNE :+
        LDX #$00
      : BIT PROC_METADATA_STATUS, X
        BPL :--

        ; Restore the Address Decoder registers.
      PROC_SWITCH:
        LDA PROC_METADATA_MLR, X
        STA DECODER_MLR
        LDA PROC_METADATA_RLR, X
        STA DECODER_RLR

        ; Get the process' program counter from the metadata table and
        ; store it in Scratch Register D.
        PHX
        TXA
        ASL
        TAX
        LDA PROC_METADATA_PC, X
        STA DECODER_SRAL
        INX
        LDA PROC_METADATA_PC, X
        STA DECODER_SRAH

        ; Switch to the process' memory space and exit the system context.
        PLX
        STX PROC_CURRENT_IX
        STX DECODER_WBR
    SFMODE_SYSCTX_OFF

    ; Jump to the process' return address.
    JMP (DECODER_SRA)
.ENDPROC
.EXPORT PROC_YIELD

; PROC_TERM procedure
; Modifies: A, X
;
; Terminates the current process and switches to another running process.
.PROC PROC_TERM
    SFMODE_SYSCTX_ON
        ; Clear the current process' status bits
        LDX PROC_CURRENT_IX
        STZ PROC_METADATA_STATUS, X

        ; Switch to the system process.
        LDX #$00
        JMP PROC_YIELD::PROC_SWITCH
    SFMODE_IMPLIED
.ENDPROC
.EXPORT PROC_TERM
