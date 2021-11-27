
_RXSCreateArgstring	EQU	-126
_RXSDeleteArgstring	EQU	-132
_RXSLengthArgstring	EQU	-138
_RXSCreateRexxMsg	EQU	-144
_RXSDeleteRexxMsg	EQU	-150
_RXSClearRexxMsg	EQU	-156
_RXSFillRexxMsg		EQU	-162
_RXSIsRexxMsg		EQU	-168
_RXSLockRexxBase	EQU	-450
_RXSUnlockRexxBase	EQU	-456

rexxsys		MACRO
		IFNC	"\0","q"
		 move.l rexxsyslibbase,a6
		ENDC
		jsr	_RXS\1(a6)
		ENDM
