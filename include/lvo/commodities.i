
_CXCreateCxObj			EQU	-30
_CXCxBroker			EQU	-36
_CXActivateCxObj		EQU	-42
_CXDeleteCxObj			EQU	-48
_CXDeleteCxObjAll		EQU	-54
_CXCxObjType			EQU	-60
_CXCxObjError			EQU	-66
_CXClearCxObjError		EQU	-72
_CXSetCxObjPri			EQU	-78
_CXAttachCxObj			EQU	-84
_CXEnqueueCxObj			EQU	-90
_CXInsertCxObj			EQU	-96
_CXRemoveCxObj			EQU	-102
_CXFindBroker			EQU	-108	; * PRIVATE *
_CXSetTranslate			EQU	-114
_CXSetFilter			EQU	-120
_CXSetFilterIX			EQU	-126
_CXParseIX			EQU	-132
_CXCxMsgType			EQU	-138
_CXCxMsgData			EQU	-144
_CXCxMsgID			EQU	-150
_CXDivertCxMsg			EQU	-156
_CXRouteCxMsg			EQU	-162
_CXDisposeCxMsg			EQU	-168
_CXInvertKeyMap			EQU	-174
_CXAddIEvents			EQU	-180
_CXCopyBrokerList		EQU	-186	; * PRIVATE *
_CXFreeBrokerList		EQU	-192	; * PRIVATE *
_CXBrokerCommand		EQU	-198	; * PRIVATE *
_CXMatchIX			EQU	-204

cx		MACRO
		IFNC	"\0","q"
		 move.l	cxbase(PC),a6
		ENDC
		jsr	_CX\1(a6)
		ENDM
