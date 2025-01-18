; hb65-bios.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Basic input/output system for the HB65 Microcomputer System"

.INCLUDE    "hb65-system.inc"

; BIOS jumptable
.SEGMENT "BIOSJMPTBL"

; 00
SYSCALLS_PROC_NEW           = $00
.IMPORT PROC_NEW
.WORD PROC_NEW

; 02
SYSCALLS_PROC_TERM          = SYSCALLS_PROC_NEW + $02
.IMPORT PROC_TERM
.WORD PROC_TERM

; 04
SYSCALLS_PROC_YIELD         = SYSCALLS_PROC_TERM + $02
.IMPORT PROC_YIELD
.WORD PROC_YIELD

; 06
SYSCALLS_WOZMON             = SYSCALLS_PROC_YIELD + $02
.IMPORT WOZ_INIT
.WORD WOZ_INIT

; 08
SYSCALLS_TIME_DELAY_50US    = SYSCALLS_WOZMON + $02
.IMPORT TIME_DELAY_50US
.WORD TIME_DELAY_50US

; 0A
SYSCALLS_TIME_DELAY_1MS     = SYSCALLS_TIME_DELAY_50US + $02
.IMPORT TIME_DELAY_1MS
.WORD TIME_DELAY_1MS

; 0C
SYSCALLS_TIME_DELAY_50MS    = SYSCALLS_TIME_DELAY_1MS + $02
.IMPORT TIME_DELAY_50MS
.WORD TIME_DELAY_50MS

; 0E
SYSCALLS_GPIO_BUZZER_BEEP   = SYSCALLS_TIME_DELAY_50MS + $02
.IMPORT GPIO_BUZZER_BEEP
.WORD GPIO_BUZZER_BEEP