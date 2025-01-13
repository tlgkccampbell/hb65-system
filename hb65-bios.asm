; hb65-bios.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Basic input/output system for the HB65 Microcomputer System"

.INCLUDE    "hb65-system.inc"

; BIOS jumptable
.SEGMENT "BIOSJMPTBL"

.IMPORT WOZ_ENTER
.WORD WOZ_ENTER       ; $00

.IMPORT WOZ_EXIT
.WORD WOZ_EXIT        ; $02