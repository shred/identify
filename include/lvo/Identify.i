
_IDNTIdExpansion        equ     -30
_IDNTIdHardware         equ     -36
_IDNTIdAlert            equ     -42
_IDNTIdFunction         equ     -48
_IDNTIdHardwareNum      EQU     -54
_IDNTIdHardwareUpdate   EQU     -60
_IDNTIdFormatString     EQU     -66
_IDNTIdEstimateFormatSize EQU   -72

idfy            MACRO
		IFD     FAR
		 move.l identifybase,a6
		ELSE
		 move.l identifybase(PC),a6
		ENDC
		jsr     _IDNT\1(a6)
		ENDM

