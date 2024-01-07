
_MMUAllocAligned		EQU	-$01e
_MMUGetMapping			EQU	-$024
_MMUReleaseMapping		EQU	-$02a
_MMUGetPageSize			EQU	-$030
_MMUGetMMUType			EQU	-$036
_MMULockMMUContext		EQU	-$048
_MMUUnlockMMUContext		EQU	-$04e
_MMUSetPropertiesA		EQU	-$054
_MMUGetPropertiesA		EQU	-$05a
_MMURebuildTree			EQU	-$060
_MMUSetPagePropertiesA		EQU	-$066
_MMUGetPagePropertiesA		EQU	-$06c
_MMUCreateMMUContextA		EQU	-$072
_MMUDeleteMMUContext		EQU	-$078
_MMUAllocLineVec		EQU	-$084
_MMUPhysicalPageLocation	EQU	-$08a
_MMUSuperContext		EQU	-$090
_MMUDefaultContext		EQU	-$096
_MMUEnterMMUContext		EQU	-$09c
_MMULeaveMMUContext		EQU	-$0a2
_MMUAddContextHookA		EQU	-$0a8
_MMURemContextHook		EQU	-$0ae
_MMUAddMessageHookA		EQU	-$0b4
_MMURemMessageHook		EQU	-$0ba
_MMUActivateException		EQU	-$0c0
_MMUDeactivateException	 	EQU	-$0c6
_MMUAttemptLockMMUContext	EQU	-$0cc
_MMULockContextList		EQU	-$0d2
_MMUUnlockContextList		EQU	-$0d8
_MMUAttemptLockContextList	EQU	-$0de
_MMUSetPropertyList		EQU	-$0e4
_MMUTouchPropertyList		EQU	-$0ea
_MMUCurrentContext		EQU	-$0f0
_MMUDMAInitiate			EQU	-$0f6
_MMUDMATerminate		EQU	-$0fc
_MMUPhysicalLocation		EQU	-$102
_MMURemapSize			EQU	-$108
_MMUWithoutMMU			EQU	-$10e
_MMUSetBusError			EQU	-$114
_MMUGetMMUContextData		EQU	-$11a
_MMUSetMMUContextDataA		EQU	-$120
_MMUNewMapping			EQU	-$126
_MMUCopyMapping			EQU	-$12c
_MMUDupMapping			EQU	-$132
_MMUCopyContextRegion		EQU	-$138
_MMUSetPropertiesMapping	EQU	-$13e
_MMUSetMappingPropertiesA	EQU	-$144
_MMUGetMappingPropertiesA	EQU	-$14a
_MMUBuildIndirect		EQU	-$150
_MMUSetIndirect			EQU	-$156
_MMUGetIndirect			EQU	-$15c
_MMURebuildTreesA		EQU	-$168
_MMURunOldConfig		EQU	-$16e
_MMUSetIndirectArray		EQU	-$174
_MMUGetPageUsedModified		EQU	-$17a
_MMUMapWindow			EQU	-$1a4
_MMUCreateContextWindowA	EQU	-$1aa
_MMUReleaseContextWindow	EQU	-$1b0
_MMURefreshContextWindow	EQU	-$1b6
_MMUMapWindowCached		EQU	-$1bc
_MMULayoutContextWindow		EQU	-$1c2
_MMULogicalLocation		EQU	-$1ce

mmu		MACRO
		IFNC	"\0","q"
		 move.l mmubase(PC),a6
		ENDC
		jsr	_MMU\1(a6)
		ENDM
