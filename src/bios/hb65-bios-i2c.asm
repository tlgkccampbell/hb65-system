; hb65-bios-i2c.asm
.FILEOPT    author,     "Cole Campbell"
.FILEOPT    comment,    "BIOS I2C interface routines"

.INCLUDE    "../hb65-system.inc"

; I2C state
.SEGMENT "SYSZP": zeropage

_I2C_DATA:  .RES 1

; I2C routines
.SEGMENT "BIOS"

; I2C_PROC_START macro
; Modifies: n/a
;
; Declares the start of an I2C API procedure. This macro creates two versions of the procedure:
; a public version called `name` and a private version called `_name`. Only the former is exported.
; The public procedure wraps the private procedure in code that enables System Context Mode and
; disables Alternative Function mode.
; Must be paired with a call to I2C_PROC_END.
.MACRO I2C_PROC_START name
.PROC name
    SFMODE_PUSH_AND_SET (1 << DECODER_DCR_BIT::SYSCTX)
        JSR .IDENT(.CONCAT("_", .STRING(name)))
    SFMODE_POP
    RTS
.ENDPROC
.EXPORT name
.PROC .IDENT(.CONCAT("_", .STRING(name)))
.ENDMAC

; I2C_PROC_END macro
; Modifies: n/a
;
; Declares the end of an I2C API procedure.
.MACRO I2C_PROC_END
.ENDPROC
.ENDMAC

; I2C_DAT_UP macro
; Modifies: A
;
; Pulls the I2C data line high.
.MACRO I2C_DAT_UP
    LDA #$80
    TRB SYSTEM_VIA_DDRA
.ENDMAC

; I2C_DAT_DN macro
; Modifies: A
;
; Pulls the I2C data line low.
.MACRO I2C_DAT_DN
    LDA #$80
    TSB SYSTEM_VIA_DDRA
.ENDMAC

; I2C_CLK_UP macro
; Modifies: A
;
; Pulls the I2C clock line high.
.MACRO I2C_CLK_UP
    LDA #$01
    TRB SYSTEM_VIA_DDRA
.ENDMAC

; I2C_CLK_DN macro
; Modifies: A
;
; Pulls the I2C clock line down.
.MACRO I2C_CLK_DN
    LDA #$01
    TSB SYSTEM_VIA_DDRA
.ENDMAC

; I2C_START procedure
; Modifies: A
;
; Sends an I2C start sequence.
I2C_PROC_START I2C_START
    I2C_DAT_UP
    I2C_CLK_UP
    I2C_DAT_DN
    I2C_CLK_DN
    RTS
I2C_PROC_END

; I2C_STOP procedure
; Modifies: A
;
; Sends an I2C stop sequence.
I2C_PROC_START I2C_STOP
    I2C_DAT_DN
    I2C_CLK_UP
    I2C_DAT_UP
    I2C_CLK_DN
    RTS
I2C_PROC_END

; I2C_ACK procedure
; Modifies: A
;
; Sends an I2C acknowledgement signal.
I2C_PROC_START I2C_ACK
    I2C_DAT_DN
  SEND:
    I2C_CLK_UP
    INC SYSTEM_VIA_DDRA
    I2C_DAT_UP
    RTS
I2C_PROC_END

; I2C_NAK procedure
; Modifies: A
; 
; Sends an I2C non-acknowledgement signal.
I2C_PROC_START I2C_NAK
    I2C_DAT_UP
    BRA _I2C_ACK::SEND
I2C_PROC_END

; I2C_IS_ACK procedure
; Modifies: A
;
; Determines whether the last byte was acknowledged by its receiver.
; On return, N=0 means ACK, and N=1 means NAK.
I2C_PROC_START I2C_IS_ACK
    I2C_DAT_UP
    I2C_CLK_UP
    BIT SYSTEM_VIA_IRA
    TSB SYSTEM_VIA_DDRA
    TXA
    RTS
I2C_PROC_END

; I2C_INIT procedure
; Modifies: A
;
; Initializes the I2C module.
I2C_PROC_START I2C_INIT
    LDA #$81
    TSB SYSTEM_VIA_DDRA
    TRB SYSTEM_VIA_ORA
    RTS
I2C_PROC_END

; I2C_CLR procedure
; Modifies: A, X
; 
; Clears any unwanted I2C transactions that are currently in progress.
I2C_PROC_START I2C_CLR
    JSR _I2C_STOP
    JSR _I2C_START
    I2C_DAT_UP
    LDX #$09
  : DEC SYSTEM_VIA_DDRA
    INC SYSTEM_VIA_DDRA
    DEX
    BNE :-
    JSR _I2C_START
    JMP _I2C_STOP
I2C_PROC_END

; I2C_SEND_BYTE procedure
; Modifies: A, X
;
; Writes the value in A to the I2C bus.
I2C_PROC_START I2C_SEND_BYTE
    STA _I2C_DATA
    LDA #$80
    LDX #$08
  : TRB SYSTEM_VIA_DDRA
    ASL _I2C_DATA
    BCS :+
    TSB SYSTEM_VIA_DDRA
  : DEC SYSTEM_VIA_DDRA
    INC SYSTEM_VIA_DDRA
    DEX
    BNE :--
    JMP _I2C_IS_ACK
I2C_PROC_END

; I2C_READ_BYTE procedure
; Modifies: A, X
;
; Reads a byte from the I2C bus into X.
I2C_PROC_START I2C_READ_BYTE
    I2C_DAT_UP
    LDX #$08
  : DEC SYSTEM_VIA_DDRA
    ASL _I2C_DATA
    BIT SYSTEM_VIA_IRA
    BPL :+
    INC _I2C_DATA
  : INC SYSTEM_VIA_DDRA
    DEX
    BNE :--
    LDX _I2C_DATA
    JMP _I2C_IS_ACK
I2C_PROC_END