
_EXECSupervisor         equ     -30
_EXECExitIntr           equ     -36
_EXECSchedule           equ     -42
_EXECReSchedule         equ     -48
_EXECSwitch             equ     -54
_EXECDispatch           equ     -60
_EXECException          equ     -66
_EXECInitCode           equ     -72
_EXECInitStruct         equ     -78
_EXECMakeLibrary        equ     -84
_EXECMakeFunctions      equ     -90
_EXECFindResident       equ     -96
_EXECInitResident       equ     -102
_EXECAlert              equ     -108
_EXECDebug              equ     -114
_EXECDisable            equ     -120
_EXECEnable             equ     -126
_EXECForbid             equ     -132
_EXECPermit             equ     -138
_EXECSetSR              equ     -144
_EXECSuperState         equ     -150
_EXECUserState          equ     -156
_EXECSetIntVector       equ     -162
_EXECAddIntServer       equ     -168
_EXECRemIntServer       equ     -174
_EXECCause              equ     -180
_EXECAllocate           equ     -186
_EXECDeallocate         equ     -192
_EXECAllocMem           equ     -198
_EXECAllocAbs           equ     -204
_EXECFreeMem            equ     -210
_EXECAvailMem           equ     -216
_EXECAllocEntry         equ     -222
_EXECFreeEntry          equ     -228
_EXECInsert             equ     -234
_EXECAddHead            equ     -240
_EXECAddTail            equ     -246
_EXECRemove             equ     -252
_EXECRemHead            equ     -258
_EXECRemTail            equ     -264
_EXECEnqueue            equ     -270
_EXECFindName           equ     -276
_EXECAddTask            equ     -282
_EXECRemTask            equ     -288
_EXECFindTask           equ     -294
_EXECSetTaskPri         equ     -300
_EXECSetSignal          equ     -306
_EXECSetExcept          equ     -312
_EXECWait               equ     -318
_EXECSignal             equ     -324
_EXECAllocSignal        equ     -330
_EXECFreeSignal         equ     -336
_EXECAllocTrap          equ     -342
_EXECFreeTrap           equ     -348
_EXECAddPort            equ     -354
_EXECRemPort            equ     -360
_EXECPutMsg             equ     -366
_EXECGetMsg             equ     -372
_EXECReplyMsg           equ     -378
_EXECWaitPort           equ     -384
_EXECFindPort           equ     -390
_EXECAddLibrary         equ     -396
_EXECRemLibrary         equ     -402
_EXECOldOpenLibrary     equ     -408
_EXECCloseLibrary       equ     -414
_EXECSetFunction        equ     -420
_EXECSumLibrary         equ     -426
_EXECAddDevice          equ     -432
_EXECRemDevice          equ     -438
_EXECOpenDevice         equ     -444
_EXECCloseDevice        equ     -450
_EXECDoIO               equ     -456
_EXECSendIO             equ     -462
_EXECCheckIO            equ     -468
_EXECWaitIO             equ     -474
_EXECAbortIO            equ     -480
_EXECAddResource        equ     -486
_EXECRemResource        equ     -492
_EXECOpenResource       equ     -498
_EXECRawIOInit          equ     -504
_EXECRawMayGetChar      equ     -510
_EXECRawPutChar         equ     -516
_EXECRawDoFmt           equ     -522
_EXECGetCC              equ     -528
_EXECTypeOfMem          equ     -534
_EXECProcure            equ     -540
_EXECVacate             equ     -546
_EXECOpenLibrary        equ     -552
_EXECInitSemaphore      EQU     -558    ;Kick 1.2 (V33+)
_EXECObtainSemaphore    EQU     -564
_EXECReleaseSemaphore   equ     -570
_EXECAttemptSemaphore   equ     -576
_EXECObtainSemaphoreList equ    -582
_EXECReleaseSemaphoreList equ   -588
_EXECFindSemaphore      equ     -594
_EXECAddSemaphore       equ     -600
_EXECRemSemaphore       equ     -606
_EXECSumKickData        equ     -612
_EXECAddMemList         equ     -618
_EXECCopyMem            equ     -624
_EXECCopyMemQuick       equ     -630
_EXECCacheClearU        EQU     -636    ;Kick 2.0 (V36+)
_EXECCacheClearE        equ     -642
_EXECCacheControl       equ     -648
_EXECCreateIORequest    equ     -654
_EXECDeleteIORequest    equ     -660
_EXECCreateMsgPort      equ     -666
_EXECDeleteMsgPort      equ     -672
_EXECObtainSemaphoreShared equ  -678
_EXECAllocVec           equ     -684
_EXECFreeVec            equ     -690
_EXECCreatePool         EQU     -696    ;Kick 3.0 (V39+)
_EXECDeletePool         equ     -702
_EXECAllocPooled        equ     -708
_EXECFreePooled         equ     -714
_EXECAttemptSemaphoreShared equ -720
_EXECColdReboot         equ     -726
_EXECStackSwap          equ     -732
_EXECChildFree          equ     -738
_EXECChildOrphan        equ     -744
_EXECChildStatus        equ     -750
_EXECChildWait          equ     -756
_EXECCachePreDMA        equ     -762
_EXECCachePostDMA       equ     -768
_EXECAddMemHandler      equ     -774
_EXECRemMemHandler      equ     -780
_EXECObtainQuickVector  equ     -786

exec            MACRO
		IFNC    "\0","D"
		 IFD     execbase
		  IFD     FAR
		   move.l execbase,a6
		  ELSE
		   move.l (execbase,PC),a6
		  ENDC
		 ELSE
		  move.l  4.w,a6
		 ENDC
		ENDC
		jsr     _EXEC\1(a6)
		ENDM
		
*jEdit: :tabSize=8:indentSize=8:mode=assembly-m68k:
