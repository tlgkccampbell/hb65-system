; hb65-basic-env.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "Enhanced BASIC operating environment for the HB65 Microcomputer System"

.INCLUDE    "hb65-system.inc"

.IMPORT     UART_GETCH, UART_PUTCH
.IMPORTZP   LAB_WARM, NmiBase, IrqBase
.IMPORT     LAB_COLD, V_INPT, V_OUTP, VEC_IN

; EhBASIC operating environment
.SEGMENT "CODE"

; EhBASIC configuration
.EXPORTZP   EHBASIC_ZP_START    = $00
.EXPORTZP   EHBASIC_ZP_MAX      = $DF

; EhBASIC I/O routines
EHBASIC_GETCH       = UART_GETCH
EHBASIC_PUTCH       = UART_PUTCH

; EhBASIC vector table
LAB_vec:
    .WORD   EHBASIC_GETCH
    .WORD   EHBASIC_PUTCH
    .WORD   EHBASIC_LOAD
    .WORD   EHBASIC_SAVE
END_CODE:

; EhBASIC sign-on message
LAB_mess:
    .BYTE   $0D, $0A, "6502 EhBASIC [C]old/[W]arm ?", $00

; EHBASIC_INIT procedure
; Modifies: flags, A, 
;
; Initializes the EhBASIC environment, copying necessary data into RAM
; and prompting the user to perform either a cold or warm start. 
; Performs JMP on exit.
.PROC EHBASIC_INIT
    ; initialize the address decoder
    STZ     DECODER_ALR
    LDA     #$40
    STA     DECODER_ZPLR
    LDA     #$11
    STA     DECODER_WRBR
    ; set up vectors and interrupt code, copy them to page 2
    LDY     #END_CODE - LAB_vec ; set index/count
LAB_stlp:
    LDA     LAB_vec - 1, Y      ; get byte from interrupt code
    STA     VEC_IN - 1, Y       ; save to RAM
    DEY                         ; decrement index/count
    BNE     LAB_stlp            ; loop if more to do

    ; now do the signon message, Y = $00 here
.IFNDEF EHBASIC_SKIP_BOOT_PROMPT
LAB_signon:
    LDA     LAB_mess, Y         ; get byte from sign on message
    BEQ     LAB_nokey           ; exit loop if done

    JSR     V_OUTP              ; output character
    INY                         ; increment index
    BNE     LAB_signon          ; loop, branch always
LAB_nokey:
    JSR     V_INPT              ; call scan input device
    BCC     LAB_nokey           ; loop if no key
.ELSE
    JSR     EHBASIC_BOOT_TYPE   ; cold or warm boot?
.ENDIF
    AND     #$DF                ; mask xx0x xxxx, ensure upper case
    CMP      #'W'               ; compare with [W]arm start
    BEQ     LAB_dowarm          ; branch if [W]arm start

    CMP     #'C'                ; compare with [C]old start
    BNE     EHBASIC_INIT        ; loop if not [C]old start

    JMP     LAB_COLD            ; do EhBASIC cold start
LAB_dowarm:
    JMP     LAB_WARM            ; do EhBASIC warm start
.ENDPROC
.EXPORT EHBASIC_INIT

; EHBASIC_BOOT_TYPE procedure
; Modifies: flags, A
;
; Determines whether EhBASIC should perform a cold or warm boot
; by loading the accumulator with either 'C' or 'W'.
.PROC EHBASIC_BOOT_TYPE
    LDA     #'C'
    RTS
.ENDPROC
.EXPORT EHBASIC_BOOT_TYPE

; EHBASIC_SAVE procedure
; Modifies: n/a
;
; Not yet implemented.
.PROC EHBASIC_SAVE
    RTS
.ENDPROC
.EXPORT EHBASIC_SAVE

; EHBASIC_LOAD procedure
; Modifies: n/a
;
; Not yet implemented.
.PROC EHBASIC_LOAD
    RTS
.ENDPROC
.EXPORT EHBASIC_LOAD

; EHBASIC_IRQ_HANDLER procedure
; Modifies: n/a
;
; Sets EhBASIC's IRQ happened flag, triggering any registered BASIC
; interrupt handler. Performs RTI on exit.
.PROC EHBASIC_IRQ_HANDLER
    PHA                         ; save A
    LDA     IrqBase             ; get the IRQ flag byte
    LSR                         ; shift the set b7 to b6, and on down ...
    ORA     IrqBase             ; OR the original back in
    STA     IrqBase             ; save the new IRQ flag byte
    PLA                         ; restore A
    RTI
.ENDPROC
.EXPORT EHBASIC_IRQ_HANDLER

; EHBASIC_NMI_HANDLER procedure
; Modifies: n/a
;
; Sets EhBASIC's NMI happened flag, triggering any registered BASIC
; interrupt handler. Performs RTI on exit.
.PROC EHBASIC_NMI_HANDLER
    PHA                         ; save A
    LDA     NmiBase             ; get the IRQ flag byte
    LSR                         ; shift the set b7 to b6, and on down ...
    ORA     NmiBase             ; OR the original back in
    STA     NmiBase             ; save the new IRQ flag byte
    PLA                         ; restore A
    RTI
.ENDPROC
.EXPORT EHBASIC_NMI_HANDLER
