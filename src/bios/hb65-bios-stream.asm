; hb65-bios-stream.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS stream routines"

.INCLUDE    "../hb65-system.inc"

.IMPORT     JMP_SRA
.IMPORt		LUT_BINSTRS, LUT_HEXCHARS

; Stream data
.SEGMENT "SYSZP": zeropage

_STRM_PUTC_PTR:
_STRM_PUTC_PTRL:	.RES 1
_STRM_PUTC_PTRH:	.RES 1
_STRM_DATA_PTR:
_STRM_DATA_PTRL:	.RES 1
_STRM_DATA_PTRH:	.RES 1

; Stream routines
.SEGMENT "BIOS"

; _STRM_JMP_PUTC
; Modifies: n/a
;
; Performs an indirect jump to the pointer at _STRM_PUTC_PTR.
.PROC _STRM_JMP_PUTC
	JMP (_STRM_PUTC_PTR)
.ENDPROC

; STRM_PUTNL
; Modifies: A
; 
; Writes a newline character using the PUTC procedure pointed to by Scratch Register A.
.PROC STRM_PUTNL
	LDA #$0A
  	JSR JMP_SRA
  	RTS
.ENDPROC
.EXPORT STRM_PUTNL

; STRM_PUTSTR procedure
; Modifies: A
;
; Writes a string using the PUTC procedure pointed to by Scratch Register A.
; The null-terminated string data should be pointed to by Scratch Register B.
.PROC STRM_PUTSTR
	PHY
	SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX)
		; Pull the PUTC pointer from Scratch Register A and store it in the zeropage.
		LDA DECODER_SRAL
		STA _STRM_PUTC_PTRL
		LDA DECODER_SRAH
		STA _STRM_PUTC_PTRH
		; Pull the DATA pointer from Scratch Register B and store it in the zeropage.
		LDA DECODER_SRBL
		STA _STRM_DATA_PTRL
		LDA DECODER_SRBH
		STA _STRM_DATA_PTRH
		; Begin the stream operation.
		LDY #$00
	  LOOP:
	  	; Load the next character and check for nulls.
		LDA (_STRM_DATA_PTR), Y
		BEQ DONE
		JSR _STRM_JMP_PUTC
		INY
		JMP LOOP
  	  DONE:
	SFMODE_POP
	PLY
    RTS
.ENDPROC
.EXPORT STRM_PUTSTR

; STRM_PUTSTR_IMM procedure
; Modifies: A
;
; Writes a string using the PUTC procedure pointed to by Scratch Register A.
; The null-terminated string data should be inlined immediately after the call to this procedure.
.PROC STRM_PUTSTR_IMM
	SFMODE_PUSH_AND_ORA (1 << DECODER_DCR_BIT::SYSCTX)
		; Pull the PUTC pointer from Scratch Register A and store it in the zeropage.
		LDA DECODER_SRAL
		STA _STRM_PUTC_PTRL
		LDA DECODER_SRAH
		STA _STRM_PUTC_PTRH
		; Pull the DATA pointer from the stack and store it in the zeropage.
		PLA
		STA _STRM_DATA_PTRL
		PLA
		STA _STRM_DATA_PTRH
		; Begin the stream operation.
		PHX
		BRA STRIMM3
	  STRIMM2:
	  	; Call PUTC.
		JSR _STRM_JMP_PUTC
	  STRIMM3:
	  	; Move to the next character in the string.
		INC _STRM_DATA_PTRL
		BNE STRIMM4
		INC _STRM_DATA_PTRH
	  STRIMM4: 
	  	; Load the next character and check for nulls.
		LDA (_STRM_DATA_PTR)
		BNE STRIMM2
		LDA _STRM_DATA_PTRH
		PLX
		PHA
		LDA _STRM_DATA_PTRL
		PHA
	SFMODE_POP
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
	; Write the high nibble
    LDA DECODER_SRBH
    JSR STRM_PUTHEX
	; Write the low nibble
    LDA DECODER_SRBL
    JSR STRM_PUTHEX
    PLA
    RTS
.ENDPROC
.EXPORT STRM_PUTHEX16