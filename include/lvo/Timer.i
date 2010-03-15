
_TIMERAddTime           EQU     -42
_TIMERSubTime           EQU     -48
_TIMERCmpTime           EQU     -54
_TIMERReadEClock        EQU     -60
_TIMERGetSysTime        EQU     -66

timer           MACRO
		IFD     FAR
		 move.l timerbase,a6
		ELSE
		 move.l timerbase(PC),a6
		ENDC
		jsr     _TIMER\1(a6)
		ENDM

*jEdit: :tabSize=8:indentSize=8:mode=assembly-m68k:
