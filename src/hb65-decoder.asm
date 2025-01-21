; hb65-wozmon.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Address Decoder interface subroutines"

.INCLUDE    "hb65-system.inc"

; Address Decoder interface subroutines
.SEGMENT "BIOS"

; SYSCTX_START procedure
; Modifies: n/a
;
; Enters System Context Mode.
.PROC SYSCTX_START
    PHA
    LDA DECODER_DCR
    ORA #(1 << DECODER_DCR_BIT::SYSCTX)
    STA DECODER_DCR
    PLA
    RTS
.ENDPROC
.EXPORT SYSCTX_START

; SYSCTX_END procedure
; Modifies: n/a
;
; Leaves System Context Mode.
.PROC SYSCTX_END
    PHA
    LDA DECODER_DCR
    AND #<~(1 << DECODER_DCR_BIT::SYSCTX)
    STA DECODER_DCR
    PLA
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