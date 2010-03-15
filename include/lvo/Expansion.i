
_EXPAddConfigDev        equ -30
_EXPAddBootNode         equ -36
_EXPAllocBoardMem       equ -42
_EXPAllocConfigDev      equ -48
_EXPAllocExpansionMem   equ -54
_EXPConfigBoard         equ -60
_EXPConfigChain         equ -66
_EXPFindConfigDev       equ -72
_EXPFreeBoardMem        equ -78
_EXPFreeConfigDev       equ -84
_EXPFreeExpansionMem    equ -90
_EXPReadExpansionByte   equ -96
_EXPReadExpansionRom    equ -102
_EXPRemConfigDev        equ -108
_EXPWriteExpansionByte  equ -114
_EXPObtainConfigBinding equ -120
_EXPReleaseConfigBinding        equ -126
_EXPSetCurrentBinding   equ -132
_EXPGetCurrentBinding   equ -138
_EXPMakeDosNode         equ -144
_EXPAddDosNode          equ -150
_EXPexpansionPrivate1   equ -156
_EXPexpansionPrivate2   equ -162

expans          MACRO
		IFNC    "\0","D"
		 IFD     FAR
		  move.l expbase,a6
		 ELSE
		  move.l expbase(PC),a6
		 ENDC
		ENDC
		jsr     _EXP\1(a6)
		ENDM
