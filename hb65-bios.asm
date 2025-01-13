; hb65-bios.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Basic input/output system for the HB65 Microcomputer System"

.IMPORT     __SHAREDMEM_START__

.INCLUDE    "hb65-system.inc"

; BIOS jumptable
.SEGMENT "BIOSJMPTBL"
BIOSJMPTBL:

SYSCALLS_PROC_NEW           := $00
.IMPORT PROC_NEW
.WORD PROC_NEW

SYSCALLS_PROC_KILL          := SYSCALLS_PROC_NEW + $02
.IMPORT PROC_KILL
.WORD PROC_KILL

SYSCALLS_PROC_SWITCH        := SYSCALLS_PROC_KILL + $02
.IMPORT PROC_SWITCH
.WORD PROC_SWITCH

SYSCALLS_WOZ_ENTER          := SYSCALLS_PROC_SWITCH + $02
.IMPORT WOZ_ENTER
.WORD WOZ_ENTER

SYSCALLS_WOZ_EXIT           := SYSCALLS_WOZ_ENTER + $02
.IMPORT WOZ_EXIT
.WORD WOZ_EXIT

; BIOS shared data
.EXPORT SYSCDAT_JMP_ADDR    := __SHAREDMEM_START__