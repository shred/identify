
_EXPAddConfigDev		EQU	-30
_EXPAddBootNode			EQU	-36
_EXPAllocBoardMem		EQU	-42
_EXPAllocConfigDev		EQU	-48
_EXPAllocExpansionMem		EQU	-54
_EXPConfigBoard			EQU	-60
_EXPConfigChain			EQU	-66
_EXPFindConfigDev		EQU	-72
_EXPFreeBoardMem		EQU	-78
_EXPFreeConfigDev		EQU	-84
_EXPFreeExpansionMem		EQU	-90
_EXPReadExpansionByte		EQU	-96
_EXPReadExpansionRom		EQU	-102
_EXPRemConfigDev		EQU	-108
_EXPWriteExpansionByte		EQU	-114
_EXPObtainConfigBinding		EQU	-120
_EXPReleaseConfigBinding	EQU	-126
_EXPSetCurrentBinding		EQU	-132
_EXPGetCurrentBinding		EQU	-138
_EXPMakeDosNode			EQU	-144
_EXPAddDosNode			EQU	-150
_EXPexpansionPrivate1		EQU	-156
_EXPexpansionPrivate2		EQU	-162

expans		MACRO
		IFNC	"\0","q"
		  move.l expbase(PC),a6
		ENDC
		jsr	_EXP\1(a6)
		ENDM
