; hb65-bios-stream.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS stream routines"

.INCLUDE    "../hb65-system.inc"

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
    PHA
    PHX
    PHY
    LDY #$00
  LOOP:
    LDA (DECODER_SRB), Y
    BEQ :+

    ; Preserve Y and Scratch Register B
    PHY
    LDX DECODER_SRBL
    PHX
    LDX DECODER_SRBH
    PHX

    ; Call PUTC
    JSR JMP_SRA

    ; Restore Y and Scratch Register B
    PLX
    STX DECODER_SRBH
    PLX
    STX DECODER_SRBL
    PLY
    INY
    JMP LOOP

  : PLY
    PLX
    PLA
    RTS
.ENDPROC
.EXPORT STRM_PUTSTR

; STRM_PUTSTR_IMM procedure
; Modifies: A
;
; Writes a string using the PUTC procedure pointed to by Scratch Register A.
; The null-terminated string data should be inlined immediately after the call to this procedure.
.PROC STRM_PUTSTR_IMM
    PLA
    STA DECODER_SRDL
    PLA
    STA DECODER_SRDH
    PHX
    BRA STRIMM3
  STRIMM2:
    LDX DECODER_SRDL
    PHX
    LDX DECODER_SRDH
    PHX
    JSR JMP_SRA
    PLX
    STX DECODER_SRDH
    PLX
    STX DECODER_SRDL
  STRIMM3:
    INC DECODER_SRDL
    BNE STRIMM4
    INC DECODER_SRDH
  STRIMM4:
    LDA (DECODER_SRD)
    BNE STRIMM2
    LDA DECODER_SRDH
    PLX
    PHA
    LDA DECODER_SRDL
    PHA
    RTS
.ENDPROC
.EXPORT STRM_PUTSTR_IMM

; STRM_PUTHEX procedure
; Modifies: n/a
;
; Writes a hexadecimal representation of the value in the A register using the PUTC
; procedure pointed to by Scratch Register A.
.PROC STRM_PUTHEX
    PHA
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
    PLA
    RTS
.ENDPROC
.EXPORT STRM_PUTHEX

; STRM_PUTHEX16 procedure
; Modifies: n/a
;
; Writes a hexadecimal representation of the 16-bit value in Scratch Register B
; using the PUTC procedure pointed to by Scratch Register A.
.PROC STRM_PUTHEX16
    PHA
    PHX
    LDA DECODER_SRBH
    LDX DECODER_SRBL
    JSR STRM_PUTHEX
    TXA
    JSR STRM_PUTHEX
    PLX
    PLA
    RTS
.ENDPROC
.EXPORT STRM_PUTHEX16