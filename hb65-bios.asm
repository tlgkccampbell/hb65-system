; hb65-bios.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Basic input/output system for the HB65 Microcomputer System"

.INCLUDE    "hb65-system.inc"

; BIOS jumptable
.SEGMENT "BIOSJMPTBL"
BIOSJMPTBL:

SYSCALLS_PROC_NEW           = $00
.IMPORT PROC_NEW
.WORD PROC_NEW

SYSCALLS_PROC_TERM          = SYSCALLS_PROC_NEW + $02
.IMPORT PROC_TERM
.WORD PROC_TERM

SYSCALLS_PROC_YIELD         = SYSCALLS_PROC_TERM + $02
.IMPORT PROC_YIELD
.WORD PROC_YIELD