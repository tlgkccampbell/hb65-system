; hb65-bios-stream.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS stream routines"

.INCLUDE    "hb65-system.inc"

.IMPORT     JMP_SRA

; Stream routines
.SEGMENT "BIOS"

; LUT_HEXCHARS
; A lookup table mapping integer values to hexadecimal characters.
LUT_HEXCHARS:
  .BYTE '0'
  .BYTE '1'
  .BYTE '2'
  .BYTE '3'
  .BYTE '4'
  .BYTE '5'
  .BYTE '6'
  .BYTE '7'
  .BYTE '8'
  .BYTE '9'
  .BYTE 'A'
  .BYTE 'B'
  .BYTE 'C'
  .BYTE 'D'
  .BYTE 'E'
  .BYTE 'F'

; STRM_PUTNL
; Modifies: n/a
; 
; Writes a newline character using the PUTC procedure pointed to by Scratch Register A.
.PROC STRM_PUTNL
  PHA
  LDA #$0A
  JSR JMP_SRA
  PLA
  RTS
.ENDPROC
.EXPORT STRM_PUTNL

; STRM_PUTSTR procedure
; Modifies: ?
;
; Writes a string using the PUTC procedure pointed to by Scratch Register A.
; The null-terminated string data should be pointed to by Scratch Register B.
.PROC STRM_PUTSTR
    LDY #$00
  LOOP:
    LDA (DECODER_SRB), Y
    BEQ :+
    PHY
    JSR JMP_SRA
    PLY
    INY
    JMP LOOP
  : RTS
.ENDPROC
.EXPORT STRM_PUTSTR

; STRM_PUTSTR_IMM procedure
; Modifies: A, X, SRB, flags
;
; Writes a string using the PUTC procedure pointed to by Scratch Register A.
; The null-terminated string data should be inlined immediately after the call to this procedure.
.PROC STRM_PUTSTR_IMM
    PLA
    STA DECODER_SRBL
    PLA
    STA DECODER_SRBH
    BRA STRIMM3
  STRIMM2:
    JSR JMP_SRA
  STRIMM3:
    INC DECODER_SRBL
    BNE STRIMM4
    INC DECODER_SRBH
  STRIMM4:
    LDA (DECODER_SRB)
    BNE STRIMM2
    LDA DECODER_SRBH
    PHA
    LDA DECODER_SRBL
    PHA
    RTS
.ENDPROC
.EXPORT STRM_PUTSTR_IMM

; STRM_PUTHEX procedure
; Modifies: A, X, flags
;
; Writes a hexadecimal representation of the value in the A register using the PUTC
; procedure pointed to by Scratch Register A.
.PROC STRM_PUTHEX
    PHA
    ; Output low nibble
    ROR
    ROR
    ROR
    ROR
    AND #$0F
    TAX
    LDA LUT_HEXCHARS, X
    JSR JMP_SRA
    ; Output high nibble
    PLA
    AND #$0F
    TAX
    LDA LUT_HEXCHARS, X
    JSR JMP_SRA
    RTS
.ENDPROC
.EXPORT STRM_PUTHEX

; STRM_PUTHEX16 procedure
; Modifies: A, X, flags
;
; Writes a hexadecimal representation of the 16-bit value in Scratch Register C
; using the PUTC procedure pointed to by Scratch Register A.
.PROC STRM_PUTHEX16
    LDA DECODER_SRCH
    JSR STRM_PUTHEX
    LDA DECODER_SRCL
    JSR STRM_PUTHEX
    RTS
.ENDPROC
.EXPORT STRM_PUTHEX16