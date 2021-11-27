
_UTILSFindTagItem		EQU	-30	;Release 2.0 (36)
_UTILSGetTagData		EQU	-36
_UTILSPackBoolTags		EQU	-42
_UTILSNextTagItem		EQU	-48
_UTILSFilterTagChanges		EQU	-54
_UTILSMapTags			EQU	-60
_UTILSAllocateTagItems		EQU	-66
_UTILSCloneTagItems		EQU	-72
_UTILSFreeTagItems		EQU	-78
_UTILSRefreshTagItemClones	EQU	-84
_UTILSTagInArray		EQU	-90
_UTILSFilterTagItems		EQU	-96
_UTILSCallHookPkt		EQU	-102
_UTILSAmiga2Date		EQU	-120
_UTILSDate2Amiga		EQU	-126
_UTILSCheckDate			EQU	-132
_UTILSSMult32			EQU	-138
_UTILSUMult32			EQU	-144
_UTILSSDivMod32			EQU	-150
_UTILSUDivMod32			EQU	-156
_UTILSStricmp			EQU	-162	; Release 2.04 (37)
_UTILSStrnicmp			EQU	-168
_UTILSToUpper			EQU	-174
_UTILSToLower			EQU	-180
_UTILSApplyTagChanges		EQU	-186	; Release 3.0 (39)
_UTILSSMult64			EQU	-198
_UTILSUMult64			EQU	-204
_UTILSPackStructureTags		EQU	-210
_UTILSUnpackStructureTags	EQU	-216
_UTILSAddNamedObject		EQU	-222
_UTILSAllocNamedObjectA		EQU	-228
_UTILSAttemptRemNamedObject	EQU	-234
_UTILSFindNamedObject		EQU	-240
_UTILSFreeNamedObject		EQU	-246
_UTILSNamedObjectName		EQU	-252
_UTILSReleaseNamedObject	EQU	-258
_UTILSRemNamedObject		EQU	-264
_UTILSGetUniqueID		EQU	-270

utils		MACRO
		IFNC	"\0","q"
		  move.l utilsbase(PC),a6
		ENDC
		jsr	_UTILS\1(a6)
		ENDM
