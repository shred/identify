
_IDNTIdExpansion	EQU	-30
_IDNTIdHardware		EQU	-36
_IDNTIdAlert		EQU	-42
_IDNTIdFunction		EQU	-48
_IDNTIdHardwareNum	EQU	-54
_IDNTIdHardwareUpdate	EQU	-60
_IDNTIdFormatString	EQU	-66
_IDNTIdEstimateFormatSize EQU	-72

idfy		MACRO
		IFNC	"\0","q"
		 move.l	identifybase(PC),a6
		ENDC
		jsr	_IDNT\1(a6)
		ENDM
