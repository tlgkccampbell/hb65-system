; hb65-wozmon.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Address Decoder interface subroutines"

.INCLUDE    "hb65-system.inc"

; Address Decoder interface subroutines
.SEGMENT "BIOS"

; SYSCTX_START procedure
; Modifies: X
;
; Enters System Context Mode.
.PROC SYSCTX_START
    ; Disable interrupts.
    DEC DECODER_ICR

    ; Pull the return address from the stack and store it in Scratch Register B.
    PLX
    STX DECODER_SRDL
    PLX
    STX DECODER_SRDH

    ; Switch to the system context.
    TSX
    STX DECODER_SPR
    TAX
    LDA DECODER_DCR
    ORA #(1 << DECODER_DCR_BIT::SYSCTX)
    STA DECODER_DCR
    TXA
    LDX DECODER_SPR
    TXS

    ; Push the return address onto the new stack.
    LDX DECODER_SRDH
    PHX
    LDX DECODER_SRDL
    PHX

    ; Enable interrupts and return.
    INC DECODER_ICR
    RTS
.ENDPROC
.EXPORT SYSCTX_START

; SYSCTX_END procedure
; Modifies: X
;
; Leaves System Context Mode.
.PROC SYSCTX_END
    ; Disable interrupts.
    DEC DECODER_ICR

    ; Pull the return address from the stack and store it in Scratch Register B.
    PLX
    STX DECODER_SRDL
    PLX
    STX DECODER_SRDH

    ; Switch out of the system context.
    TSX
    STX DECODER_SPR
    TAX
    LDA DECODER_DCR
    AND #<~(1 << DECODER_DCR_BIT::SYSCTX)
    STA DECODER_DCR
    TXA
    LDX DECODER_SPR
    TXS

    ; Push the return address onto the new stack.
    LDX DECODER_SRDH
    PHX
    LDX DECODER_SRDL
    PHX 

    ; Enable interrupts and return.
    INC DECODER_ICR
    RTS
.ENDPROC
.EXPORT SYSCTX_END

; ALTFN_START procedure
; Modifies: n/a
;
; Enters Alternative Function Mode.
.PROC ALTFN_START
    PHA
    LDA DECODER_DCR
    ORA #(1 << DECODER_DCR_BIT::ALTFN)
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT ALTFN_START

; ALTFN_END procedure
; Modifies: n/a
;
; Leaves Alternative Function Mode.
.PROC ALTFN_END
    PHA
    LDA DECODER_DCR
    AND #<~(1 << DECODER_DCR_BIT::ALTFN)
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT ALTFN_END