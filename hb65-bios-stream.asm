; hb65-bios-stream.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS stream routines"

.INCLUDE    "hb65-system.inc"
.INCLUDE    "hb65-bios-stream.inc"

; Stream routines

; _STRM_JMP procedure
; Modifies: n/a
;
; Jumps to a stream subroutine.
.PROC _STRM_JMP
    JMP (DECODER_SR0, X)
.ENDPROC

; STRM_NULL procedure
; Modifies: n/a
;
; A placeholder subroutine that immediately returns without performing any operations.
.PROC STRM_NULL
    RTS
.ENDPROC
.EXPORT STRM_NULL

; STRM_CLR procedure
; Modifies: A, X, flags
;
; Clears the STREAM pointed to by Scratch Register 0.
.PROC STRM_CLR
    LDX STREAM::CLR
    JSR _STRM_JMP
.ENDPROC
.EXPORT STRM_CLR

; STRM_GETC procedure
; Modifies: A, X, flags
;
; Reads a byte from the stream pointed at by Scratch Register 0 and places it into the A register.
.PROC STRM_GETC
    LDX STREAM::GETC
    JSR _STRM_JMP
.ENDPROC
.EXPORT STRM_GETC

; STRM_PUTC procedure
; Modifies: A, X, flags
;
; Writes a byte from the A register into the stream pointed at by Scratch Register 0.
.PROC STRM_PUTC
    LDX STREAM::PUTC
    JSR _STRM_JMP
.ENDPROC
.EXPORT STRM_PUTC

; STRM_PUTSTR_IMM procedure
; Modifies: A, X, flags
;
; Writes a string to the stream pointed at by Scratch Register 0. The string data should be
; inlined immediately after the call to this procedure.
.PROC STRM_PUTSTR_IMM
    ; Pull the return address from the stack.
    PLA
    STA DECODER_SR1L
    PLA
    STA DECODER_SR1H
    BRA STRIMM3
  STRIMM2:
    JSR STRM_PUTC
  STRIMM3:
    INC DECODER_SR1L
    BNE STRIMM4
    INC DECODER_SR1H
  STRIMM4:
    LDA (DECODER_SR1)
    BNE STRIMM2
    LDA DECODER_SR1H
    PHA
    LDA DECODER_SR1L
    PHA
    RTS
.ENDPROC
.EXPORT STRM_PUTSTR_IMM