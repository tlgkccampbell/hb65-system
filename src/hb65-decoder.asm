; hb65-wozmon.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Address Decoder interface subroutines"

.INCLUDE    "hb65-system.inc"

; Address Decoder interface subroutines
.SEGMENT "BIOS"

; DECODER_INTEN_ON procedure
; Modifies: n/a
;
; Globally enables interrupts in the Address Decoder.
.PROC DECODER_INTEN_ON
    PHA
    LDA DECODER_ICR
    ORA #(1 << DECODER_ICR_BIT::INTEN)
    STA DECODER_ICR
    PLA
    RTS
.ENDPROC
.EXPORT DECODER_INTEN_ON

; DECODER_INTEN_OFF procedure
; Modifies: n/a
;
; Globally disables interrupts in the Address Decoder.
.PROC DECODER_INTEN_OFF
    PHA
    LDA DECODER_ICR
    AND #<~(1 << DECODER_ICR_BIT::INTEN)
    STA DECODER_ICR
    PLA
    RTS
.ENDPROC
.EXPORT DECODER_INTEN_OFF

; DECODER_SYSCTX_ON procedure
; Modifies: n/a
;
; Enters System Context Mode.
.PROC DECODER_SYSCTX_ON
    PHA
    LDA DECODER_DCR
    ORA #(1 << DECODER_DCR_BIT::SYSCTX)
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT DECODER_SYSCTX_ON

; DECODER_SYSCTX_OFF procedure
; Modifies: n/a
;
; Leaves System Context Mode.
.PROC DECODER_SYSCTX_OFF
    PHA
    LDA DECODER_DCR
    AND #<~(1 << DECODER_DCR_BIT::SYSCTX)
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT DECODER_SYSCTX_OFF

; DECODER_ALTFN_ON procedure
; Modifies: n/a
;
; Enters Alternative Function Mode.
.PROC DECODER_ALTFN_ON
    PHA
    LDA DECODER_DCR
    ORA #(1 << DECODER_DCR_BIT::ALTFN)
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT DECODER_ALTFN_ON

; DECODER_ALTFN_OFF procedure
; Modifies: n/a
;
; Leaves Alternative Function Mode.
.PROC DECODER_ALTFN_OFF
    PHA
    LDA DECODER_DCR
    AND #<~(1 << DECODER_DCR_BIT::ALTFN)
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT DECODER_ALTFN_OFF