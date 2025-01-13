; hb65-bios-proc.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS process management routines"

.IMPORT     SYSCDAT_JMP_ADDR, SYSCDAT_JMP_ADDR_HI, SYSCDAT_JMP_ADDR_LO

.INCLUDE    "hb65-system.inc"

; Process metadata table
PROC_MAX_COUNT          := $00
PROC_CURRENT_IX         := $01
PROC_METADATA_STATES    := $0300
PROC_METADATA_REG_DCR   := $0310
PROC_METADATA_REG_ALR   := $0320
PROC_METADATA_REG_ZPLR  := $0330

; Process management routines
.SEGMENT "BIOS"

; PROC_INIT procedure
; Modifies: A, flags
;
; Initializes the process metadata table.
.PROC PROC_INIT
    STZ DECODER_SCR
    ; Check whether we have 128K or 512K of WRAM, which changes
    ; how many processes we can run simultaneously.
    LDA DECODER_DCR
    AND #%00000100
    BEQ PROC_128K
    LDA #$10
    JMP PROC_INIT_TBL
PROC_128K:
    LDA #$04
PROC_INIT_TBL:
    ; Initialize the process metadata table by setting the
    ; maximum process count and then clearing the state flags
    ; for all processes.
    STA PROC_MAX_COUNT
    STZ PROC_CURRENT_IX
    TAX
    LDA #$FF
:   DEX
    STZ PROC_METADATA_STATES, X
    STZ PROC_METADATA_REG_DCR, X
    STZ PROC_METADATA_REG_ALR, X
    STA PROC_METADATA_REG_ZPLR, X
    BNE :-
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
.PROC PROC_NEW
    STZ DECODER_SCR
    LDX #$00
:   BIT PROC_METADATA_STATES, X
    BPL PROC_ALLOC
    INX
    CPX PROC_MAX_COUNT
    BNE :-
    LDA #$FF
    JMP PROC_DONE
PROC_ALLOC:
    LDA #%10000000
    STA PROC_METADATA_STATES, X
    JSR _PROC_SAVE_REGISTERS
    TXA
PROC_DONE:
    STZ DECODER_SCR
    RTS
.ENDPROC
.EXPORT PROC_NEW

; PROC_KILL procedure
; Modifies: X, flags
;
; Kills the process with the index specified in the A register.
.PROC PROC_KILL
    STZ DECODER_SCR
    TAX
    STZ PROC_METADATA_STATES, X
    STZ DECODER_SCR
    RTS
.ENDPROC
.EXPORT PROC_KILL

; PROC_SWITCH procedure
; Modifies: A, X, Y, flags
;
; Switches execution to the process specified in the X register, then jumps
; to the location stored in PROC_DATA_TARGET_ADDR (in the shared data page).
.PROC PROC_SWITCH
    STZ DECODER_SCR             ; Enter syscall mode

    BIT PROC_METADATA_STATES, X ; Ensure that the requested process exists
    BPL FAILED                  ; and fail if it does not.

    PLA                         ; Discard the return address that was pushed
    PLA                         ; onto the stack by JSR; we won't need it.

    PHX                         ; Save the registers for the current process
    LDX PROC_CURRENT_IX
    JSR _PROC_SAVE_REGISTERS    

    PLX                         ; Update the current process index
    STX PROC_CURRENT_IX         

    JSR _PROC_LOAD_REGISTERS    ; Load the registers for the new process.

    LDA SYSCDAT_JMP_ADDR        ; Copy the jump address into registers
    LDY SYSCDAT_JMP_ADDR+1      ; so that we don't lose them when banking WRAM.

    STX DECODER_WRBR            ; Switch to the new memory space.

    STA SYSCDAT_JMP_ADDR        ; Copy the jump address into the newly-exposed
    STY SYSCDAT_JMP_ADDR+1      ; shared data page in WRAM.

    STZ DECODER_SCR             ; Exit syscall mode and jump to
    JMP (SYSCDAT_JMP_ADDR)      ; the target address.

FAILED:
    STZ DECODER_SCR             ; Exit syscall mode and return $FF
    LDA #$FF
    RTS
.ENDPROC
.EXPORT PROC_SWITCH

; _PROC_SAVE_REGISTERS procedure
; Modifies: A, flags
;
; Saves the current register states for the process stored in X.
.PROC _PROC_SAVE_REGISTERS
    LDA DECODER_DCR
    STA PROC_METADATA_REG_DCR, X
    LDA DECODER_ALR
    STA PROC_METADATA_REG_ALR, X
    LDA DECODER_ZPLR
    STA PROC_METADATA_REG_ZPLR, X
    RTS
.ENDPROC

; _PROC_LOAD_REGISTERS procedure
; Modifies: A, flags
;
; Loads the register state for the process stored in X.
.PROC _PROC_LOAD_REGISTERS
    LDA PROC_METADATA_REG_DCR, X
    STA DECODER_DCR
    LDA PROC_METADATA_REG_ALR, X
    STA DECODER_ALR
    LDA PROC_METADATA_REG_ZPLR, X
    STA DECODER_ZPLR
    RTS
.ENDPROC