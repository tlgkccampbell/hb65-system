.IFNDEF _INCLUDE_CONFIG_HELPERS_
_INCLUDE_CONFIG_HELPERS_ = 1

; DECLARE_RDEV macro
; When used in the system configuration file hb65-config.inc, this macro is used
; to declare which register-only devices are present. If label is empty, no device
; is associated with the specified device index; otherwise, label is defined as
; the appropriate value from the DEVICE_LOCATIONS enum.
.MACRO DECLARE_RDEV ix, label
    .IFNBLANK label
        label = DEVICE_LOCATIONS::.IDENT(.SPRINTF("RDEV%s", .STRING(ix)))
    .ENDIF
.ENDMACRO

; DECLARE_PDEV macro
; When used in the system configuration file hb65-config.inc, this macro is used
; to declare which peripheral devices are present. If label is empty, no device
; is associated with the specified device index; otherwise, label is defined as
; the appropriate value from the DEVICE_LOCATIONS enum.
.MACRO DECLARE_PDEV ix, label
    .IFNBLANK label
        label = DEVICE_LOCATIONS::.IDENT(.SPRINTF("PDEV%s", .STRING(ix)))
    .ENDIF
.ENDMACRO

; DEVICE_LOCATIONS enum
; A set of constant values that uniquely identify each of the HB65 Microcomputer
; System's register-only devices (RDEV0-1) and peripheral devices (PDEV0-3).
.ENUM DEVICE_LOCATIONS
    RDEV0
    RDEV1
    PDEV0
    PDEV1
    PDEV2
    PDEV3
    PDEV4
.ENDENUM

; SYSTEM_CARDS enum
; A set of constant values that represent the known configurations of system card
; that can be attached to an HB65 Microcomputer System.
.ENUM SYSTEM_CARDS
    TYPE_A
.ENDENUM

.ENDIF