
_CXCreateCxObj          equ     -30
_CXCxBroker             equ     -36
_CXActivateCxObj        equ     -42
_CXDeleteCxObj          equ     -48
_CXDeleteCxObjAll       equ     -54
_CXCxObjType            equ     -60
_CXCxObjError           equ     -66
_CXClearCxObjError      equ     -72
_CXSetCxObjPri          equ     -78
_CXAttachCxObj          equ     -84
_CXEnqueueCxObj         equ     -90
_CXInsertCxObj          equ     -96
_CXRemoveCxObj          equ     -102
_CXFindBroker           equ     -108    ; * PRIVATE *
_CXSetTranslate         equ     -114
_CXSetFilter            equ     -120
_CXSetFilterIX          equ     -126
_CXParseIX              equ     -132
_CXCxMsgType            equ     -138
_CXCxMsgData            equ     -144
_CXCxMsgID              equ     -150
_CXDivertCxMsg          equ     -156
_CXRouteCxMsg           equ     -162
_CXDisposeCxMsg         equ     -168
_CXInvertKeyMap         equ     -174
_CXAddIEvents           equ     -180
_CXCopyBrokerList       equ     -186    ; * PRIVATE *
_CXFreeBrokerList       equ     -192    ; * PRIVATE *
_CXBrokerCommand        equ     -198    ; * PRIVATE *
_CXMatchIX              equ     -204

cx              MACRO
		IFD     FAR
		 move.l cxbase,a6
		ELSE
		 move.l cxbase(PC),a6
		ENDC
		jsr     _CX\1(a6)
		ENDM
		
*jEdit: :tabSize=8:indentSize=8:mode=assembly-m68k:
