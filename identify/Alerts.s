*
* identify.library
*
* Copyright (C) 2010 Richard "Shred" Körber
*   http://identify.shredzone.org
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License / GNU Lesser
* General Public License as published by the Free Software Foundation,
* either version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*

ID_ALERTS       SET     -1
CATCOMP_NUMBERS SET     1

		INCLUDE exec/alerts.i
		INCLUDE exec/memory.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/utility.i

		INCLUDE libraries/identify.i

		INCLUDE Refs.i
		INCLUDE Alerts.i
		INCLUDE Locale.i

		IFD     _MAKE_68020
		MACHINE 68020
		ENDC

		SECTION text,CODE

*---------------------------------------------------------------*
* strbase definieren                                            *
*>                                                              *
	;-- Wichtig! MUSS hier stehen, damit die Datensektion
	;   an der richtigen Stelle angelegt wird, und die
	;   Strings durchgehend positive Referenzen bekommen
		SAVE
		SECTION strings,DATA
strbase         ds.w    0                       ;String-Base
		RESTORE
*<

*---------------------------------------------------------------*
*       == FUNKTIONEN ==                                        *
*                                                               *
*-------------------------------------------------------*
* Name:         IdAlert                                 *
*                                                       *
* Funktion:     Holt Beschreibung zum Alert             *
*                                                       *
* Parameter:    -» D0.l Alert-ID                        *
*               -» A0.l ^Tags                           *
*               «- D0.l Error-Code                      *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 14:48:03)            *
*                                                       *
		clrfo
ale_DeadStr     fo.l    1       ;^String für Deadend/Recovery
ale_SubsysStr   fo.l    1       ;^String für Subsystem
ale_GeneralStr  fo.l    1       ;^String für General
ale_SpecStr     fo.l    1       ;^String für Specify
ale_StrLength   fo.w    1       ;Stringlänge -1 (für DBRA)
ale_Localize    fo.b    1       ;-1:Locale 0:Builtin
ale_PAD         fo.b    1
ale_SIZEOF      fo.w    0

		XDEF    IdAlert
IdAlert         movem.l d1-d7/a0-a3/a5-a6,-(sp)
		link    a4,#ale_SIZEOF
		move.l  d0,d7
		move.l  a0,a3
		lea     strbase,a5
	;-- Strings zusammenkramen -------------;
		move.l  a3,a0                   ;Dead-String
		move.l  #IDTAG_DeadStr,d0
		moveq   #0,d1
		utils   GetTagData
		move.l  d0,(ale_DeadStr,a4)
		move.l  a3,a0                   ;Subsystem-String
		move.l  #IDTAG_SubsysStr,d0
		moveq   #0,d1
		utils   GetTagData
		move.l  d0,(ale_SubsysStr,a4)
		move.l  a3,a0                   ;General-String
		move.l  #IDTAG_GeneralStr,d0
		moveq   #0,d1
		utils   GetTagData
		move.l  d0,(ale_GeneralStr,a4)
		move.l  a3,a0                   ;Specific-String
		move.l  #IDTAG_SpecStr,d0
		moveq   #0,d1
		utils   GetTagData
		move.l  d0,(ale_SpecStr,a4)
		move.l  a3,a0                   ;Stringlänge
		move.l  #IDTAG_StrLength,d0
		moveq   #50,d1
		utils   GetTagData
		subq    #1,d0
		bcs     .err_nolength
		move    d0,(ale_StrLength,a4)
		move.l  a3,a0                   ;NoLocale
		move.l  #IDTAG_Localize,d0
		moveq   #-1,d1
		utils   GetTagData
		tst.l   d0
		sne     (ale_Localize,a4)
	;-- Recovery/Deadend? ------------------;
		tst.l   (ale_DeadStr,a4)        ;Deadend-String gewünscht?
		beq     .no_dead
		move.l  #MSG_ALERT_RECOVERY,d0
		btst    #31,d7                  ;Deadend?
		beq     .deadok
		move.l  #MSG_ALERT_DEADEND,d0
.deadok         move.b  (ale_Localize,a4),d1
		bsr     GetNewLocString         ;Suchen
		move.l  (ale_DeadStr,a4),a1
		move    (ale_StrLength,a4),d0
.deadcopy       move.b  (a0)+,(a1)+
		dbeq    d0,.deadcopy
		clr.b   -(a1)
	;-- Subsystem? -------------------------;
.no_dead        tst.l   (ale_SubsysStr,a4)
		beq     .no_subsys
		move.l  d7,d1
		swap    d1
		lsr     #8,d1
		and     #$7f,d1
		lea     tab_subsystem,a0        ;Subsystem suchen
.sub_find       cmp     (subsys_ID,a0),d1       ;Subsys-ID
		blo     .sub_notfound
		beq     .sub_found
		addq.l  #subsys_SIZEOF,a0
		bra     .sub_find
.sub_notfound   move.l  #MSG_ALERT_UNKNOWN,d0
		move.b  (ale_Localize,a4),d1
		bsr     GetNewLocString
		bra     .sub_copy
.sub_found      move    (subsys_Spec,a0),d0
		lea     (a5,d0.w),a0            ;^String
.sub_copy       move.l  (ale_SubsysStr,a4),a1
		move    (ale_StrLength,a4),d0
.subcopy        move.b  (a0)+,(a1)+
		dbeq    d0,.subcopy
		clr.b   -(a1)
	;-- General? ---------------------------;
.no_subsys      tst.l   (ale_GeneralStr,a4)
		beq     .no_general
		move.l  d7,d1
		swap    d1
		and     #$7f,d1
		lea     tab_general,a0          ;General cause suchen
		move.l  #MSG_ALERT_UNKNOWN,d0
.gen_find       cmp     (general_ID,a0),d1      ;General-ID
		blo     .gen_copy
		beq     .gen_found
		addq.l  #general_SIZEOF,a0
		bra     .gen_find
.gen_found      moveq   #0,d0
		move    (general_Spec,a0),d0    ;String-ID
		add.l   #MSG_AG_BADPARM,d0
.gen_copy       move.b  (ale_Localize,a4),d1
		bsr     GetNewLocString
		move.l  (ale_GeneralStr,a4),a1
		move    (ale_StrLength,a4),d0
.gencopy        move.b  (a0)+,(a1)+
		dbeq    d0,.gencopy
		clr.b   -(a1)
	;-- Specific? --------------------------;
.no_general     tst.l   (ale_SpecStr,a4)
		beq     .no_spec
		btst    #15,d7                  ;Zielobjekt?
		beq     .dest_alert
		move.l  d7,d1                   ;-- Ziel-Objekt testen ---
		and.l   #$7fff,d1
		lea     tab_objects,a0          ;Objekt suchen
.obj_find       cmp     (object_ID,a0),d1       ;Subsys-ID
		blo     .dest_alert
		beq     .obj_found
		addq.l  #object_SIZEOF,a0
		bra     .obj_find
.obj_found      move    (object_Spec,a0),d0
		lea     (a5,d0.w),a0            ;^String
		bra     .obj_copy
.dest_alert     move.l  d7,d1                   ;-- Ziel-Alert suchen ---
		and.l   #$7fffffff,d1
		lea     tab_alerts,a0           ;Alert suchen
		move.l  #MSG_ALERT_UNKNOWN,d0
.ale_find       cmp.l   (alert_ID,a0),d1        ;General-ID
		blo     .ale_copy
		beq     .ale_found
		addq.l  #alert_SIZEOF,a0
		bra     .ale_find
.ale_found      moveq   #0,d0
		move    (alert_Spec,a0),d0      ;String-ID
		add.l   #MSG_ACPU_ADDRESSERR,d0
.ale_copy       move.b  (ale_Localize,a4),d1
		bsr     GetNewLocString
.obj_copy       move.l  (ale_SpecStr,a4),a1     ;Kopieren
		move    (ale_StrLength,a4),d0
.speccopy       move.b  (a0)+,(a1)+
		dbeq    d0,.speccopy
		clr.b   -(a1)
	;-- to be continued... -----------------;
.no_spec
	;-- Fertig -----------------------------;
.done           moveq   #0,d0                   ;Alles OK
.exit           unlk    a4                      ;Fertig
		movem.l (sp)+,d1-d7/a0-a3/a5-a6
		rts
	;-- Fehler -----------------------------;
.err_nolength   moveq   #IDERR_NOLENGTH,d0      ;Länge = 0???
		bra     .exit
*<

*---------------------------------------------------------------*
*       == ALERT-TABELLE ==                                     *
*                                                               *
		SECTION tables,DATA

tab_subsystem   ssys    $0000,          "CPU"                   ; $0000
		ssys    $0001,          "exec.library"          ; $0001
		ssys    $0002,          "graphics.library"      ; $0002
		ssys    $0003,          "layers.library"        ; $0003
		ssys    $0004,          "intuition.library"     ; $0004
		ssys    $0005,          "math#?.library"        ; $0005
		ssys    $0007,          "dos.library"           ; $0007
		ssys    $0008,          "ramlib"                ; $0008
		ssys    $0009,          "icon.library"          ; $0009
		ssys    $000A,          "expansion.library"     ; $000A
		ssys    $000B,          "diskfont.library"      ; $000B
		ssys    $0010,          "audio.device"          ; $0010
		ssys    $0011,          "console.device"        ; $0011
		ssys    $0012,          "gameport.device"       ; $0012
		ssys    $0013,          "keyboard.device"       ; $0013
		ssys    $0014,          "trackdisk.device"      ; $0014
		ssys    $0015,          "timer.device"          ; $0015
		ssys    $0020,          "cia?.resource"         ; $0020
		ssys    $0021,          "disk.resource"         ; $0021
		ssys    $0022,          "misc.resource"         ; $0022
		ssys    $0030,          "bootstrap"             ; $0030
		ssys    $0031,          "Workbench"             ; $0031
		ssys    $0032,          "DiskCopy"              ; $0032
		ssys    $0033,          "gadtools.library"      ; $0033
		ssys    $0034,          "utility.library"       ; $0034
		ssdone

tab_general     general $00000000,      MSG_AG_GENERAL          ; $00000000
		general AG_NoMemory,    MSG_AG_NOMEMORY         ; $00010000
		general AG_MakeLib,     MSG_AG_MAKELIB          ; $00020000
		general AG_OpenLib,     MSG_AG_OPENLIB          ; $00030000
		general AG_OpenDev,     MSG_AG_OPENDEV          ; $00040000
		general AG_OpenRes,     MSG_AG_OPENRES          ; $00050000
		general AG_IOError,     MSG_AG_IOERROR          ; $00060000
		general AG_NoSignal,    MSG_AG_NOSIGNAL         ; $00070000
		general AG_BadParm,     MSG_AG_BADPARM          ; $00080000
		general AG_CloseLib,    MSG_AG_CLOSELIB         ; $00090000 Usually too many closes
		general AG_CloseDev,    MSG_AG_CLOSEDEV         ; $000A0000 or a mismatched close
		general AG_ProcCreate,  MSG_AG_PROCCREATE       ; $000B0000 Process creation failed
		gedone

tab_alerts      alerts  $00000000,      MSG_AN_NOALERT          ; $00000000 kein Alert
		alerts  ACPU_BusErr,    MSG_ACPU_BUSERR         ; $80000002 Hardware bus fault/access error
		alerts  ACPU_AddressErr,MSG_ACPU_ADDRESSERR     ; $80000003 Illegal address access (ie: odd)
		alerts  ACPU_InstErr,   MSG_ACPU_INSTERR        ; $80000004 Illegal instruction
		alerts  ACPU_DivZero,   MSG_ACPU_DIVZERO        ; $80000005 Divide by zero
		alerts  ACPU_CHK,       MSG_ACPU_CHK            ; $80000006 Check instruction error
		alerts  ACPU_TRAPV,     MSG_ACPU_TRAPV          ; $80000007 TrapV instruction error
		alerts  ACPU_PrivErr,   MSG_ACPU_PRIVERR        ; $80000008 Privilege violation error
		alerts  ACPU_Trace,     MSG_ACPU_TRACE          ; $80000009 Trace error
		alerts  ACPU_LineA,     MSG_ACPU_LINEA          ; $8000000A Line 1010 Emulator error
		alerts  ACPU_LineF,     MSG_ACPU_LINEF          ; $8000000B Line 1111 Emulator error
		alerts  $8000000C,      MSG_ACPU_EMUINTR        ; $8000000C Emulator interrupt
		alerts  $8000000D,      MSG_ACPU_COPRVIOL       ; $8000000D Coprocessor protocol violation
		alerts  ACPU_Format,    MSG_ACPU_FORMAT         ; $8000000E Stack frame format error
		alerts  ACPU_Spurious,  MSG_ACPU_SPURIOUS       ; $80000018 Spurious interrupt error
		alerts  ACPU_AutoVec1,  MSG_ACPU_AUTOVEC1       ; $80000019 AutoVector Level 1 interrupt error
		alerts  ACPU_AutoVec2,  MSG_ACPU_AUTOVEC2       ; $8000001A AutoVector Level 2 interrupt error
		alerts  ACPU_AutoVec3,  MSG_ACPU_AUTOVEC3       ; $8000001B AutoVector Level 3 interrupt error
		alerts  ACPU_AutoVec4,  MSG_ACPU_AUTOVEC4       ; $8000001C AutoVector Level 4 interrupt error
		alerts  ACPU_AutoVec5,  MSG_ACPU_AUTOVEC5       ; $8000001D AutoVector Level 5 interrupt error
		alerts  ACPU_AutoVec6,  MSG_ACPU_AUTOVEC6       ; $8000001E AutoVector Level 6 interrupt error
		alerts  ACPU_AutoVec7,  MSG_ACPU_AUTOVEC7       ; $8000001F AutoVector Level 7 interrupt error
		alerts  $80000030,      MSG_ACPU_FPCPBRANCH     ; $80000030 FPCP branch or set on unordered condition
		alerts  $80000031,      MSG_ACPU_FPCPINEXACT    ; $80000031 FPCP inexact result
		alerts  $80000032,      MSG_ACPU_FPCPDIVZERO    ; $80000032 FPCP divide by zero
		alerts  $80000033,      MSG_ACPU_FPCPUNDER      ; $80000033 FPCP underflow
		alerts  $80000034,      MSG_ACPU_FPCPOPERROR    ; $80000034 FPCP operand error
		alerts  $80000035,      MSG_ACPU_FPCPOVER       ; $80000035 FPCP overflow
		alerts  $80000036,      MSG_ACPU_NAN            ; $80000036 FPCP signaling NAN
		alerts  $80000037,      MSG_ACPU_UNIMPLDTYPE    ; $80000037 FPCP unimplemented data type
		alerts  $80000038,      MSG_ACPU_MMUCONFIG      ; $80000038 PMMU configuration
		alerts  $80000039,      MSG_ACPU_MMUILLEGAL     ; $80000039 PMMU illegal configuration
		alerts  $8000003A,      MSG_ACPU_MMUACCVIOL     ; $8000003A PMMU access level violation
		alerts  $8000003C,      MSG_ACPU_UNIMPLEA       ; $8000003C FPCP unimplemented effective address
		alerts  $8000003D,      MSG_ACPU_UNIMPLII       ; $8000003D FPCP unimplemented integer instruction
		alerts  AN_ExecLib,     MSG_AN_EXECLIB          ; $01000000
		alerts  AN_ExcptVect,   MSG_AN_EXCPTVECT        ; $01000001 68000 exception vector checksum (obs.)
		alerts  AN_BaseChkSum,  MSG_AN_BASECHKSUM       ; $01000002 Execbase checksum bad (obs.)
		alerts  AN_LibChkSum,   MSG_AN_LIBCHKSUM        ; $01000003 Library checksum failure
		alerts  AN_MemCorrupt,  MSG_AN_MEMCORRUPT       ; $81000005 Corrupt memory list detected in FreeMem
		alerts  AN_IntrMem,     MSG_AN_INTRMEM          ; $81000006 No memory for interrupt servers
		alerts  AN_InitAPtr,    MSG_AN_INITAPTR         ; $01000007 InitStruct() of an APTR source (obs.)
		alerts  AN_SemCorrupt,  MSG_AN_SEMCORRUPT       ; $01000008 A semaphore is in an illegal state at ReleaseSemaphore()
		alerts  AN_FreeTwice,   MSG_AN_FREETWICE        ; $01000009 Freeing memory that is already free
		alerts  AN_BogusExcpt,  MSG_AN_BOGUSEXCPT       ; $8100000A Illegal 68k exception taken (obs.)
		alerts  AN_IOUsedTwice, MSG_AN_IOUSEDTWICE      ; $0100000B Attempt to reuse active IORequest
		alerts  AN_MemoryInsane,MSG_AN_MEMORYINSANE     ; $0100000C Sanity check on memory list failed during AvailMem(MEMF_LARGEST)
		alerts  AN_IOAfterClose,MSG_AN_IOAFTERCLOSE     ; $0100000D IO attempted on closed IORequest
		alerts  AN_StackProbe,  MSG_AN_STACKPROBE       ; $0100000E Stack appears to extend out of range
		alerts  AN_BadFreeAddr, MSG_AN_BADFREEADDR      ; $0100000F Memory header not located. [ Usually an invalid address passed to FreeMem() ]
		alerts  AN_BadSemaphore,MSG_AN_BADSEMAPHORE     ; $01000010 An attempt was made to use the old message semaphores.
		alerts  AN_BadQuickInt, MSG_AN_BADQUICKINT      ; $810000FF A quick interrupt has happened to an uninitialized vector.
		alerts  AN_GraphicsLib, MSG_AN_GRAPHICSLIB      ; $02000000
		alerts  AN_GfxNewError, MSG_AN_GFXNEWERROR      ; $0200000C
		alerts  AN_GfxFreeError,MSG_AN_GFXFREEERROR     ; $0200000D
		alerts  AN_ObsoleteFont,MSG_AN_OBSOLETEFONT     ; $02000401 unsupported font description used
		alerts  AN_GfxNoMem,    MSG_AN_GFXNOMEM         ; $82010000 graphics out of memory
		alerts  AN_GfxNoMemMspc,MSG_AN_GFXNOMEMMSPC     ; $82010001 MonitorSpec alloc, no memory
		alerts  AN_LongFrame,   MSG_AN_LONGFRAME        ; $82010006 long frame, no memory
		alerts  AN_ShortFrame,  MSG_AN_SHORTFRAME       ; $82010007 short frame, no memory
		alerts  AN_TextTmpRas,  MSG_AN_TEXTTMPRAS       ; $02010009 text, no memory for TmpRas
		alerts  AN_BltBitMap,   MSG_AN_BLTBITMAP        ; $8201000A BltBitMap, no memory
		alerts  AN_RegionMemory,MSG_AN_REGIONMEMORY     ; $8201000B regions, memory not available
		alerts  AN_MakeVPort,   MSG_AN_MAKEVPORT        ; $82010030 MakeVPort, no memory
		alerts  AN_GfxNoLCM,    MSG_AN_GFXNOLCM         ; $82011234 emergency memory not available
		alerts  AN_LayersLib,   MSG_AN_LAYERSLIB        ; $03000000
		alerts  AN_LayersNoMem, MSG_AN_LAYERSNOMEM      ; $83010000 layers out of memory
		alerts  AN_Intuition,   MSG_AN_INTUITION        ; $04000000
		alerts  AN_GadgetType,  MSG_AN_GADGETTYPE       ; $84000001 unknown gadget type
		alerts  AN_BadGadget,   MSG_AN_BADGADGET        ; $04000001 Recovery form of AN_GadgetType
		alerts  AN_ItemBoxTop,  MSG_AN_ITEMBOXTOP       ; $84000006 item box top < RelZero
		alerts  AN_SysScrnType, MSG_AN_SYSSCRNTYPE      ; $84000009 open sys screen, unknown type
		alerts  AN_BadState,    MSG_AN_BADSTATE         ; $8400000C Bad State Return entering Intuition
		alerts  AN_BadMessage,  MSG_AN_BADMESSAGE       ; $8400000D Bad Message received by IDCMP
		alerts  AN_WeirdEcho,   MSG_AN_WEIRDECHO        ; $8400000E Weird echo causing incomprehension
		alerts  AN_NoConsole,   MSG_AN_NOCONSOLE        ; $8400000F couldn't open the Console Device
		alerts  AN_NoISem,      MSG_AN_NOISEM           ; $04000010 Intuition skipped obtaining a sem
		alerts  AN_ISemOrder,   MSG_AN_ISEMORDER        ; $04000011 Intuition obtained a sem in bad order
		alerts  AN_CreatePort,  MSG_AN_CREATEPORT       ; $84010002 create port, no memory
		alerts  AN_ItemAlloc,   MSG_AN_ITEMALLOC        ; $04010003 item plane alloc, no memory
		alerts  AN_SubAlloc,    MSG_AN_SUBALLOC         ; $04010004 sub alloc, no memory
		alerts  AN_PlaneAlloc,  MSG_AN_PLANEALLOC       ; $84010005 plane alloc, no memory
		alerts  AN_OpenScreen,  MSG_AN_OPENSCREEN       ; $84010007 open screen, no memory
		alerts  AN_OpenScrnRast,MSG_AN_OPENSCRNRAST     ; $84010008 open screen, raster alloc, no memory
		alerts  AN_AddSWGadget, MSG_AN_ADDSWGADGET      ; $8401000A add SW gadgets, no memory
		alerts  AN_OpenWindow,  MSG_AN_OPENWINDOW       ; $8401000B open window, no memory
		alerts  AN_MathLib,     MSG_AN_MATHLIB          ; $05000000
		alerts  AN_DOSLib,      MSG_AN_DOSLIB           ; $07000000
		alerts  AN_EndTask,     MSG_AN_ENDTASK          ; $07000002 EndTask didn't
		alerts  AN_QPktFail,    MSG_AN_QPKTFAIL         ; $07000003 Qpkt failure
		alerts  AN_AsyncPkt,    MSG_AN_ASYNCPKT         ; $07000004 Unexpected packet received
		alerts  AN_FreeVec,     MSG_AN_FREEVEC          ; $07000005 Freevec failed
		alerts  AN_DiskBlkSeq,  MSG_AN_DISKBLKSEQ       ; $07000006 Disk block sequence error
		alerts  AN_BitMap,      MSG_AN_BITMAP           ; $07000007 Bitmap corrupt
		alerts  AN_KeyFree,     MSG_AN_KEYFREE          ; $07000008 Key already free
		alerts  AN_BadChkSum,   MSG_AN_BADCHKSUM        ; $07000009 Invalid checksum
		alerts  AN_DiskError,   MSG_AN_DISKERROR        ; $0700000A Disk Error
		alerts  AN_KeyRange,    MSG_AN_KEYRANGE         ; $0700000B Key out of range
		alerts  AN_BadOverlay,  MSG_AN_BADOVERLAY       ; $0700000C Bad overlay
		alerts  AN_BadInitFunc, MSG_AN_BADINITFUNC      ; $0700000D Invalid init packet for cli/shell
		alerts  AN_FileReclosed,MSG_AN_FILERECLOSED     ; $0700000E A filehandle was closed more than once
		alerts  AN_StartMem,    MSG_AN_STARTMEM         ; $07010001 no memory at startup
		alerts  AN_RAMLib,      MSG_AN_RAMLIB           ; $08000000
		alerts  AN_BadSegList,  MSG_AN_BADSEGLIST       ; $08000001 overlays are illegal for library segments
		alerts  AN_IconLib,     MSG_AN_ICONLIB          ; $09000000
		alerts  AN_ExpansionLib,MSG_AN_EXPANSIONLIB     ; $0A000000
		alerts  AN_BadExpansionFree,MSG_AN_BADEXPANSIONFREE ; $0A000001 Freeed free region
		alerts  AN_DiskfontLib, MSG_AN_DISKFONTLIB      ; $0B000000
		alerts  AN_AudioDev,    MSG_AN_AUDIODEV         ; $10000000
		alerts  AN_ConsoleDev,  MSG_AN_CONSOLEDEV       ; $11000000
		alerts  AN_NoWindow,    MSG_AN_NOWINDOW         ; $11000001 Console can't open initial window
		alerts  AN_GamePortDev, MSG_AN_GAMEPORTDEV      ; $12000000
		alerts  AN_KeyboardDev, MSG_AN_KEYBOARDDEV      ; $13000000
		alerts  AN_TrackDiskDev,MSG_AN_TRACKDISKDEV     ; $14000000
		alerts  AN_TDCalibSeek, MSG_AN_TDCALIBSEEK      ; $14000001 calibrate: seek error
		alerts  AN_TDDelay,     MSG_AN_TDDELAY          ; $14000002 delay: error on timer wait
		alerts  AN_TimerDev,    MSG_AN_TIMERDEV         ; $15000000
		alerts  AN_TMBadReq,    MSG_AN_TMBADREQ         ; $15000001 bad request
		alerts  AN_TMBadSupply, MSG_AN_TMBADSUPPLY      ; $15000002 power supply -- no 50/60hz ticks
		alerts  AN_CIARsrc,     MSG_AN_CIARSRC          ; $20000000
		alerts  AN_DiskRsrc,    MSG_AN_DISKRSRC         ; $21000000
		alerts  AN_DRHasDisk,   MSG_AN_DRHASDISK        ; $21000001 get unit: already has disk
		alerts  AN_DRIntNoAct,  MSG_AN_DRINTNOACT       ; $21000002 interrupt: no active unit
		alerts  AN_MiscRsrc,    MSG_AN_MISCRSRC         ; $22000000
		alerts  AN_BootStrap,   MSG_AN_BOOTSTRAP        ; $30000000
		alerts  AN_BootError,   MSG_AN_BOOTERROR        ; $30000001 boot code returned an error
		alerts  AN_Workbench,   MSG_AN_WORKBENCH        ; $31000000
		alerts  AN_NoFonts,     MSG_AN_NOFONTS          ; $B1000001
		alerts  AN_WBBadStartupMsg2,MSG_AN_WBBADSTARTUPMSG2 ; $31000002
		alerts  AN_WBBadIOMsg,  MSG_AN_WBBADIOMSG       ; $31000003 Hacker code?
		alerts  AN_WBReLayoutToolMenu,MSG_AN_WBRELAYOUTTOOLMENU ; $B1010009 GadTools broke?
		alerts  AN_DiskCopy,    MSG_AN_DISKCOPY         ; $32000000
		alerts  AN_GadTools,    MSG_AN_GADTOOLS         ; $33000000
		alerts  AN_UtilityLib,  MSG_AN_UTILITYLIB       ; $34000000
		alerts  $35000000,      MSG_AN_LAWBREAKER       ; $35000000
		aldone

tab_objects     object  AO_ExecLib,     "exec.library"          ; $00008001
		object  AO_GraphicsLib, "graphics.library"      ; $00008002
		object  AO_LayersLib,   "layers.library"        ; $00008003
		object  AO_Intuition,   "intuition.library"     ; $00008004
		object  AO_MathLib,     "math#?.library"        ; $00008005
		object  AO_DOSLib,      "dos.library"           ; $00008007
		object  AO_RAMLib,      "ramlib"                ; $00008008
		object  AO_IconLib,     "icon.library"          ; $00008009
		object  AO_ExpansionLib,"expansion.library"     ; $0000800A
		object  AO_DiskfontLib, "diskfont.library"      ; $0000800B
		object  AO_UtilityLib,  "utility.library"       ; $0000800C
		object  AO_KeyMapLib,   "keymap.library"        ; $0000800D
		object  AO_AudioDev,    "audio.device"          ; $00008010
		object  AO_ConsoleDev,  "console.device"        ; $00008011
		object  AO_GamePortDev, "gameport.device"       ; $00008012
		object  AO_KeyboardDev, "keyboard.device"       ; $00008013
		object  AO_TrackDiskDev,"trackdisk.device"      ; $00008014
		object  AO_TimerDev,    "timer.device"          ; $00008015
		object  AO_CIARsrc,     "cia?.resource"         ; $00008020
		object  AO_DiskRsrc,    "disk.resource"         ; $00008021
		object  AO_MiscRsrc,    "misc.resource"         ; $00008022
		object  AO_BootStrap,   "bootstrap"             ; $00008030
		object  AO_Workbench,   "Workbench"             ; $00008031
		object  AO_DiskCopy,    "DiskCopy"              ; $00008032
		object  AO_GadTools,    "gadtools"              ; $00008033
		obdone

*---------------------------------------------------------------*
*       == ENDE ==                                              *
*                                                               *
		ECHO    "##"
		ECHO    "## SubSystems = ",__GLBSUBSYS
		ECHO    "## General    = ",__GLBGENERAL
		ECHO    "## Alerts     = ",__GLBALERT
		ECHO    "## Objects    = ",__OBJECT
		ECHO    "##"
		END OF SOURCE
