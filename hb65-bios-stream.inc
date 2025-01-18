.IFNDEF _INCLUDE_BIOS_STREAM_
_INCLUDE_BIOS_STREAM_ = 1

; STREAM structure
; Represents a bidirectional stream of bytes.
.STRUCT STREAM
    ; A pointer to a routine that clears the stream's output.
    CLR     .WORD
    ; A pointer to a routine that reads a byte from the stream into the A register.
    GETC    .WORD
    ; A pointer to a routine that writes a byte from the A register to the stream.
    PUTC    .WORD
.ENDSTRUCT

.ENDIF