; hb65-bios-proc.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS process management routines"

.INCLUDE    "../hb65-system.inc"

BAR_STK := DECODER_BAR0
BAR_PC  := DECODER_BAR1
BAR_PCL := DECODER_BAR1
BAR_PCH := DECODER_BAR2

; Process metadata table
.SEGMENT "SYSZP"
PROC_MAX_COUNT:         .RES 1
PROC_CURRENT_IX:        .RES 1

.SEGMENT "SYSWRAM"
PROC_METADATA_STATUS:   .RES 16
PROC_METADATA_MLR:      .RES 16
PROC_METADATA_RLR:      .RES 16

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

    ; Disable interrupts
    DEC DECODER_ICR

    ; Switch to the system context.
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

        ; Find an open slot, set its valid bit, and store its
        ; initial program counter and register values in the metadata table.
        ; Return the new process index in the A register.
      PROC_NEW_ALLOC:
        LDA #(1 << PROC_STATUS_BIT::VALID)
        STA PROC_METADATA_STATUS, X
        STZ PROC_METADATA_MLR, X
        STZ PROC_METADATA_RLR, X

        ; Temporarily switch WRAM banks to the new process
        ; so that we can save its metadata in the Address Decoder's BARs.
        LDA DECODER_WBR
        STX DECODER_WBR
        LDX #$FF
        STX BAR_STK       ; Stack pointer
        LDX DECODER_SRAL
        STX BAR_PCL       ; Program counter (low)
        LDX DECODER_SRAH
        STX BAR_PCH       ; Program counter (high)
        STA DECODER_WBR
PROC_NEW_DONE:
    SFMODE_SYSCTX_OFF

    ; Re-enable interrupts
    INC DECODER_ICR

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

    ; Disable interrupts.
    DEC DECODER_ICR

    ; Switch to the system context.
    SFMODE_SYSCTX_ON
        ; Store the return address in Scratch Register A.
        STA DECODER_SRAL
        STY DECODER_SRAH
        INC DECODER_SRAL
        BNE :+
        INC DECODER_SRAH
      :
        ; Get the previous process' Address Decoder registers 
        ; and store them in the process metadata table.
        LDX PROC_CURRENT_IX
        LDA DECODER_MLR
        STA PROC_METADATA_MLR, X
        LDA DECODER_RLR
        STA PROC_METADATA_RLR, X

        ; Get the previous process' program counter and stack pointer
        ; and store them in the BARs.
        TXA
        LDX DECODER_SRAL
        STX BAR_PCL
        LDX DECODER_SRAH
        STX BAR_PCH
        TSX
        STX BAR_STK
        TAX

        ; Find the next valid process and switch to it.
      PROC_YIELD_FIND_PROC:
        LDX PROC_CURRENT_IX
      : INX
        CPX PROC_MAX_COUNT
        BNE :+
        LDX #$00
      : BIT PROC_METADATA_STATUS, X
        BPL :--

        ; Switch to the process' memory space.
      PROC_SWITCH:
        STX PROC_CURRENT_IX
        STX DECODER_WBR

        ; Get the new process' Address Decoder registers 
        ; from the process metadata table and update the Address Decoder.
        LDA PROC_METADATA_MLR, X
        STA DECODER_MLR
        LDA PROC_METADATA_RLR, X
        STA DECODER_RLR

        ; Get the new process' program counter and stack pointer
        ; from the BARs, update the CPU stack pointer, and prepare to jump.
        TXA
        LDX BAR_PCL
        STX DECODER_SRAL
        LDX BAR_PCH
        STX DECODER_SRAH
        LDX BAR_STK
        TXS
        TAX
    SFMODE_SYSCTX_OFF

    ; Re-enable interrupts.
    INC DECODER_ICR

    ; Jump to the process' return address.
    JMP (DECODER_SRA)
.ENDPROC
.EXPORT PROC_YIELD

; PROC_TERM procedure
; Modifies: A, X
;
; Terminates the current process and switches to another running process.
.PROC PROC_TERM
    ; Disable interrupts.
    DEC DECODER_ICR

    ; Switch to the system context.
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
