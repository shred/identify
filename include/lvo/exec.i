
_EXECSupervisor			EQU	-30
_EXECExitIntr			EQU	-36
_EXECSchedule			EQU	-42
_EXECReSchedule			EQU	-48
_EXECSwitch			EQU	-54
_EXECDispatch			EQU	-60
_EXECException			EQU	-66
_EXECInitCode			EQU	-72
_EXECInitStruct			EQU	-78
_EXECMakeLibrary		EQU	-84
_EXECMakeFunctions		EQU	-90
_EXECFindResident		EQU	-96
_EXECInitResident		EQU	-102
_EXECAlert			EQU	-108
_EXECDebug			EQU	-114
_EXECDisable			EQU	-120
_EXECEnable			EQU	-126
_EXECForbid			EQU	-132
_EXECPermit			EQU	-138
_EXECSetSR			EQU	-144
_EXECSuperState			EQU	-150
_EXECUserState			EQU	-156
_EXECSetIntVector		EQU	-162
_EXECAddIntServer		EQU	-168
_EXECRemIntServer		EQU	-174
_EXECCause			EQU	-180
_EXECAllocate			EQU	-186
_EXECDeallocate			EQU	-192
_EXECAllocMem			EQU	-198
_EXECAllocAbs			EQU	-204
_EXECFreeMem			EQU	-210
_EXECAvailMem			EQU	-216
_EXECAllocEntry			EQU	-222
_EXECFreeEntry			EQU	-228
_EXECInsert			EQU	-234
_EXECAddHead			EQU	-240
_EXECAddTail			EQU	-246
_EXECRemove			EQU	-252
_EXECRemHead			EQU	-258
_EXECRemTail			EQU	-264
_EXECEnqueue			EQU	-270
_EXECFindName			EQU	-276
_EXECAddTask			EQU	-282
_EXECRemTask			EQU	-288
_EXECFindTask			EQU	-294
_EXECSetTaskPri			EQU	-300
_EXECSetSignal			EQU	-306
_EXECSetExcept			EQU	-312
_EXECWait			EQU	-318
_EXECSignal			EQU	-324
_EXECAllocSignal		EQU	-330
_EXECFreeSignal			EQU	-336
_EXECAllocTrap			EQU	-342
_EXECFreeTrap			EQU	-348
_EXECAddPort			EQU	-354
_EXECRemPort			EQU	-360
_EXECPutMsg			EQU	-366
_EXECGetMsg			EQU	-372
_EXECReplyMsg			EQU	-378
_EXECWaitPort			EQU	-384
_EXECFindPort			EQU	-390
_EXECAddLibrary			EQU	-396
_EXECRemLibrary			EQU	-402
_EXECOldOpenLibrary		EQU	-408
_EXECCloseLibrary		EQU	-414
_EXECSetFunction		EQU	-420
_EXECSumLibrary			EQU	-426
_EXECAddDevice			EQU	-432
_EXECRemDevice			EQU	-438
_EXECOpenDevice			EQU	-444
_EXECCloseDevice		EQU	-450
_EXECDoIO			EQU	-456
_EXECSendIO			EQU	-462
_EXECCheckIO			EQU	-468
_EXECWaitIO			EQU	-474
_EXECAbortIO			EQU	-480
_EXECAddResource		EQU	-486
_EXECRemResource		EQU	-492
_EXECOpenResource		EQU	-498
_EXECRawIOInit			EQU	-504
_EXECRawMayGetChar		EQU	-510
_EXECRawPutChar			EQU	-516
_EXECRawDoFmt			EQU	-522
_EXECGetCC			EQU	-528
_EXECTypeOfMem			EQU	-534
_EXECProcure			EQU	-540
_EXECVacate			EQU	-546
_EXECOpenLibrary		EQU	-552
_EXECInitSemaphore		EQU	-558	;Kick 1.2 (V33+)
_EXECObtainSemaphore		EQU	-564
_EXECReleaseSemaphore		EQU	-570
_EXECAttemptSemaphore		EQU	-576
_EXECObtainSemaphoreList 	EQU	-582
_EXECReleaseSemaphoreList 	EQU	-588
_EXECFindSemaphore		EQU	-594
_EXECAddSemaphore		EQU	-600
_EXECRemSemaphore		EQU	-606
_EXECSumKickData		EQU	-612
_EXECAddMemList			EQU	-618
_EXECCopyMem			EQU	-624
_EXECCopyMemQuick		EQU	-630
_EXECCacheClearU		EQU	-636	;Kick 2.0 (V36+)
_EXECCacheClearE		EQU	-642
_EXECCacheControl		EQU	-648
_EXECCreateIORequest		EQU	-654
_EXECDeleteIORequest		EQU	-660
_EXECCreateMsgPort		EQU	-666
_EXECDeleteMsgPort		EQU	-672
_EXECObtainSemaphoreShared 	EQU	-678
_EXECAllocVec			EQU	-684
_EXECFreeVec			EQU	-690
_EXECCreatePool			EQU	-696	;Kick 3.0 (V39+)
_EXECDeletePool			EQU	-702
_EXECAllocPooled		EQU	-708
_EXECFreePooled			EQU	-714
_EXECAttemptSemaphoreShared 	EQU	-720
_EXECColdReboot			EQU	-726
_EXECStackSwap			EQU	-732
_EXECChildFree			EQU	-738
_EXECChildOrphan		EQU	-744
_EXECChildStatus		EQU	-750
_EXECChildWait			EQU	-756
_EXECCachePreDMA		EQU	-762
_EXECCachePostDMA		EQU	-768
_EXECAddMemHandler		EQU	-774
_EXECRemMemHandler		EQU	-780
_EXECObtainQuickVector		EQU	-786

exec		MACRO
		IFNC	"\0","q"
		 IFD	execbase
		  move.l execbase(PC),a6
		 ELSE
		  move.l 4.w,a6
		 ENDC
		ENDC
		jsr	_EXEC\1(a6)
		ENDM
