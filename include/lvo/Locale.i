_LOClocalePrivate1	equ	-30
_LOCCloseCatalog	equ	-36
_LOCCloseLocale		equ	-42
_LOCConvToLower		equ	-48
_LOCConvToUpper		equ	-54
_LOCFormatDate		equ	-60
_LOCFormatString	equ	-66
_LOCGetCatalogStr	equ	-72
_LOCGetLocaleStr	equ	-78
_LOCIsAlNum		equ	-84
_LOCIsAlpha		equ	-90
_LOCIsCntrl		equ	-96
_LOCIsDigit		equ	-102
_LOCIsGraph		equ	-108
_LOCIsLower		equ	-114
_LOCIsPrint		equ	-120
_LOCIsPunct		equ	-126
_LOCIsSpace		equ	-132
_LOCIsUpper		equ	-138
_LOCIsXDigit		equ	-144
_LOCOpenCatalogA	equ	-150
_LOCOpenLocale		equ	-156
_LOCParseDate		equ	-162
_LOClocalePrivate2	equ	-168
_LOCStrConvert		equ	-174
_LOCStrnCmp		equ	-180
_LOClocalePrivate3	equ	-186
_LOClocalePrivate4	equ	-192
_LOClocalePrivate5	equ	-198
_LOClocalePrivate6	equ	-204
_LOClocalePrivate7	equ	-210
_LOClocalePrivate8	equ	-216

locale		MACRO
		IFD	FAR
		 move.l	localebase,a6
		ELSE
		 move.l	localebase(PC),a6
		ENDC
		jsr	_LOC\1(a6)
		ENDM
