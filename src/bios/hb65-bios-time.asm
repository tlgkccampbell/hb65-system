; hb65-bios-time.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS time routines"

.INCLUDE    "../hb65-system.inc"

; Time routines
.SEGMENT "BIOS"

; TIME_DELAY_50US procedure
; Modifies: n/a
;
; Delays for approximately 50 microseconds (assuming a 3.15 MHz clock).
.PROC TIME_DELAY_50US
              ; 6 cycles (JSR)
    PHX       ; 3 cycles
    LDX #$1C	; 2 cycles
  : DEX		    ; 2 cycles
    BNE :-		; 3 cycles / 2 cycles
    PLX       ; 4 cycleds
    RTS		    ; 6 cycles
              ; 21 cycles [overhead] + (5 * X) - 1 cycles [loop] = 160 cycles (X = $1C)
              ; 160 cycles * 318 ns/cycle = 50.88 microseconds
.ENDPROC
.EXPORT TIME_DELAY_50US

; TIME_DELAY_1MS procedure
; Modifies: X, Y, flags
;
; Delays for approximately 1 millisecond (assuming a 3.15 MHz clock).
.PROC TIME_DELAY_1MS
              ; 6 cycles (JSR)
    PHX       ; 3 cycles
    PHY       ; 3 cycles
    LDY #$04	; 2 cycles
  : LDX #$9B	; 2 cycles
  : DEX		    ; 2 cycles
    BNE :-		; 3 cycles / 2 cycles
    DEY		    ; 2 cycles
    BNE :--		; 3 cycles / 2 cycles
    PLY       ; 4 cycles
    PLX       ; 4 cycles
    RTS		    ; 6 cycles
              ; 28 cycles [overhead] + (Y * (7 + (2 + (5 * X) - 1))) - 1 cycles [loop] = 3159 cycles (X = $9B, Y = $04)
              ; 3159 cycles * 318 ns/cycle = 1.004562 milliseconds
.ENDPROC
.EXPORT TIME_DELAY_1MS

; TIME_DELAY_50MS procedure
; Modifies: X, Y, flags
;
; Delays for approximately 50 milliseconds (assuming a 3.15 MHz clock).
.PROC TIME_DELAY_50MS
              ; 6 cycles (JSR)
    PHX       ; 3 cycles
    PHY       ; 3 cycles
    LDY #$C9	; 2 cycles
  : LDX #$9B	; 2 cycles
  : DEX		    ; 2 cycles
    BNE :-		; 3 cycles / 2 cycles
    DEY		    ; 2 cycles
    BNE :--		; 3 cycles / 2 cycles
    PLY       ; 4 cycles
    PLX       ; 4 cycles
    RTS		    ; 6 cycles
              ; 28 cycles [overhead] + (Y * (7 + (2 + (5 * X) - 1))) - 1 cycles [loop] = 157410 cycles (X = $9B, Y = $C9)
              ; 157410 cycles * 318 ns/cycle = 50.05638 milliseconds
.ENDPROC
.EXPORT TIME_DELAY_50MS