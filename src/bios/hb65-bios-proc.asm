; hb65-bios-proc.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS process management routines"

.INCLUDE    "../hb65-system.inc"

BAR_STK := DECODER_BAR0
BAR_PC  := DECODER_BAR1
BAR_PCL := DECODER_BAR1
BAR_PCH := DECODER_BAR2

; Process metadata table
.SEGMENT "SYSZP": zeropage

PROC_MAX:           .RES 1
PROC_INDEX:         .RES 1
PROC_METADATA_STATUS:
PROC_METADATA_MLR:  .RES 16
PROC_METADATA_RLR:  .RES 16

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

    GLOBAL_INTERRUPT_MASK_ON
        SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX)
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
            STA PROC_MAX
            STZ PROC_INDEX
            TAX
          : DEX
            STZ PROC_METADATA_STATUS, X
            BNE :-
        SFMODE_POP
    GLOBAL_INTERRUPT_MASK_OFF

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

    ; Switch to the system context.
    GLOBAL_INTERRUPT_MASK_ON
        SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX)
            ; Find an unused process slot in the metadata table.
          PROC_NEW_FIND_UNUSED:
            LDX #$00
          : BIT PROC_METADATA_STATUS, X
            BPL PROC_NEW_ALLOC
            INX
            CPX PROC_MAX
            BNE :-

            ; Failed to find an open slot, so exit with $FF in A.
            LDA #$FF
            JMP PROC_NEW_DONE

            ; Find an open slot and initialize its entry in the metadata table.
            ; Return the new process index in the A register.
          PROC_NEW_ALLOC:
            LDA #(1 << PROC_STATUS_BIT::VALID)
            STA PROC_METADATA_MLR, X
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
        SFMODE_POP
    GLOBAL_INTERRUPT_MASK_OFF

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
    GLOBAL_INTERRUPT_MASK_ON
        SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX)
            ; Store the previous process' return address and stack pointer
            ; in the Address Decoder's BARs.
            PLA
            STA BAR_PCL
            PLA
            STA BAR_PCH
            INC BAR_PCL
            BNE :+
            INC BAR_PCH
          : TSX
            STX BAR_STK

            ; Get the previous process' Address Decoder registers 
            ; and store them in the process metadata table.
            LDX PROC_INDEX
            LDA DECODER_MLR
            ORA #(1 << PROC_STATUS_BIT::VALID)
            STA PROC_METADATA_MLR, X
            LDA DECODER_RLR
            STA PROC_METADATA_RLR, X

          PROC_YIELD_FIND_PROC:
            ; Find the next valid process and switch to it.
          : INX
            CPX PROC_MAX
            BNE :+
            LDX #$00
          : BIT PROC_METADATA_STATUS, X
            BPL :--

          PROC_SWITCH:
            ; Get the new process' Address Decoder registers 
            ; from the process metadata table and update the Address Decoder.
            STX PROC_INDEX
            LDA PROC_METADATA_MLR, X
            STA DECODER_MLR
            LDA PROC_METADATA_RLR, X
            STA DECODER_RLR
        SFMODE_POP
            ; Update the WRAM bank index and stack register.
            STX DECODER_WBR
            LDX BAR_STK
            TXS
    GLOBAL_INTERRUPT_MASK_OFF

    ; Jump to the process' return address.
    JMP (BAR_PCL)
.ENDPROC
.EXPORT PROC_YIELD

; PROC_TERM procedure
; Modifies: A, X
;
; Terminates the current process and switches to another running process.
.PROC PROC_TERM
    ; Switch to the system context.
    GLOBAL_INTERRUPT_MASK_ON
        SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX)
            ; Clear the current process' status bits
            LDX PROC_INDEX
            STZ PROC_METADATA_STATUS, X

            ; Switch to the system process.
            LDX #$00
            JMP PROC_YIELD::PROC_SWITCH
        SFMODE_POP_IMPLIED
    GLOBAL_INTERRUPT_MASK_IMPLIED
.ENDPROC
.EXPORT PROC_TERM
