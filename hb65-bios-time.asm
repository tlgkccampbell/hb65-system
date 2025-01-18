; hb65-bios-time.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS time routines"

.INCLUDE    "hb65-system.inc"

; Time routines
.SEGMENT "BIOS"

; TIME_DELAY_50US procedure
; Modifies: X, flags
;
; Delays for approximately 50 microseconds (assuming a 3.15 MHz clock).
.PROC TIME_DELAY_50US
                ; 6 cycles (JSR)
    LDX #$1D	; 2 cycles
  : DEX		    ; 2 cycles
    BNE :-		; 3 cycles / 2 cycles
    RTS		    ; 6 cycles
                ; 14 cycles [overhead] + (5 * X) - 1 cycles [loop] = 158 cycles (X = $1D)
                ; 158 cycles * 318 ns/cycle = 50,244 nanoseconds = 50.244 microseconds
.ENDPROC
.EXPORT TIME_DELAY_50US

; TIME_DELAY_1MS procedure
; Modifies: X, Y, flags
;
; Delays for approximately 1 millisecond (assuming a 3.15 MHz clock).
.PROC TIME_DELAY_1MS
                ; 6 cycles (JSR)
    LDY #$04	; 2 cycles
  : LDX #$9B	; 2 cycles
  : DEX		    ; 2 cycles
    BNE :-		; 3 cycles / 2 cycles
    DEY		    ; 2 cycles
    BNE :--		; 3 cycles / 2 cycles
    RTS		    ; 6 cycles
                ; 14 cycles [overhead] + (Y * (7 + (2 + (5 * X) - 1))) - 1 cycles [loop] = 3145 cycles (X = $9B, Y = $04)
                ; 3145 cycles * 318 ns/cycle = 1.00011 milliseconds
.ENDPROC
.EXPORT TIME_DELAY_1MS

; TIME_DELAY_50MS procedure
; Modifies: X, Y, flags
;
; Delays for approximately 50 milliseconds (assuming a 3.15 MHz clock).
.PROC TIME_DELAY_50MS
                ; 6 cycles (JSR)
    LDY #$C8	; 2 cycles
  : LDX #$9B	; 2 cycles
  : DEX		    ; 2 cycles
    BNE :-		; 3 cycles / 2 cycles
    DEY		    ; 2 cycles
    BNE :--		; 3 cycles / 2 cycles
    RTS		    ; 6 cycles
                ; 14 cycles [overhead] + (Y * (7 + (2 + (5 * X) - 1))) - 1 cycles [loop] = 3145 cycles (X = $9B, Y = $04)
                ; 3145 cycles * 318 ns/cycle = 1.00011 milliseconds
.ENDPROC
.EXPORT TIME_DELAY_50MS