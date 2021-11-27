
_TIMERAddTime		EQU	-42
_TIMERSubTime		EQU	-48
_TIMERCmpTime		EQU	-54
_TIMERReadEClock	EQU	-60
_TIMERGetSysTime	EQU	-66

timer		MACRO
		IFNC	"\0","q"
		  move.l timerbase(PC),a6
		ENDC
		jsr	_TIMER\1(a6)
		ENDM
