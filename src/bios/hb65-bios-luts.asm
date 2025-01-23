; hb65-bios-luts.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS common lookup tables"

.INCLUDE    "../hb65-system.inc"

; LUTs
.SEGMENT "BIOS"

; LUT_HEXCHARS
; A lookup able that relates the offset index to a byte value that corresponds to the
; index's representation as a hexadecimal character in ASCII.
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
.EXPORT LUT_HEXCHARS