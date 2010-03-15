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

ID_HARDWARE     SET     -1
CATCOMP_NUMBERS SET     1

		MACHINE 68060

		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/initializers.i
		INCLUDE exec/nodes.i
		INCLUDE exec/resident.i
		INCLUDE exec/execbase.i
		INCLUDE exec/tasks.i
		INCLUDE exec/memory.i
		INCLUDE exec/semaphores.i
		INCLUDE dos/dos.i
		INCLUDE graphics/gfxbase.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/utility.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/dos.i
		INCLUDE lvo/graphics.i

		INCLUDE libraries/identify.i

		INCLUDE Hardware.i
		INCLUDE Refs.i
		INCLUDE Locale.i

		SECTION text,CODE

		XREF    _PPC_CPU_Clock

		clrfo
idhws_Tags      fo.l    1       ;Tags
idhws_Type      fo.l    1       ;Type
idhws_Localize  fo.b    1       ;-1: Localisieren
idhws_NullNA    fo.b    1       ;-1: Null für NA
idhws_SIZEOF    fo.w    0

		; EQUs für die native.library
NATIVE_HOST_OSNAME      EQU     1
NATIVE_HOST_OSVERS      EQU     2
NATIVE_HOST_MACHINE     EQU     4
NATIVE_HOST_CPUID       EQU     5
NATIVE_HOST_CPUSPEED    EQU     6


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
* Name:         InitHardware                            *
*                                                       *
* Funktion:     Hardware-Teil initialisieren            *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
		XDEF    InitHardware
InitHardware    movem.l d0-d3/a0-a6,-(sp)
	;-- Semaphore erzeugen -----------------;
		lea     (db_semaphore,PC),a0
		exec    InitSemaphore
	;-- DraCo? -----------------------------;
		lea     (.draconame,PC),a1      ;DraCo-System
		exec    OpenResource
		lea     (flags_draco,PC),a0
		tst.l   d0                      ;okay?
		sne     (a0)
		bsr     BuildRAMtab             ;RAM-Tabelle erzeugen
	;-- Hardware ermitteln -----------------;
		moveq   #IDHW_SYSTEM,d0
		bsr     IdHardwareNum           ;setzt das Emulated-Flag
	;-- Fertig -----------------------------;
		movem.l (sp)+,d0-d3/a0-a6
		rts
	;-- Strings ----------------------------;
.draconame      dc.b    "draco.resource",0
		even
*<
*-------------------------------------------------------*
* Name:         ExitHardware                            *
*                                                       *
* Funktion:     Hardware-Teil freigeben                 *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
		XDEF    ExitHardware
ExitHardware    movem.l d0-d1/a0-a1,-(SP)
		lea     (db_semaphore,PC),a0
		exec    ObtainSemaphore
		movem.l (SP)+,d0-d1/a0-a1
		rts
*<
*-------------------------------------------------------*
* Name:         IdHardwareNum                           *
*                                                       *
* Funktion:     Holt Beschreibung zur Hardware (num.)   *
*                                                       *
* Parameter:    -» D0.l DescriptionType                 *
*               -» A0.l ^Tags                           *
*               «- D0.l Zahl                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 14:48:03)            *
*                                                       *
		XDEF    IdHardwareNum
IdHardwareNum   movem.l d1-d3/a0-a6,-(SP)
		lea     strbase,a4
		move.l  a0,a3                   ;^TagList
		lea     entrynums,a5            ;Ergebnis speichern
		move.l  d0,d3                   ;d3: Num merken
		cmp.l   #IDHW_NUMBEROF,d3       ;>= numberof?
		bhs     .err_unknown
	;-- DBase belegen ----------------------;
		lea     (db_semaphore,PC),a0
		exec    ObtainSemaphore
	;-- Bereits erzeugt? -------------------;
		lea     buildflags,a0
		tst.b   (a0,d3.w)               ;Existiert bereits?
		bne     .is_built
	;-- Eintrag erzeugen -------------------;
		st      (a0,d3.w)               ;WICHTIG: *VOR* dem Ansprung in die Routine!!!
		lea     (.calltab,PC),a0        ;Init-Funktionszeiger holen
		IFD     _MAKE_68020
		 move.l (a0,d3.w*4),a2
		ELSE
		 move   d3,d0
		 add    d0,d0
		 add    d0,d0
		 move.l (a0,d0.w),a2            ;entsprechenden Eintrag holen
		ENDC
		move.l  (execbase,PC),a0
		move    (AttnFlags,a0),d0       ;^AttnFlags
		movem.l d3-d7/a5,-(SP)
		jsr     (a2)
		movem.l (SP)+,d3-d7/a5
		IFD     _MAKE_68020
		 move.l d0,(a5,d3.w*4)
		ELSE
		 move   d3,d1
		 add    d1,d1
		 add    d1,d1
		 move.l d0,(a5,d1.w)
		ENDC
		bra     .free
	;-- Eintrag lesen ----------------------;
.is_built
		IFD     _MAKE_68020             ;Ergebnis holen
		 move.l (a5,d3.w*4),d0
		ELSE
		 move   d3,d0
		 add    d0,d0
		 add    d0,d0
		 move.l (a5,d0.w),d0
		ENDC
	;-- DBase freigeben --------------------;
.free           lea     (db_semaphore,PC),a0
		exec    ReleaseSemaphore
	;-- Fertig -----------------------------;
.exit           movem.l (SP)+,d1-d3/a0-a6
		rts
	;-- Fehler -----------------------------;
.err_unknown    ;; Fehler: Type nicht bekannt!
		moveq   #0,d0                   ;War nichts
		bra     .exit
	;-- Funktionstabelle -------------------;
.calltab        dc.l    do_System,       do_CPU,         do_FPU,       do_MMU
		dc.l    do_OsVer,        do_ExecVer,     do_WbVer,     do_RomSize
		dc.l    do_Chipset,      do_GfxSys,      do_ChipRAM,   do_FastRAM
		dc.l    do_RAM,          do_SetPatchVer, do_AudioSys,  do_OsNr
		dc.l    do_VMChipRAM,    do_VMFastRAM,   do_VMRAM,     do_PlainChipRAM
		dc.l    do_PlainFastRAM, do_PlainRAM,    do_VBR,       do_LastAlert
		dc.l    do_VBlankFreq,   do_PowerFreq,   do_EClock,    do_SlowRAM
		dc.l    do_Gary,         do_Ramsey,      do_BattClock, do_ChunkyPlanar
		dc.l    do_PowerPC,      do_PPCClock,    do_CPURev,    do_CPUClock
		dc.l    do_FPUClock,     do_RAMAccess,   do_RAMWidth,  do_RAMCAS
		dc.l    do_RAMBandwidth, do_TCPIP,       do_PPCOS,     do_Agnus
		dc.l    do_AgnusMode,    do_Denise,      do_DeniseRev, do_BoingBag
		dc.l    do_Emulated,     do_XLVersion,   do_HostOS,    do_HostVers
		dc.l    do_HostMachine,  do_HostCPU,     do_HostSpeed
*<
*-------------------------------------------------------*
* Name:         IdHardware                              *
*                                                       *
* Funktion:     Holt Beschreibung zur Hardware          *
*                                                       *
* Parameter:    -» D0.l DescriptionType                 *
*               -» A0.l ^Tags                           *
*               «- D0.l ^String oder NULL               *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 14:48:03)            *
*                                                       *
		XDEF    IdHardware
IdHardware      movem.l d1-d3/a0-a3/a6,-(SP)
		link    a4,#idhws_SIZEOF
		move.l  a0,(idhws_Tags,a4)      ;^Tags
		move.l  d0,(idhws_Type,a4)      ;Type
		cmp.l   #IDHW_NUMBEROF,d0       ;>= numberof?
		bhs     .err_unknown
	;-- Tags auswerten ---------------------;
		move.l  (idhws_Tags,a4),a0      ;lokalisieren?
		move.l  #IDTAG_Localize,d0
		moveq   #-1,d1
		utils   GetTagData
		tst.l   d0
		sne     (idhws_Localize,a4)
		move.l  (idhws_Tags,a4),a0      ;NULL4NA
		move.l  #IDTAG_NULL4NA,d0
		moveq   #0,d1
		utils   GetTagData
		tst.l   d0
		sne     (idhws_NullNA,a4)
	;-- Numerisches Ergebnis holen ---------;
		move.l  (idhws_Type,a4),d0
		move.l  (idhws_Tags,a4),a0
		bsr     IdHardwareNum
	;-- Umwandeln --------------------------;
		move.l  (idhws_Type,a4),d1
		lea     (.calltab,PC),a0        ;Init-Funktionszeiger holen
		IFD     _MAKE_68020
		 move.l (a0,d1.w*4),a0
		ELSE
		 add    d1,d1
		 add    d1,d1
		 move.l (a0,d1.w),a0
		ENDC
		jsr     (a0)
		move.l  a0,d0
	;-- Fertig -----------------------------;
.exit           unlk    a4
		movem.l (sp)+,d1-d3/a0-a3/a6
		rts
	;-- Fehler -----------------------------;
.err_unknown    ;; Fehler: Type nicht bekannt!
		moveq   #0,d0                   ;War nichts
		bra     .exit
	;-- Funktionstabelle -------------------;
.calltab        dc.l    cv_System,       cv_CPU,         cv_FPU,       cv_MMU
		dc.l    cv_OsVer,        cv_ExecVer,     cv_WbVer,     cv_RomSize
		dc.l    cv_Chipset,      cv_GfxSys,      cv_ChipRAM,   cv_FastRAM
		dc.l    cv_RAM,          cv_SetPatchVer, cv_AudioSys,  cv_OsNr
		dc.l    cv_VMChipRAM,    cv_VMFastRAM,   cv_VMRAM,     cv_PlainChipRAM
		dc.l    cv_PlainFastRAM, cv_PlainRAM,    cv_VBR,       cv_LastAlert
		dc.l    cv_VBlankFreq,   cv_PowerFreq,   cv_EClock,    cv_SlowRAM
		dc.l    cv_Gary,         cv_Ramsey,      cv_BattClock, cv_ChunkyPlanar
		dc.l    cv_PowerPC,      cv_PPCClock,    cv_CPURev,    cv_CPUClock
		dc.l    cv_FPUClock,     cv_RAMAccess,   cv_RAMWidth,  cv_RAMCAS
		dc.l    cv_RAMBandwidth, cv_TCPIP,       cv_PPCOS,     cv_Agnus
		dc.l    cv_AgnusMode,    cv_Denise,      cv_DeniseRev, cv_BoingBag
		dc.l    cv_Emulated,     cv_XLVersion,   cv_HostOS,    cv_HostVers
		dc.l    cv_HostMachine,  cv_HostCPU,     cv_HostSpeed

	;-- Funktionen -------------------------;
	;  -> D0.l Numerisches Ergebnis
	;  -> A4.l ^Stack-Frame
	;  <- A0.l String
*> cv_System
cv_System       add.l   #MSG_HW_AMIGA1000,d0
		bra     quick_loc
*<
*> cv_CPU
cv_CPU          add.l   #MSG_HW_68000,d0
		bra     quick_loc
*<
*> cv_FPU
cv_FPU          subq.l  #1,d0                   ;NONE?
		bcs     quick_none
		lea     (.systab,PC),a0
		move.b  (a0,d0.l),d0
		add.l   #MSG_HW_68000,d0
		bra     quick_loc
.systab         dc.b    MSG_HW_68881-MSG_HW_68000
		dc.b    MSG_HW_68882-MSG_HW_68000
		dc.b    MSG_HW_68040-MSG_HW_68000
		dc.b    MSG_HW_68060-MSG_HW_68000
		even
*<
*> cv_MMU
cv_MMU          subq.l  #1,d0                   ;NONE?
		bcs     quick_none
		lea     (.systab,PC),a0
		move.b  (a0,d0.l),d0
		add.l   #MSG_HW_68000,d0
		bra     quick_loc
.systab         dc.b    MSG_HW_68851-MSG_HW_68000
		dc.b    MSG_HW_68030-MSG_HW_68000
		dc.b    MSG_HW_68040-MSG_HW_68000
		dc.b    MSG_HW_68060-MSG_HW_68000
		even
*<
*> cv_OsVer
cv_OsVer        lea     buf_OsVer,a0
		lea     buf_OsVerLoc,a1
		bra     quick_ver
*<
*> cv_ExecVer
cv_ExecVer      lea     buf_ExecVer,a0
		lea     buf_ExecVerLoc,a1
		bra     quick_ver
*<
*> cv_WbVer
cv_WbVer        tst.l   d0
		beq     quick_na
		lea     buf_WbVer,a0
		lea     buf_WbVerLoc,a1
		bra     quick_ver
*<
*> cv_RomSize
cv_RomSize      lea     buf_RomSize,a0
		lea     buf_RomSizeLoc,a1
		bra     quick_size
*<
*> cv_Chipset
cv_Chipset      add.l   #MSG_HW_OCS,d0
		bra     quick_loc
*<
*> cv_GfxSys
cv_GfxSys       add.l   #MSG_HW_AMIGAOS,d0
		bra     quick_loc
*<
*> cv_ChipRAM
cv_ChipRAM      lea     buf_ChipRAM,a0
		lea     buf_ChipRAMLoc,a1
		bra     quick_size
*<
*> cv_FastRAM
cv_FastRAM      lea     buf_FastRAM,a0
		lea     buf_FastRAMLoc,a1
		bra     quick_size
*<
*> cv_RAM
cv_RAM          lea     buf_RAM,a0
		lea     buf_RAMLoc,a1
		bra     quick_size
*<
*> cv_SetPatchVer
cv_SetPatchVer  tst.l   d0
		beq     quick_na
		lea     buf_SetPatchVer,a0
		lea     buf_SetPatchVerLoc,a1
		bra     quick_ver
*<
*> cv_AudioSys
cv_AudioSys     add.l   #MSG_HW_AUDAMIGAOS,d0
		bra     quick_loc
*<
*> cv_OsNr
cv_OsNr         subq.l  #1,d0                   ;NONE?
		bcc     .os_ok
		tst.b   (idhws_NullNA,a4)
		beq     .strna
		sub.l   a0,a0                   ;NULLptr
		rts
.strna          move.l  #MSG_HW_OS_UNKNOWN,d0
		bra     quick_loc
.os_ok          add.l   #MSG_HW_OS_36,d0
		bra     quick_loc
*<
*> cv_VMChipRAM
cv_VMChipRAM    lea     buf_VMChipRAM,a0
		lea     buf_VMChipRAMLoc,a1
		bra     quick_size
*<
*> cv_VMFastRAM
cv_VMFastRAM    lea     buf_VMFastRAM,a0
		lea     buf_VMFastRAMLoc,a1
		bra     quick_size
*<
*> cv_VMRAM
cv_VMRAM        lea     buf_VMRAM,a0
		lea     buf_VMRAMLoc,a1
		bra     quick_size
*<
*> cv_PlainChipRAM
cv_PlainChipRAM lea     buf_PlainChipRAM,a0
		lea     buf_PlainChipRAMLoc,a1
		bra     quick_size
*<
*> cv_PlainFastRAM
cv_PlainFastRAM lea     buf_PlainFastRAM,a0
		lea     buf_PlainFastRAMLoc,a1
		bra     quick_size
*<
*> cv_PlainRAM
cv_PlainRAM     lea     buf_PlainRAM,a0
		lea     buf_PlainRAMLoc,a1
		bra     quick_size
*<
*> cv_VBR
cv_VBR          lea     buf_VBR,a0
		sf      (a0)                    ; Caching verhindern
		bra     quick_addr
*<
*> cv_LastAlert
cv_LastAlert    lea     buf_LastAlert,a0
		sf      (a0)                    ; Caching verhindern
		bra     quick_hex
*<
*> cv_VBlankFreq
cv_VBlankFreq   lea     buf_VBlankFreq,a0
		bra     quick_freq
*<
*> cv_PowerFreq
cv_PowerFreq    lea     buf_PowerFreq,a0
		bra     quick_freq
*<
*> cv_EClock
cv_EClock       lea     buf_EClock,a0
		bra     quick_freq
*<
*> cv_SlowRAM
cv_SlowRAM      lea     buf_SlowRAM,a0
		lea     buf_SlowRAMLoc,a1
		bra     quick_size
*<
*> cv_Gary
cv_Gary         subq.l  #1,d0                   ;NONE?
		bcs     quick_none
		add.l   #MSG_HW_NORMAL,d0
		bra     quick_loc
*<
*> cv_Ramsey
cv_Ramsey       subq.l  #1,d0                   ;NONE?
		bcs     quick_none
		add.l   #MSG_HW_REVD,d0
		bra     quick_loc
*<
*> cv_BattClock
cv_BattClock    bra     quick_found

*<
*> cv_ChunkyPlanar
cv_ChunkyPlanar bra     quick_found

*<
*> cv_PowerPC
cv_PowerPC      subq.l  #1,d0                   ;NONE?
		bcs     quick_none
		add.l   #MSG_HW_PPCFOUND,d0
		bra     quick_loc
*<
*> cv_PPCClock
cv_PPCClock     lea     buf_PPCClock,a0
		bra     quick_mhz
*<
*> cv_CPURev
cv_CPURev       tst.l   d0              ;Vorhanden?
		bmi     quick_na
		lea     buf_CPURev,a0
		bra     quick_num
*<
*> cv_CPUClock
cv_CPUClock     lea     buf_CPUClock,a0
		bra     quick_mhz
*<
*> cv_FPUClock
cv_FPUClock     lea     buf_FPUClock,a0
		bra     quick_mhz
*<
*> cv_RAMAccess
cv_RAMAccess    tst.l   d0              ;Vorhanden?
		beq     quick_na
		lea     buf_RAMAccess,a0
		bra     quick_ns
*<
*> cv_RAMWidth
cv_RAMWidth     tst.l   d0              ;Vorhanden?
		beq     quick_na
		lea     buf_RAMWidth,a0
		bra     quick_num
*<
*> cv_RAMCAS
cv_RAMCAS       subq.l  #1,d0                   ;NONE?
		bcs     quick_none
		add.l   #MSG_HW_RAMCAS_NORMAL,d0
		bra     quick_loc
*<
*> cv_RAMBandwidth
cv_RAMBandwidth tst.l   d0              ;Vorhanden?
		beq     quick_na
		lea     buf_RAMBandwidth,a0
		bra     quick_num
*<
*> cv_TCPIP
cv_TCPIP        add.l   #MSG_HW_TCPIP_NONE,d0
		bra     quick_loc
*<
*> cv_PPCOS
cv_PPCOS        add.l   #MSG_HW_PPCOS_NONE,d0
		bra     quick_loc
*<
*> cv_Agnus
cv_Agnus        add.l   #MSG_HW_AGNUS_NONE,d0
		bra     quick_loc
*<
*> cv_AgnusMode
cv_AgnusMode    add.l   #MSG_HW_AMODE_NONE,d0
		bra     quick_loc
*<
*> cv_Denise
cv_Denise       add.l   #MSG_HW_DENISE_NONE,d0
		bra     quick_loc
*<
*> cv_DeniseRev
cv_DeniseRev    tst.l   d0              ;Vorhanden?
		bmi     quick_na
		lea     buf_DeniseRev,a0
		bra     quick_num
*<
*> cv_BoingBag
cv_BoingBag     tst.l   d0              ;Vorhanden?
		beq     quick_na
		lea     buf_BoingBag,a0
		bra     quick_num
*<
*> cv_Emulated
cv_Emulated     bra     quick_found

*<
*> cv_XLVersion
cv_XLVersion    lea     buf_XLVersion,a0
		bra     quick_num
*<
*> cv_HostOS
cv_HostOS       lea     buf_HostOS,a0
		bra     quick_strptr
*<
*> cv_HostVers
cv_HostVers     lea     buf_HostVers,a0
		bra     quick_strptr
*<
*> cv_HostMachine
cv_HostMachine  lea     buf_HostMachine,a0
		bra     quick_strptr
*<
*> cv_HostCPU
cv_HostCPU      lea     buf_HostCPU,a0
		bra     quick_strptr
*<
*> cv_HostSpeed
cv_HostSpeed    lea     buf_HostSpeed,a0
		bra     quick_mhz
*<

*> ** QUICK-FUNKTIONEN **
	;== Schnelles Found ====================;
quick_found     tst.l   d0                      ;OK?
		beq     quick_none
		move.l  #MSG_HW_FOUND,d0
		bra     quick_loc
	;== Schnelles Not Available ============;
quick_na        tst.b   (idhws_NullNA,a4)
		beq     .strna
		sub.l   a0,a0                   ;NULLptr
		rts
.strna          move.l  #MSG_HW_NOVERSION,d0
		bra     quick_loc
	;== Schnelles Not Found ================;
quick_none      tst.b   (idhws_NullNA,a4)
		beq     .strna
		sub.l   a0,a0                   ;NULLptr
		rts
.strna          move.l  #MSG_HW_NONE,d0
	;== Schnelles Localisieren =============;
quick_loc       move.b  (idhws_Localize,a4),d1
		bra     GetNewLocString
	;== Schnelle Versionswandlung ==========;
quick_ver       move.b  (idhws_Localize,a4),d1
		beq     .noloc
		move.l  a1,a0
.noloc          tst.b   (a0)                    ;bereits gewandelt?
		bne     .exit
		move.l  a0,a1
		moveq   #0,d2
		swap    d0
		move    d0,d2
		move.l  d2,-(sp)
		swap    d0
		move    d0,d2
		move.l  d2,-(sp)
		move.l  #MSG_HW_VERSION,d0
		bsr     GetNewLocString
		exg     a0,a1
		move.l  sp,a2
		bsr     SPrintF
		add.l   #2*4,sp
.exit           rts
	;== Schnelles PrintSize ================;
quick_size      move.b  (idhws_Localize,a4),d1  ;welcher Stringbuffer?
		beq     .noloc
		move.l  a1,a0
.noloc          tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		bra     SPrintSize
.exit           rts
	;== Schnelles Hex ======================;
quick_hex       tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		lea     (.hex,PC),a1
		bra     quick_sconv
.exit           rts
.hex            dc.b    "%08lx",0
		even
	;== Schnelles Addr =====================;
quick_addr      tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		lea     (.addr,PC),a1
		bra     quick_sconv
.exit           rts
.addr           dc.b    "0x%08lx",0
		even
	;== Schnelles Freq =====================;
quick_freq      tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		lea     (.freq,PC),a1
		bra     quick_sconv
.exit           rts
.freq           dc.b    "%ld Hz",0
		even
	;== Schnelles MHZ ======================;
quick_mhz       tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		lea     (.mhz,PC),a1
		bra     quick_sconv
.exit           rts
.mhz            dc.b    "%ld MHz",0
		even
	;== Schnelles ns =======================;
quick_ns        tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		lea     (.ns,PC),a1
		bra     quick_sconv
.exit           rts
.ns             dc.b    "%ld ns",0
		even
	;== Schnelles Num ======================;
quick_num       tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		lea     (.num,PC),a1
		bra     quick_sconv
.exit           rts
.num            dc.b    "%ld",0
		even
	;== Schnelles String ===================;
quick_strptr    tst.b   (a0)                    ;bereits gewandelt
		bne     .exit
		tst.l   d0
		beq     quick_none
		lea     (.strptr,PC),a1
		bra     quick_sconv
.exit           rts
.strptr         dc.b    "%.29ls",0
		even
	;== Schnelles SPrintf ==================;
quick_sconv     move.l  d0,-(sp)
		move.l  sp,a2
		bsr     SPrintF
		add.l   #1*4,sp
		rts
*<

STRSIZE         EQU     30
		SAVE
		SECTION blank,BSS
buf_STARTOFBUF          ds.b    0
buf_OsVer               ds.b    STRSIZE
buf_OsVerLoc            ds.b    STRSIZE
buf_ExecVer             ds.b    STRSIZE
buf_ExecVerLoc          ds.b    STRSIZE
buf_WbVer               ds.b    STRSIZE
buf_WbVerLoc            ds.b    STRSIZE
buf_RomSize             ds.b    STRSIZE
buf_RomSizeLoc          ds.b    STRSIZE
buf_ChipRAM             ds.b    STRSIZE
buf_ChipRAMLoc          ds.b    STRSIZE
buf_FastRAM             ds.b    STRSIZE
buf_FastRAMLoc          ds.b    STRSIZE
buf_RAM                 ds.b    STRSIZE
buf_RAMLoc              ds.b    STRSIZE
buf_SetPatchVer         ds.b    STRSIZE
buf_SetPatchVerLoc      ds.b    STRSIZE
buf_VMChipRAM           ds.b    STRSIZE
buf_VMChipRAMLoc        ds.b    STRSIZE
buf_VMFastRAM           ds.b    STRSIZE
buf_VMFastRAMLoc        ds.b    STRSIZE
buf_VMRAM               ds.b    STRSIZE
buf_VMRAMLoc            ds.b    STRSIZE
buf_PlainChipRAM        ds.b    STRSIZE
buf_PlainChipRAMLoc     ds.b    STRSIZE
buf_PlainFastRAM        ds.b    STRSIZE
buf_PlainFastRAMLoc     ds.b    STRSIZE
buf_PlainRAM            ds.b    STRSIZE
buf_PlainRAMLoc         ds.b    STRSIZE
buf_VBR                 ds.b    STRSIZE
buf_LastAlert           ds.b    STRSIZE
buf_VBlankFreq          ds.b    STRSIZE
buf_PowerFreq           ds.b    STRSIZE
buf_EClock              ds.b    STRSIZE
buf_SlowRAM             ds.b    STRSIZE
buf_SlowRAMLoc          ds.b    STRSIZE
buf_PPCClock            ds.b    STRSIZE
buf_CPURev              ds.b    STRSIZE
buf_CPUClock            ds.b    STRSIZE
buf_FPUClock            ds.b    STRSIZE
buf_RAMAccess           ds.b    STRSIZE
buf_RAMWidth            ds.b    STRSIZE
buf_RAMBandwidth        ds.b    STRSIZE
buf_DeniseRev           ds.b    STRSIZE
buf_BoingBag            ds.b    STRSIZE
buf_XLVersion           ds.b    STRSIZE
buf_HostOS              ds.b    STRSIZE
buf_HostVers            ds.b    STRSIZE
buf_HostMachine         ds.b    STRSIZE
buf_HostCPU             ds.b    STRSIZE
buf_HostSpeed           ds.b    STRSIZE
buf_ENDOFBUF            ds.b    0
		RESTORE
*<
*-------------------------------------------------------*
* Name:         IdHardwareUpdate                        *
*                                                       *
* Funktion:     Aktualisiert die Hardware-Datenbank     *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 14:48:03)            *
*                                                       *
		XDEF    IdHardwareUpdate
IdHardwareUpdate
		movem.l d0-d3/a0-a6,-(SP)
	;-- DBase belegen ----------------------;
		lea     (db_semaphore,PC),a0
		exec    ObtainSemaphore
	;-- Erzeugungsflags löschen ------------;
		moveq   #IDHW_NUMBEROF-1,d0
		lea     buildflags,a0
.clrloop        sf      (a0,d0.w)
		dbra    d0,.clrloop
	;-- Strings invalidieren ---------------;
		lea     buf_STARTOFBUF,a0
		move    #((buf_ENDOFBUF-buf_STARTOFBUF)/STRSIZE)-1,d0
.invloop        sf      (a0)
		add.l   #STRSIZE,a0
		dbra    d0,.invloop
	;-- RAM neu aufbauen -------------------;
		bsr     BuildRAMtab
	;-- DBase freigeben --------------------;
		lea     (db_semaphore,PC),a0
		exec    ReleaseSemaphore
	;-- Fertig -----------------------------;
.exit           movem.l (SP)+,d0-d3/a0-a6
		rts
*<
*-------------------------------------------------------*
* Name:         IdFormatString                          *
*                                                       *
* Funktion:     Formatierter String mit Parametern      *
*                                                       *
* Parameter:    -» a0.l ^Formatstring                   *
*               -» a1.l ^Puffer                         *
*               -» d0.l Puffer-Länge                    *
*               -» a2.l ^Tags oder NULL                 *
*               «- d0.l Puffer-Länge des Strings        *
*                       inkl. Nullterminator            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (11. März 1999, 01:03:18)           *
*                                                       *
		XDEF    IdFormatString
IdFormatString  movem.l d1-d7/a0-a6,-(SP)
		move.l  a1,d7                   ;d7: Puffer-Start
		move.l  a1,a4                   ;a4: current
		lea     (-1,a1,d0.l),a5         ;a5: Puffer-Ende
		move.l  a0,a3                   ;a3: Formatstring
	;-- Formatstring kopieren --------------;
.copy           cmp.l   a5,a4                   ;Ende erreicht?
		bhs     .terminate              ;  ja: terminieren und Exit
		move.b  (a3)+,d0                ;Zeichen holen
		beq     .terminate              ;  Ende: terminieren
		cmp.b   #"$",d0                 ;Escape-Char?
		beq     .escape
.insert         move.b  d0,(a4)+                ;sonst in Puffer werfen
		bra     .copy                   ; und weitermachen
	;-- Escape-Char ------------------------;
.escape         move.b  (a3)+,d0                ;folgendes Zeichen holen
		cmp.b   #"$",d0                 ; noch ein Prozent?
		beq     .insert                 ;dann Einfügen und normal weiter
		lea     fmtcommands,a0          ;Command-Tab laden
		moveq   #0,d2                   ;ID Counter
.findloop       lea     (-1,a3),a2              ;a2: erstes Prüfzeichen
.innerfind      move.b  (a2),d0                 ;Prüflesen
		beq     .terminate              ; vorzeitiges Ende: terminieren
		cmpm.b  (a0)+,(a2)+             ;gleich?
		bne     .nextcmd                ; nein: nächstes Kommando prüfen
		cmp.b   #"$",d0                 ;war es Terminiert?
		bne     .innerfind              ; nein: weitermachen
	;-- Gefunden ---------------------------;
		move.l  d2,d0                   ;Kommando-Code holen
		sub.l   a0,a0                   ;keine Tags
		bsr     IdHardware              ;String holen
		tst.l   d0                      ;Fehler?
		beq     .copy                   ;dann ignorieren
		move.l  d0,a0                   ;sonst kopieren
.fcopy          cmp.l   a5,a4                   ;Ende erreicht?
		bhs     .terminate
		move.b  (a0)+,d0                ;Formatstring holen
		beq     .copy                   ;  beendet: weiterkopieren
		move.b  d0,(a4)+                ;sonst schreiben
		move.l  a2,a3
		bra     .fcopy                  ;und weitermachen
	;-- nächstes Kommando suchen -----------;
.nextcmd        subq.l  #1,a0                   ;a0 eins zurück
.nextloop       move.b  (a0)+,d0                ;nächstes Zeichen
		beq     .unknown                ;  Kommando unbekannt
		cmp.b   #"$",d0                 ;neues Kommando?
		bne     .nextloop
		tst.b   (a0)                    ;war's das?
		beq     .unknown
		addq.l  #1,d2                      ;ID counter
		bra     .findloop               ;und weitersuchen
	;-- Kommando unbekannt -----------------;
.unknown        move.b  (a3)+,d0                ;nach Escapechar suchen
		beq     .terminate
		cmp.b   #"$",d0
		bne     .unknown
		bra     .copy                   ;von dort aus weitermachen
	;-- Puffer terminieren -----------------;
.terminate      move.b  #0,(a4)+
		move.l  a4,d0
		sub.l   d7,d0                   ;Länge berechnen
.exit           movem.l (SP)+,d1-d7/a0-a6
		rts

	;== TABELLE DER KOMMANDONAMEN ==========;
		SAVE
		SECTION strings,DATA
fmtcommands     dc.b    "SYSTEM$CPU$FPU$MMU$"
		dc.b    "OSVER$EXECVER$WBVER$ROMSIZE$"
		dc.b    "CHIPSET$GFXSYS$CHIPRAM$FASTRAM$"
		dc.b    "RAM$SETPATCHVER$AUDIOSYS$OSNR$"
		dc.b    "VMMCHIPRAM$VMMFASTRAM$VMMRAM$PLNCHIPRAM$"
		dc.b    "PLNFASTRAM$PLNRAM$VBR$LASTALERT$"
		dc.b    "VBLANKFREQ$POWERFREQ$ECLOCK$SLOWRAM$"
		dc.b    "GARY$RAMSEY$BATTCLOCK$CHUNKYPLANAR$"
		dc.b    "POWERPC$PPCCLOCK$CPUREV$CPUCLOCK$"
		dc.b    "FPUCLOCK$RAMACCESS$RAMWIDTH$RAMCAS$"
		dc.b    "RAMBANDWIDTH$TCPIP$PPCOS$AGNUS$"
		dc.b    "AGNUSMODE$DENISE$DENISEREV$BOINGBAG$"
		dc.b    "EMULATED$XLVERSION$HOSTOS$HOSTVERS$"
		dc.b    "HOSTMACHINE$HOSTCPU$HOSTSPEED$"
		dc.b    0
		even
		RESTORE
*<
*-------------------------------------------------------*
* Name:         IdEstimateFormatSize                    *
*                                                       *
* Funktion:     Schätze Größe des Format-Puffers        *
*                                                       *
* Parameter:    -» a0.l ^Formatstring                   *
*               «- d0.l Puffer-Länge des Strings        *
*                       inkl. Nullterminator            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (11. März 1999, 01:03:18)           *
*                                                       *
		XDEF    IdEstimateFormatSize
IdEstimateFormatSize
		movem.l d1/a0,-(SP)
		moveq   #1,d0                   ;Counter
.loop           addq.l  #1,d0
		move.b  (a0)+,d1                ;Zeichen holen
		beq     .done
		cmp.b   #"$",d1                 ;Escape-Char?
		bne     .loop
		move.b  (a0)+,d1                ;Folgezeichen?
		beq     .done
		cmp.b   #"$",d1                 ;weiteres Dollar?
		beq     .loop
		add.l   #IDENTIFYBUFLEN,d0      ;Länge auf Buffersize hinzufügen
.seek           move.b  (a0)+,d1                ;Ende suchen
		beq     .done
		cmp.b   #"$",d1
		bne     .seek
		bra     .loop
.done           addq.l  #6,d0                   ;Sicherheitsspanne
		movem.l (SP)+,d1/a0
		rts
*<

*---------------------------------------------------------------*
*       == SUBFUNKTIONEN ==                                     *
*                                                               *
*-------------------------------------------------------*
* Name:         do_System                               *
*                                                       *
* Funktion:     System auswerten (Amiga, DraCo usw.)    *
*                                                       *
* Parameter:    -» d0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
	defhws  a1000bonus,     "A1000 Bonus"     ;A1000 bonus resident
;       defhws  a3000bonus,     "A3000 bonus"     ;A3000 bonus resident
	defhws  a4000bonus,     "A4000 bonus"     ;A4000 bonus resident
	defhws  nd2scsiname,    "2nd.scsi.device" ;A4000T SCSI device
	defhws  cardresource,   "card.resource"   ;card resource
	defhws  cduiname,       "cdui.library"    ;cdui library
	defhws  dmacsemaphore,  "dmac.semaphore"  ;dmac semaphore
	defhws  nativename,     "native.library"  ;AmigaXL library
	defhws  a690id,         "A690ID"          ;A690ID resident

do_System       move    d0,d7
		move.l  (execbase,PC),a6                  ;Execbase
	;-- DraCo? -----------------------------;
		move.b  (flags_draco,PC),d0     ;DraCo?
		bne     .draco
	;-- AmigaXL ----------------------------;
		lea     (nativename,a4),a1
		moveq   #0,d0
		exec.q  OpenLibrary
		tst.l   d0
		beq     .no_amigaxl
		move.l  d0,a1
		exec.q  CloseLibrary
		bra     .amigaxl
	;-- UAE? -------------------------------;
.no_amigaxl     sub.l   a0,a0
		move    #1803,d0                ;UAE 1 (1803/??)
		moveq   #-1,d1
		expans  FindConfigDev
		tst.l   d0
		bne     .uae
		sub.l   a0,a0
		move    #$07DB,d0               ;UAE 2 ($07DB/$60)
		moveq   #$60,d1
		expans  FindConfigDev
		tst.l   d0
		bne     .uae
	;-- A4000 (OS 3.1) ---------------------;
		lea     (a4000bonus,a4),a1
		exec    FindResident
		tst.l   d0
		bne     .amiga4000
	;-- A3000 (OS 3.1) ---------------------;
	;        lea     (a3000bonus,a4),a1
	;        exec    FindResident
	;        tst.l   d0
	;        bne     .amiga3000
	;-- AGA? -------------------------------;
		move    $dff07c,d1              ;ID-Register lesen
		cmp.b   #$f8,d1
		bne     .no_aga
	;---- A4000 (OS 3.0) -------------------;
		lea     (a1000bonus,a4),a1  ;A1000 bonus unter OS3.0
		exec.q  FindResident
		tst.l   d0
		bne     .amiga4000
	;---- CD32 -----------------------------;
		lea     (cduiname,a4),a1    ;cdui.library
		moveq   #0,d0
		exec.q  OpenLibrary
		tst.l   d0
		beq     .no_cd32
		move.l  d0,a1
		exec.q  CloseLibrary
		bra     .cd32
	;---- A1200 ----------------------------;
.no_cd32        bra     .amiga1200              ;momentan nur diese Alternative
;;                lea     (cardresource,a4),a1  ;card.resource
;                exec    OpenResource
;                tst.l   d0
;                bne     .amiga1200
;                move.l  (execbase,PC),a0                  ;Memory-Liste durchsuchen!
;                lea     (MemList,a0),a0         ;^Erste MemHeader-Node
;                lea     (cardresource,a4),a1   ;Nach der card.resource suchen! 8)
;                exec    FindName
;                tst.l   d0
;                bne     .amiga1200
;        ;---- Walker?! -------------------------;
;                bra     .walker
	;-- ECS? -------------------------------;
.no_aga         cmp.b   #$fc,d1                 ;ECS?
		bne     .no_ecs                 ; nein: einfacher Amiga
	;---- A500 mit Viper 520 ---------------;
		sub.l   a0,a0
		move    #2157,d0                ;DCE (2157)
		moveq   #0,d1                   ;Viper 520 CD (0)
		expans  FindConfigDev           ; (Die Viper benutzt das Kick-ROM
		tst.l   d0                      ; vom A1200, daher card.resource)
		bne     .amiga500
	;---- A600 -----------------------------;
		lea     (cardresource,a4),a1    ;card.resource
		exec    OpenResource
		tst.l   d0
		bne     .amiga600
		move.l  (execbase,PC),a0        ;Memory-Liste durchsuchen!
		lea     (MemList,a0),a0         ;^Erste MemHeader-Node
		lea     (cardresource,a4),a1    ;Nach der card.resource suchen! 8)
		exec.q  FindName
		tst.l   d0
		bne     .amiga600
	;---- CDTV -----------------------------;
		exec.q  Forbid
		lea     (dmacsemaphore,a4),a1   ;dmac.semaphore
		exec.q  FindSemaphore
		exec.q  Permit
		tst.l   d0                      ;gibts sie?
		beq     .no_cdtv                ; ja: könnte CDTV oder A500 mit A570 sein
		lea     (a690id,a4),a1          ;A570 vorhanden?
		exec.q  FindResident
		tst.l   d0
		bne     .amiga500               ;ja: Amiga 500
		bra     .cdtv                   ;nein: CDTV
	;---- A3000 ----------------------------;
.no_cdtv        movem.l d1-d7/a0-a5,-(SP)
		lea     (.getramsey,PC),a5      ;im Supervisor
		exec.q  Supervisor
		movem.l (SP)+,d1-d7/a0-a5
		cmp.b   #$0d,d0                 ;Ramsey D ?
		beq     .amiga3000
		cmp.b   #$0f,d0                 ;Ramsey F ?
		beq     .amiga3000
	;---- A2000/o6o ------------------------;
		btst    #AFB_68060,d7           ;Nur Amiga 2000 kann auf 060 erweitert werden
		bne     .amiga2000
	;---- A500/A2000 ECS -------------------;
		bra     .amigaecs
	;-- OCS-Amiga --------------------------;
.no_ecs ;        move    $dff004,d0              ;OCS
	;        btst    #13,d0
	;        beq     .newamiga               ; nein: was dann?! :-)
	;---- A1000 ----------------------------;
		exec    Disable
		move    $dff002,d0              ;Custom-Chip-Spiegel
		move    $dc0002,d1
		exec.q  Enable
		cmp     d0,d1
		bne     .amigaocs
	;-- Identifiziert ----------------------;
.amiga1000      moveq   #IDSYS_AMIGA1000,d0
		rts

.amiga2000      moveq   #IDSYS_AMIGA2000,d0
		rts
.amigaocs       moveq   #IDSYS_AMIGAOCS,d0
		rts
.amigaecs       moveq   #IDSYS_AMIGAECS,d0
		rts
.amiga3000      moveq   #IDSYS_AMIGA3000,d0
		rts
.amiga500       moveq   #IDSYS_AMIGA500,d0
		rts
.cdtv           moveq   #IDSYS_CDTV,d0
		rts
.amiga600       moveq   #IDSYS_AMIGA600,d0
		rts
.amiga1200      moveq   #IDSYS_AMIGA1200,d0
		rts
.amiga4000      lea     (nd2scsiname,a4),a1     ;Vielleicht ein A4000T ?
		move.l  (execbase,PC),a6
		lea     (DeviceList,a6),a0
		exec    FindName
		tst.l   d0
		bne     .amiga4000t
		moveq   #IDSYS_AMIGA4000,d0
		rts
.cd32           moveq   #IDSYS_CD32,d0
		rts
.draco          moveq   #IDSYS_DRACO,d0
		rts
.uae            lea     (flags_emulated,PC),a0
		st      (a0)
		moveq   #IDSYS_UAE,d0
		rts
.amigaxl        lea     (flags_emulated,PC),a0
		st      (a0)
		moveq   #IDSYS_AMIGAXL,d0
		rts
.amiga4000t     moveq   #IDSYS_AMIGA4000T,d0
.done           rts
	;==== Prüfe auf RAMSEY==================;
		cnop    0,4
.getramsey      lea     $de0003,a0              ;^Ramsey in A0
		move.b  ($40,a0),d0
		nop
		rte
*<
*-------------------------------------------------------*
* Name:         do_CPU                                  *
*                                                       *
* Funktion:     CPU auswerten (68000 ...)               *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_CPU          move    d0,d2
		btst    #AFB_68060,d2
		bne     .found060
		btst    #AFB_68040,d2
		bne     .found040
		moveq   #IDCPU_68030,d0
		btst    #AFB_68030,d2
		bne     .found
		moveq   #IDCPU_68020,d0
		btst    #AFB_68020,d2
		bne     .found
		moveq   #IDCPU_68010,d0
		btst    #AFB_68010,d2
		bne     .found
		moveq   #IDCPU_68000,d0
.found          rts
	;-- 68060 / 68LC060 --------------------;
.found060       moveq   #IDCPU_68060,d0
		btst    #AFB_FPU60,d2
		bne     .found
		moveq   #IDCPU_68LC060,d0
		rts
	;-- 68040 / 68LC040 --------------------;
.found040       moveq   #IDCPU_68040,d0
		btst    #AFB_FPU40,d2
		bne     .found
		moveq   #IDCPU_68LC040,d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_FPU                                  *
*                                                       *
* Funktion:     FPU auswerten (68881 ...)               *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_FPU          move    d0,d2
		moveq   #IDFPU_68060,d0
		btst    #AFB_68060,d2
		beq     .no68060
		btst    #AFB_FPU60,d2
		bne     .found
.no68060        moveq   #IDFPU_68040,d0
		btst    #AFB_68040,d2
		beq     .no68040
		btst    #AFB_FPU40,d2
		bne     .found
.no68040        moveq   #IDFPU_68882,d0
		btst    #AFB_68882,d2
		bne     .found
		moveq   #IDFPU_68881,d0
		btst    #AFB_68881,d2
		bne     .found
		moveq   #IDFPU_NONE,d0
.found          rts
*<
*-------------------------------------------------------*
* Name:         do_MMU                                  *
*                                                       *
* Funktion:     MMU auswerten (68030 ...)               *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_MMU          move    d0,d2
		moveq   #IDMMU_68060,d0
		btst    #AFB_68060,d2
		bne     .found
		moveq   #IDMMU_68040,d0
		btst    #AFB_68040,d2
		bne     .found
		moveq   #IDMMU_68030,d0
		btst    #AFB_68030,d2
		bne     .found                  ;; Nur zum Test
;                bne     .checkit
;                moveq   #IDMMU_68851,d0
;                btst    #AFB_68020,d2
;                beq     .none
;.checkit        bsr     .test_mmu
;                beq     .found
.none           moveq   #IDMMU_NONE,d0
.found          rts

;        ;== MMU-Test ===========================;
;        ; <- Zeroflag=Gefunden ~Zeroflag=keine MMU
;.test_mmu       movem.l d1-d7/a0-a6,-(sp)
;                sub.l   a1,a1                   ;Task herausbekommen
;                exec    FindTask
;                move.l  d0,a5
;                move.l  (TC_TRAPCODE,a5),d7     ;Trapcode merken
;                lea     (.mmu_trap,PC),a1
;                move.l  a1,(TC_TRAPCODE,a5)     ;eigenen setzen
;                subq.l  #4,sp                   ;Stack erniedrigen
;                pmove   tc,(sp)                 ;Hier gibt's die Exception
;                addq.l  #4,sp                   ;Stack ausgleichen
;                move.l  d7,(TC_TRAPCODE,a5)     ;Alten Trapcode restaurieren
;                cmp     #8,d0                   ;Privilegverletzung?
;                movem.l (sp)+,d1-d7/a0-a6       ;+CCR
;                rts
;                cnop    0,4
;.mmu_trap       move.l  (sp)+,d0                ;Exception-Nummer holen
;.trap_exit      addq.l  #4,(2,SP)               ;Bösen Befehl überspringen
;                nop
;                rte                             ;das war's
*<
*-------------------------------------------------------*
* Name:         do_OsVer                                *
*                                                       *
* Funktion:     OS-Version (V37.175)                    *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_OsVer
	;-- Os-Version auslesen ----------------;
;                move.l  $ffffec,d0              ;ROM-Size
;                lea     $1000000,a0             ;ROM-Ende
;                sub.l   d0,a0                   ;ROM-Start
		move.l  (execbase,PC),a0                  ; des MOMENTANEN OS
		move.l  (LIB_IDSTRING,a0),d0
		and.l   #$FFFFFC00,d0
		move.l  d0,a0
		move    (14,a0),d0              ;Revision
		swap    d0
		move    (12,a0),d0              ;Version
		rts
*<
*-------------------------------------------------------*
* Name:         do_ExecVer                              *
*                                                       *
* Funktion:     Exec-Version auswerten (V??.??)         *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_ExecVer
	;-- Exec-Version auslesen --------------;
		move.l  (execbase,PC),a0
		moveq   #0,d0
		move    (LIB_REVISION,a0),d0
		swap    d0
		move    (LIB_VERSION,a0),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_WbVer                                *
*                                                       *
* Funktion:     Workbench-Version auswerten (V??.??)    *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
	defhws  versionname,"version.library"

do_WbVer
	;-- Wb-Version auslesen ----------------;
		lea     (versionname,a4),a1    ;Version
		moveq   #0,d0
		exec    OpenLibrary
		move.l  d0,a1
		tst.l   d0
		beq     .none
		move    (LIB_REVISION,a1),d2
		swap    d2
		move    (LIB_VERSION,a1),d2
		exec.q  CloseLibrary
		move.l  d2,d0
		rts
	;-- String erzeugen --------------------;
.none           moveq   #0,d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_OsNr                                 *
*                                                       *
* Funktion:     OS-Version (OS3.1)                      *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (17. Februar 1997, 02:43:22)        *
*                                                       *
	;-- Strings ----------------------------;
     ;   defhws  versionname,"version.library"  ; von do_WbVer

do_OsNr
	;-- Os-Version auslesen ----------------;
		bsr     .get_version
		moveq   #IDOS_3_9,d2            ;OS3.9 ?
		cmp     #45,d0
		beq     .found
		moveq   #IDOS_3_5,d2            ;OS3.5 ?
		cmp     #44,d0
		beq     .found
		moveq   #IDOS_2_1,d2            ;OS2.1 ?
		cmp     #38,d0
		beq     .found
	; Kein Software-Update
	;--- Hardware-Version prüfen -----------;
;                move.l  $ffffec,d0              ;ROM-Size
;                lea     $1000000,a0             ;ROM-Ende
;                sub.l   d0,a0                   ;ROM-Start
		move.l  (execbase,PC),a0                  ; des MOMENTANEN OS
		move.l  (LIB_IDSTRING,a0),d0
		and.l   #$FFFFFC00,d0
		move.l  d0,a0
		moveq   #0,d1
		move    (12,a0),d1              ;Version
		moveq   #IDOS_UNKNOWN,d2        ;Unknown
		sub.l   #36,d1                  ;<36
		bcs     .found
		cmp.l   #4,d1                   ;>40
		bhi     .found
		addq.l  #1,d1
		move.l  d1,d2
.found          move.l  d2,d0
		rts
	;== Holt die OS-Version ================;
.get_version    movem.l d1-d2/a0-a2,-(SP)
		lea     (versionname,a4),a1     ;Version
		moveq   #0,d0
		exec.q  OpenLibrary
		move.l  d0,a1
		tst.l   d0
		beq     .none35
		moveq   #0,d2
		move    (LIB_VERSION,a1),d2
		exec    CloseLibrary
.none35         move.l  d2,d0
		movem.l (SP)+,d1-d2/a0-a2
		rts
*<
*-------------------------------------------------------*
* Name:         do_RomSize                              *
*                                                       *
* Funktion:     ROM-Größe auswerten (KB)                *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_RomSize
	;-- Vom aktuellen OS -------------------;
		move.l  (execbase,PC),a0                  ; des MOMENTANEN OS
		move.l  (LIB_IDSTRING,a0),d0
		and.l   #$FFFFFC00,d0
		move.l  d0,a0                   ;Startadresse
		move    (a0),d0
		cmp     #$1111,d0               ;256K?
		beq     .is256k
		cmp     #$1114,d0               ;512K?
		beq     .is512k
	;-- ROM-Größe auslesen -----------------;
		move.l  $ffffec,d0              ;ROM size
	;-- Fertig -----------------------------;
.correct        rts
	;-- Feste Puffergröße ------------------;
.is256k         moveq   #$4,d0                  ; = $40000 = 256KB
		swap    d0
		bra     .correct
.is512k         moveq   #$8,d0                  ; = $80000 = 512KB
		swap    d0
		bra     .correct
*<
*-------------------------------------------------------*
* Name:         do_Chipset                              *
*                                                       *
* Funktion:     Chipset auswerten (ECS,AGA,Altais)      *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_Chipset      moveq   #IDCS_ALTAIS,d0
		move.b  (flags_draco,PC),d1     ; bei DraCo
		bne     .done
	;-- AGA --------------------------------;
		move    $dff07c,d1              ;LISAID
		and     #$000F,d1               ; nur die Typ-Bits maskieren
		moveq   #IDCS_AGA,d0
		cmp     #$0008,d1               ;Lisa?
		beq     .done
	;-- ECS/NECS ---------------------------;
		cmp     #$000c,d1               ;HR-Denise
		seq     d2
		move    $dff004,d1              ;VPOSR
		btst    #13,d1                  ;HR-Agnus
		sne     d3
		move.b  d3,d1                   ;Prüfen auf ECS
		and.b   d2,d1
		bne     .done_ecs
		or.b    d3,d2
		beq     .done_ocs
		moveq   #IDCS_NECS,d0           ;Nearly ECS
		rts
.done_ecs       moveq   #IDCS_ECS,d0            ;ECS
		rts
.done_ocs       moveq   #IDCS_OCS,d0            ;OCS
.done           rts

*<
*-------------------------------------------------------*
* Name:         do_GfxSys                               *
*                                                       *
* Funktion:     Graphics OS (CyberGraphX)               *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
	defhws  gfx_cgx3,       "cgxsystem.library"      ;CyberGraphX 3
	defhws  gfx_cybergfx,   "cybergraphics.library"  ;CyberGraphX
	defhws  gfx_egs,        "egs.library"            ;EGS
	defhws  gfx_tiga,       "gfx.library"            ;Tiga
	defhws  gfx_graffiti,   "graffiti.library"       ;Graffiti
	defhws  gfx_hrgblitter, "hrgblitter.library"     ;ProBench
	defhws  gfx_retina,     "retina.library"         ;Retina
	defhws  gfx_picasso,    "vilintuisup.library"    ;Picasso
	defhws  gfx_pic96,      "rtg.library"            ;Picasso96
	defhws  cyber_name,     "ENVARC:CyberGraphics"   ;Drawer für CGX

do_GfxSys       move.l  (execbase,PC),a6                  ;^Lib-Liste holen
		lea     (LibList,a6),a3
	;-- Picasso96 --------------------------;
		move.l  #IDGOS_PICASSO96,d3
		lea     (gfx_pic96,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		bne     .found
	;-- ProBench? --------------------------;
		move.l  #IDGOS_PROBENCH,d3
		lea     (gfx_hrgblitter,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		bne     .found
	;-- CGX 3/4 ? --------------------------;
		lea     (gfx_cgx3,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		beq     .nocgx
		move.l  d0,a0
		move.l  #IDGOS_CGX3,d3
		cmp     #42,(LIB_VERSION,a0)
		blt     .found
		move.l  #IDGOS_CGX4,d3
		bra     .found
	;-- CyberGraphX? -----------------------;
.nocgx          move.l  #IDGOS_CGX,d3
		lea     (gfx_cybergfx,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		beq     .nocybergfx
		lea     (cyber_name,a4),a0      ;Env-Variable da?
		move.l  a0,d1
		moveq   #ACCESS_READ,d2
		dos     Lock
		move.l  d0,d1
		beq     .nocybergfx
		dos     UnLock
		bra     .found
	;-- EGS? -------------------------------;
.nocybergfx     move.l  #IDGOS_EGS,d3
		lea     (gfx_egs,a4),a1
		move.l  a3,a0
		exec    FindName                ;KEIN exec.q !!!!
		tst.l   d0
		bne     .found
	;-- Retina? ----------------------------;
		move.l  #IDGOS_RETINA,d3
		lea     (gfx_retina,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		bne     .found
	;-- Graffiti? --------------------------;
		move.l  #IDGOS_GRAFFITI,d3
		lea     (gfx_graffiti,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		bne     .found
	;-- TIGA? ------------------------------;
		move.l  #IDGOS_TIGA,d3
		lea     (gfx_tiga,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		bne     .found
	;-- Picasso? ---------------------------;
		move.l  #IDGOS_PICASSO,d3
		lea     (gfx_picasso,a4),a1
		move.l  a3,a0
		exec.q  FindName
		tst.l   d0
		bne     .found
	;-- Keins davon ------------------------;
		move.l  #IDGOS_AMIGAOS,d3
.found          move.l  d3,d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_AudioSys                             *
*                                                       *
* Funktion:     Audio OS (MacroAudio)                   *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (17. Februar 1997, 02:17:04)        *
*                                                       *
	;-- Strings ----------------------------;
	defhws  audio_maestix,  "maestix.library"       ;Maestix
	defhws  audio_toccata,  "toccata.library"       ;Toccata
	defhws  audio_prelude,  "prelude.library"       ;Prelude
	defhws  audio_maudio,   "macroaudio.library"    ;MacroAudio
	defhws  ahi_name,       "devs:AHI"              ;Drawer für AHI

do_AudioSys
	;-- AHI --------------------------------;
		move.l  #IDAOS_AHI,d3
		lea     (ahi_name,a4),a0        ;Datei da?
		move.l  a0,d1
		moveq   #ACCESS_READ,d2
		dos     Lock
		move.l  d0,d1
		beq     .noahi
		dos     UnLock
		bra     .found
	;-- MacroAudio -------------------------;
.noahi          move.l  #IDAOS_MACROAUDIO,d3
		lea     (audio_maudio,a4),a1
		moveq   #0,d0
		exec    OpenLibrary
		tst.l   d0
		bne     .found2
	;-- Maestix ----------------------------;
		move.l  #IDAOS_MAESTIX,d3
		lea     (audio_maestix,a4),a1
		moveq   #0,d0
		exec.q  OpenLibrary
		tst.l   d0
		bne     .found2
	;-- Toccata ----------------------------;
		move.l  #IDAOS_TOCCATA,d3
		lea     (audio_toccata,a4),a1
		moveq   #0,d0
		exec.q  OpenLibrary
		tst.l   d0
		bne     .found2
	;-- Prelude ----------------------------;
		move.l  #IDAOS_PRELUDE,d3
		lea     (audio_prelude,a4),a1
		moveq   #0,d0
		exec.q  OpenLibrary
		tst.l   d0
		bne     .found2
	;-- Keins davon ------------------------;
		move.l  #IDAOS_AMIGAOS,d3
		bra     .found
.found2         move.l  d0,a1                   ;Schließe Library
		exec.q  CloseLibrary
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_ChipRAM                              *
*                                                       *
* Funktion:     ChipRAM auswerten                       *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_ChipRAM      move.l  (mem_chip_plain,PC),d0
		add.l   (mem_chip_vmm,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_FastRAM                              *
*                                                       *
* Funktion:     FastRAM auswerten                       *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_FastRAM      move.l  (mem_fast_plain,PC),d0
		add.l   (mem_fast_vmm,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_RAM                                  *
*                                                       *
* Funktion:     Gesamtes RAM auswerten                  *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_RAM          move.l  (mem_all_plain,PC),d0
		add.l   (mem_all_vmm,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_VMChipRAM                            *
*                                                       *
* Funktion:     Virtual ChipRAM auswerten               *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_VMChipRAM    move.l  (mem_chip_vmm,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_VMFastRAM                            *
*                                                       *
* Funktion:     Virtual FastRAM auswerten               *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_VMFastRAM    move.l  (mem_fast_vmm,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_VMRAM                                *
*                                                       *
* Funktion:     Gesamtes Virtual RAM auswerten          *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_VMRAM        move.l  (mem_all_vmm,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_PlainChipRAM                         *
*                                                       *
* Funktion:     Reines ChipRAM auswerten                *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_PlainChipRAM move.l  (mem_chip_plain,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_PlainFastRAM                         *
*                                                       *
* Funktion:     Reines FastRAM auswerten                *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_PlainFastRAM move.l  (mem_fast_plain,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_PlainRAM                             *
*                                                       *
* Funktion:     Gesamtes Reines RAM auswerten           *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_PlainRAM     move.l  (mem_all_plain,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_SetPatchVer                          *
*                                                       *
* Funktion:     SetPatch-Version lesen                  *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
		rsreset         ;SetPatchSemaphore
sps_Sem         rs.b    SS_SIZE         ;Signal Semaphore
sps_Private     rs.b    MLH_SIZE        ;MinList (Privat)
sps_Version     rs.w    1               ;Version
sps_Revision    rs.w    1               ;Revision
sps_SIZEOF      rs.w    0

	defhws  semaphore,      "« SetPatch »"  ;SetPatch Semaphore

do_SetPatchVer
	;-- Semaphore suchen -------------------;
		exec    Forbid                  ;Semaphore suchen
		lea     (semaphore,a4),a1
		exec.q  FindSemaphore
		tst.l   d0
		beq     .na                     ;Nicht verfügbar
		move.l  d0,a0
	;-- Version ausfüllen ------------------;
		moveq   #0,d0
		move    (sps_Revision,a0),d0    ;Revision
		swap    d0
		move    (sps_Version,a0),d0     ;Version
		exec.q  Permit
		bra     .doit
	;-- String erzeugen --------------------;
.na             exec.q  Permit
		moveq   #0,d0
	;-- Fertig -----------------------------;
.doit           rts
*<
*-------------------------------------------------------*
* Name:         do_VBR                                  *
*                                                       *
* Funktion:     VBR lesen                               *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_VBR          lea     buildflags,a0
		sf      (IDHW_VBR,a0)           ;Kein Caching
		btst    #AFB_68010,d0           ;68010 oder höher
		beq     .no_vbr
		lea     (.vbr_trap,PC),a5
		exec    Supervisor
		rts
	;-- Kein VBR ---------------------------;
.no_vbr         moveq   #0,d0                   ;VBR = 0
		rts
	;-- Lese VBR-Register ------------------;
		cnop    0,4
.vbr_trap       movec.l vbr,d0                  ;VBR lesen
		nop
		rte                             ;das war's
*<
*-------------------------------------------------------*
* Name:         do_LastAlert                            *
*                                                       *
* Funktion:     Liest LastAlert                         *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_LastAlert    lea     buildflags,a0
		sf      (IDHW_LASTALERT,a0)     ;Kein Caching
		move.l  (execbase,PC),a0        ;In Execbase schauen
		move.l  (LastAlert,a0),d0       ;Alert gefunden
		cmp.l   #-1,d0                  ;keiner drin?
		bne     .showalert
		bsr     dola_get100
		btst    #31,d0                  ;Deadend sollte er sein!
		bne     .showalert
		moveq   #-1,d0                  ;kein Alert da
.showalert      rts

	;== Holt den Wert von $100, möglichst über Blitter,
	;   damit ein Enforcerhit vermieden wird. Die Leute
	;   nerven langsam damit... :-(
dola_get100     move.b  (flags_draco,PC),d0     ;DraCo?
		bne     .noblit                 ;  hat keinen Blitter
		moveq   #8,d0                   ;8 Bytes
		move.l  #MEMF_CHIP,d1           ; Chip-RAM
		exec    AllocMem
		move.l  d0,a3
		tst.l   d0                      ;bekommen?
		beq     .noblit
	;-- Blitter vorbereiten ----------------;
		gfx     OwnBlitter              ;Leider nicht so schön, aber schnell
		gfx     WaitBlit
		lea     $dff000,a2              ;Chipset-Basisadresse
		move.l  a3,($054,a2)            ;Ziel: Chip-RAM
		moveq   #0,d0
		move.l  d0,($064,a2)            ;Kein Modulo
		move    #$0100,d0
		move.l  d0,($050,a2)            ;Quelle: Guru-Adresse
		moveq   #-1,d0
		move.l  d0,($044,a2)            ;Maske: alle Bits gesetzt
		move.l  #$09F00000,($040,a2)    ;DMAA DMAD, Miniterm Axx=1 axx=0
		move    #$0042,($058,a2)        ;Size = 1x2
		gfx     WaitBlit
		gfx     DisownBlitter
		move.l  (a3),d3                 ;Chip-Speicher freigeben
		move.l  a3,a1
		moveq   #8,d0
		exec    FreeMem
		move.l  d3,d0                   ;und Ergebnis liefern
		rts
	;-- Kein Blitter vorhanden -------------;
.noblit         move.l  $100.w,d0               ;Sei's drum...
		rts
*<
*-------------------------------------------------------*
* Name:         do_VBlankFreq                           *
*                                                       *
* Funktion:     Liest VBlank-Frequenz                   *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_VBlankFreq   move.l  (execbase,PC),a0
		moveq   #0,d0
		move.b  (VBlankFrequency,a0),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_PowerFreq                            *
*                                                       *
* Funktion:     Liest Power-Frequenz                    *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_PowerFreq    move.l  (execbase,PC),a0
		moveq   #0,d0
		move.b  (PowerSupplyFrequency,a0),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_EClock                               *
*                                                       *
* Funktion:     Liest E-Frequenz                        *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_EClock       move.l  (execbase,PC),a0
		move.l  (ex_EClockFrequency,a0),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_SlowRAM                              *
*                                                       *
* Funktion:     Liest SlowRAM                           *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_SlowRAM      moveq   #0,d0
		move.l  (execbase,PC),a0
		move.l  (MemList,a0),a0         ;^Erste MemHeader-Node
	;-- Speicherliste durchgehen -----------;
.getramloop     tst.l   (a0)                    ;Ende?
		beq     .getramdone
	;-- Richtiger Speichertyp ? ------------;
		move.l  (MH_LOWER,a0),d1        ;Richtige Adresse?
		and.l   #$FFFFF000,d1
		cmp.l   #$00C00000,d1
		bne     .getramnext
	;-- Blockgröße berechnen ---------------;
		move.l  (MH_UPPER,a0),d0        ;Speichergröße
		sub.l   #MH_SIZE,d1
		sub.l   d1,d0
		bra     .getramdone
	;-- Nächste Node -----------------------;
.getramnext     move.l  (a0),a0                 ;^Nächste Node
		bra     .getramloop
	;-- Fertig -----------------------------;
.getramdone     rts
*<
*-------------------------------------------------------*
* Name:         do_Gary                                 *
*                                                       *
* Funktion:     Schaut nach GARY                        *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_Gary         move.b  (flags_draco,PC),d1     ; bei DraCo
		bne     .none
	;-- Prüfen -----------------------------;
		lea     (.garytest,PC),a5
		exec    Supervisor
		tst.b   d0                      ;Normal?
		beq     .normal
		cmp.b   #$90,d0                 ;Enhanced?
		beq     .enhanced
.none           moveq   #IDGRY_NONE,d0
		rts
.normal         moveq   #IDGRY_NORMAL,d0
		rts
.enhanced       moveq   #IDGRY_ENHANCED,d0
		rts

	;-- Gary-Test --------------------------;
		cnop    0,4
.garytest       lea     $de1002,a0
		moveq   #0,d0
		moveq   #7,d1
		move.b  d0,(a0)
.garyloop       move.b  (a0),d2
		lsl.b   #1,d2
		roxl.b  #1,d0
		dbra    d1,.garyloop
		nop
		rte
*<
*-------------------------------------------------------*
* Name:         do_Ramsey                               *
*                                                       *
* Funktion:     Schaut nach RAMSEY                      *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_Ramsey       move.b  (flags_draco,PC),d1     ; bei DraCo
		bne     .none
	;-- Prüfen -----------------------------;
		lea     (.ramseytest,PC),a5
		exec    Supervisor
		cmp.b   #$0d,d0                 ;Revision D ?
		beq     .rev_d
		cmp.b   #$0f,d0                 ;Revision F ?
		beq     .rev_f
.none           moveq   #IDRSY_NONE,d0
		rts
.rev_d          moveq   #IDRSY_REVD,d0
		rts
.rev_f          moveq   #IDRSY_REVF,d0
		rts

	;-- Ramsey-Test ------------------------;
		cnop    0,4
.ramseytest     move.b  $de0043,d0              ;Ramsey-Revision
		nop
		rte
*<
*-------------------------------------------------------*
* Name:         do_BattClock                            *
*                                                       *
* Funktion:     Schaut nach Battery Backed Up Clock     *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
	defhws  battclockname,  "battclock.resource"    ;Resource

do_BattClock    lea     (battclockname,a4),a1
		exec    OpenResource
		tst.l   d0                      ;Resource vorhanden?
		beq     .noclock
		move.l  d0,a6                   ;Clock ermitteln
		jsr     (-12,a6)                ;ReadBattClock()
		tst.l   d0                      ; okay?
		beq     .noclock
	;-- Clock vorhanden --------------------;
		moveq   #1,d0                   ;Ergebnis ist Boolean
		rts
	;-- Clock nicht vorhanden --------------;
.noclock        moveq   #0,d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_ChunkyPlanar                         *
*                                                       *
* Funktion:     Schaut nach Chunky/Planar-Hardware      *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
	defhws  sgfxname,"graphics.library"

do_ChunkyPlanar lea     (sgfxname,a4),a1        ;gfx öffnen
		moveq   #40,d0                  ; ab OS3.1 !!!
		exec    OpenLibrary
		tst.l   d0
		beq     .nohw
		move.l  d0,a1
		move.l  (gb_ChunkyToPlanarPtr,a1),d3    ;Pointer merken
		exec.q  CloseLibrary
		tst.l   d3                      ;vorhanden?
		beq     .nohw
	;-- Hardware vorhanden -----------------;
		moveq   #1,d0                   ;Ergebnis ist Boolean
		rts
	;-- Hardware nicht vorhanden -----------;
.nohw           moveq   #0,d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_PowerPC                              *
*                                                       *
* Funktion:     Findet PowerPC heraus                   *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
	defhws  warpname,"powerpc.library"
	defhws  ppcname,"ppc.library"

do_PowerPC
	;-- Check for PowerUP ------------------;
		move.l  4.w,a6
		lea     (LibList,a6),a0
		lea     (ppcname,a4),a1         ;ist bereits PowerUP geladen?
		exec.q  FindName
		tst.l   d0
		bne     .nowarp                 ;dann direkt benutzen
	;-- WarpOS -----------------------------;
		lea     (warpname,a4),a1
		moveq   #7,d0
		exec    OpenLibrary
		tst.l   d0
		beq     .nowarp
		move.l  d0,a6
		jsr     (-42,a6)                ;GetCPU()
		move.l  d0,d2
		move.l  a6,a1
		exec    CloseLibrary
		lea     (.warptype,PC),a0
		lea     (.warpbit,PC),a1
		moveq   #0,d0
.warploop       move.b  (a0)+,d0
		move.b  (a1)+,d1
		bmi     .other
		btst    d1,d2
		beq     .warploop
		rts
	;-- PowerUP ----------------------------;
.nowarp         lea     (ppcname,a4),a1         ;ppc öffnen
		moveq   #40,d0
		exec    OpenLibrary
		tst.l   d0
		beq     .noppc
		move.l  d0,a6
		lea     (.ppctags,PC),a0
		jsr     (-138,a6)
		move.l  d0,d2
		move.l  a6,a1
		exec    CloseLibrary
		subq.l  #3,d2
		bcs     .other
		moveq   #6,d0
		cmp.l   d0,d2
		bgt     .other
		move.l  d2,d0
		lea     (.ppctype,PC),a0
		move.b  (a0,d0.w),d0            ;Typ holen
		rts
	;-- Hardware vorhanden -----------------;
.other          moveq   #IDPPC_OTHER,d0
		rts
	;-- Hardware nicht vorhanden -----------;
.noppc          moveq   #IDPPC_NONE,d0
		rts
	;-- Strings ----------------------------;
		cnop    0,4
.ppctags        dc.l    $8001F001,0,TAG_DONE
.ppctype        dc.b    IDPPC_603,IDPPC_604,IDPPC_602,IDPPC_603E,IDPPC_603P,IDPPC_OTHER,IDPPC_604E
.warpbit        dc.b    20,16,12,8,4,-1
.warptype       dc.b    IDPPC_620,IDPPC_604E,IDPPC_604,IDPPC_603E,IDPPC_603
		even
*<
*-------------------------------------------------------*
* Name:         do_PPCClock                             *
*                                                       *
* Funktion:     Schaut nach PowerPC-Takt                *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
   ;;     defhws  ppcname,"ppc.library"         ; von do_PowerPC

do_PPCClock     move.l  4.w,a6                  ;ist WarpUp geladen?
		lea     (LibList,a6),a0
		lea     (warpname,a4),a1
		exec.q  FindName
		tst.l   d0
		bne     .noppc                  ;  dann gibt's keinen Takt
	;-- Takt ermitteln ---------------------;
		lea     (ppcname,a4),a1         ;ppc öffnen
		moveq   #40,d0
		exec    OpenLibrary
		tst.l   d0
		beq     .noppc
		move.l  d0,a6
		lea     (.ppctags,PC),a0
		jsr     (-138,a6)
		move.l  d0,d2
		move.l  a6,a1
		exec    CloseLibrary
		move.l  d2,d0
		rts
	;-- Hardware nicht vorhanden -----------;
.noppc          movem.l d4-d7,-(SP)
		jsr     _PPC_CPU_Clock          ;Über WarpUP testen
		movem.l (SP)+,d4-d7
		tst.l   d0                      ; nichts?
		beq     .nowarp
		IFD     _MAKE_68020
		 divu.l #1000000,d0
		ELSE
		 move.l #1000000,d1             ;eigentlich ja Blödsinn... wer hat schon
		 utils  UDivMod32               ; einen PowerPC mit 68000 als Companion?
		ENDC
.nowarp         rts                             ;.nowarp: d0.l = 0
	;-- Strings ----------------------------;
		cnop    0,4
.ppctags        dc.l    $8001F003,0,TAG_DONE
*<
*-------------------------------------------------------*
* Name:         do_CPURev                               *
*                                                       *
* Funktion:     CPU-Revision (N/A, 1, ...)              *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. September 1997, 14:04:32)      *
*                                                       *
do_CPURev       btst    #AFB_68060,d0
		bne     .found060
		moveq   #-1,d0                  ;keine Revision
		rts
	;-- 68060 / 68LC060 --------------------;
.found060       lea     (.getcpurev,PC),a5
		exec    Supervisor
		lsr     #8,d0
		and.l   #$FF,d0
		rts
	;-- Auswertungs-Code -------------------;
		cnop    0,4
.getcpurev      movec.l pcr,d0
		nop
		rte
*<
*-------------------------------------------------------*
* Name:         do_CPUClock                             *
*                                                       *
* Funktion:     CPU-Taktrate                            *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. September 1997, 14:04:32)      *
*                                                       *
do_CPUClock     bsr     CalcClock
		move.l  (cpuclk,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_FPUClock                             *
*                                                       *
* Funktion:     FPU-Taktrate                            *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. September 1997, 14:04:32)      *
*                                                       *
do_FPUClock     bsr     CalcClock
		move.l  (fpuclk,PC),d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_RAMAccess                            *
*                                                       *
* Funktion:     RAM-Zugriffszeit                        *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. September 1997, 14:04:32)      *
*                                                       *
do_RAMAccess    moveq   #80,d0                  ;80ns
		move.b  (flags_draco,PC),d1     ;DraCo?
		bne     .done                   ; hat nur 80ns
		lea     (.getramsey,PC),a5
		exec    Supervisor
.done           rts
	;-- Ramsey-Zustand ---------------------;
		cnop    0,4
.getramsey      lea     $de0003,a0              ;^Ramsey in a1
		cmp.b   #$0f,$40(a0)            ;Richtig?
		bne     .ramseydone             ;  falsch -> RAUS!
		btst    #4,(a0)                 ;An oder aus?
		beq     .ramseydone
		moveq   #60,d0                  ;60ns
.ramseydone     nop
		rte
*<
*-------------------------------------------------------*
* Name:         do_RAMWidth                             *
*                                                       *
* Funktion:     RAM-Busbreite                           *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. September 1997, 14:04:32)      *
*                                                       *
do_RAMWidth     moveq   #16,d0                  ;80ns
		move.l  (gfxbase,PC),a0
		btst    #0,(gb_MemType,a0)
		beq     .done
		moveq   #32,d0
.done           rts
*<
*-------------------------------------------------------*
* Name:         do_RAMCAS                               *
*                                                       *
* Funktion:     RAM CAS mode                            *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. September 1997, 14:04:32)      *
*                                                       *
do_RAMCAS       moveq   #IDCAS_NORMAL,d0
		move.l  (gfxbase,PC),a0
		btst    #1,(gb_MemType,a0)
		beq     .done
		moveq   #IDCAS_DOUBLE,d0
.done           rts
*<
*-------------------------------------------------------*
* Name:         do_RAMBandwidth                         *
*                                                       *
* Funktion:     RAM Bandbreite                          *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. September 1997, 14:04:32)      *
*                                                       *
do_RAMBandwidth moveq   #1,d0
		move.l  (gfxbase,PC),a0
		move.b  (gb_MemType,a0),d1
		and.b   #%11,d1
		beq     .done
		moveq   #4,d0
		cmp.b   #%11,d1
		beq     .done
		moveq   #2,d0
.done           rts
*<
*-------------------------------------------------------*
* Name:         do_TCPIP                                *
*                                                       *
* Funktion:     TCP/IP Stack (Miami)                    *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (17. Februar 1997, 02:17:04)        *
*                                                       *
	;-- Strings ----------------------------;
	defhws  tcp_miami,      "miami.library"         ;Miami
	defhws  tcp_termite,    "tsocket.library"       ;Termite
	defhws  tcp_genesis,    "genesis.library"       ;Genesis
	defhws  tcp_amitcp,     "bsdsocket.library"     ;AmiTCP
	defhws  tcp_miamidx,    "MiamiDx"               ;Miami Deluxe

do_TCPIP        lea     buildflags,a0
		sf      (IDHW_TCPIP,a0)         ;Kein Caching
	;-- Miami ------------------------------;
		move.l  #IDTCP_MIAMI,d3
		lea     (tcp_miami,a4),a1
		moveq   #0,d0
		exec    OpenLibrary
		tst.l   d0
		beq     .no_miami
		move.l  d0,a1
		exec.q  CloseLibrary
		lea     (tcp_miamidx,a4),a1
		exec.q  Forbid
		exec.q  FindTask
		exec.q  Permit
		tst.l   d0
		beq     .found
		move.l  #IDTCP_MIAMIDX,d3
		bra     .found
	;-- Genesis ----------------------------;
.no_miami       move.l  #IDTCP_GENESIS,d3
		lea     (tcp_genesis,a4),a1
		moveq   #0,d0
		exec    OpenLibrary
		tst.l   d0
		bne     .found2
	;-- Termite ----------------------------;
		move.l  #IDTCP_TERMITE,d3
		lea     (tcp_termite,a4),a1
		moveq   #0,d0
		exec    OpenLibrary
		tst.l   d0
		bne     .found2
	;-- AmiTCP -----------------------------;
		move.l  #IDTCP_AMITCP,d3
		lea     (tcp_amitcp,a4),a1
		moveq   #0,d0
		exec    OpenLibrary
		tst.l   d0
		bne     .found2
	;-- Keins davon ------------------------;
		move.l  #IDTCP_NONE,d3
		bra     .found
.found2         move.l  d0,a1                   ;Schließe Library
		exec.q  CloseLibrary
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_PPCOS                                *
*                                                       *
* Funktion:     Findet PPCOS heraus                     *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
	;-- Strings ----------------------------;
	; defhws  warpname,"powerpc.library"    ; Siehe oben
	; defhws  ppcname,"ppc.library"

do_PPCOS        move.l  4.w,a6
		lea     (LibList,a6),a3
	;-- WarpOS -----------------------------;
		moveq   #IDPOS_WARPOS,d2
		lea     (warpname,a4),a1
		move.l  a3,a0
		exec    FindName
		tst.l   d0
		bne     .found
	;-- PowerUP ----------------------------;
		moveq   #IDPOS_POWERUP,d2
		lea     (ppcname,a4),a1
		move.l  a3,a0
		exec    FindName
		tst.l   d0
		bne     .found
	;-- Nichts -----------------------------;
		moveq   #IDPOS_NONE,d0
		rts
	;-- Gefunden ---------------------------;
.found          move.l  d2,d0
		rts
*<
*-------------------------------------------------------*
* Name:         do_Agnus                                *
*                                                       *
* Funktion:     Findet Agnus-Version heraus             *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_Agnus        moveq   #IDAG_NONE,d0
		move.b  (flags_draco,PC),d1     ; bei DraCo
		bne     .done
		move    $dff004,d1              ;VPOSR
		and     #$7f00,d1               ; Maskieren
		addq    #2,d0                   ;IDAG_8361 / IDAG_8370
		cmp     #$1000,d1
		beq     .tst_fat
		addq    #1,d0
		tst     d1                      ;IDAG_8367 / IDAG_8371
		beq     .tst_fat
		addq    #3,d0
		bclr    #12,d1                  ;PAL/NTSC egal
		sub     #$2000,d1
		bcs     .unknown
		cmp     #$0300,d1
		bhi     .unknown
		lsr     #8,d1
		add     d1,d0
.done           rts
.unknown        moveq   #IDAG_UNKNOWN,d0
		rts
.tst_fat        exec    Disable
		move    $dff002,d2              ;Custom-Chip-Spiegel
		move    $dc0002,d3
		exec.q  Enable
		cmp     d2,d3
		beq     .is_old
		addq    #2,d0
.is_old         rts
*<
*-------------------------------------------------------*
* Name:         do_AgnusMode                            *
*                                                       *
* Funktion:     Findet Agnus-Mode heraus                *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:13:04)            *
*                                                       *
do_AgnusMode    moveq   #IDAM_NONE,d0
		move.b  (flags_draco,PC),d1     ; bei DraCo
		bne     .done
		move    $dff004,d1
		moveq   #IDAM_NTSC,d0
		btst    #12,d1
		bne     .done
		moveq   #IDAM_PAL,d0
.done           rts
*<
*-------------------------------------------------------*
* Name:         do_Denise                               *
*                                                       *
* Funktion:     Findet Denise-Version heraus            *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (18. Oktober 1998, 14:32:24)        *
*                                                       *
do_Denise       moveq   #IDDN_NONE,d0
		move.b  (flags_draco,PC),d1     ; bei DraCo
		bne     .done
	;-- 8362 -------------------------------;
		moveq   #IDDN_8362,d0           ;IDDN_8362
		move    $dff07c,d1              ;LISAID
		and     #$00FF,d1
		move    $dff07c,d2
		and     #$00FF,d2
		cmp     d1,d2                   ;Muß gleich sein!
		bne     .done                   ;  nein -> ganz alte Denise
	;-- 8373 -------------------------------;
		and     #$000F,d1               ; nur die Version
		moveq   #IDDN_8373,d0           ;IDDN_8373 ?
		cmp     #$0C,d1
		beq     .done
	;-- 8364 (AGA) -------------------------;
		moveq   #IDDN_8364,d0           ;IDDN_8364
		cmp     #$08,d1
		beq     .done
	;-- Irgendwas anderes ------------------;
.unknown        moveq   #IDDN_UNKNOWN,d0
.done           rts
*<
*-------------------------------------------------------*
* Name:         do_DeniseRev                            *
*                                                       *
* Funktion:     Findet Denise-Revision heraus           *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (18. Oktober 1998, 14:32:24)        *
*                                                       *
do_DeniseRev    moveq   #-1,d0
		move.b  (flags_draco,PC),d1     ; bei DraCo
		bne     .done
	;-- 8362 -------------------------------;
		move    $dff07c,d1              ;LISAID
		and     #$00FF,d1
		move    $dff07c,d2
		and     #$00FF,d2
		cmp     d1,d2                   ;Muß gleich sein!
		bne     .done                   ;  nein -> ganz alte Denise
	;-- 8373 -------------------------------;
		move    $dff07c,d0
		and.l   #$000000F0,d0
		eor     #$00F0,d0
		lsr     #4,d0
.done           rts
*<
*-------------------------------------------------------*
* Name:         do_BoingBag                             *
*                                                       *
* Funktion:     BoingBag ermitteln                      *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (27. Dezember 1999, 10:19:01)       *
*                                                       *
	;-- Strings ----------------------------;
	defhws  bb_workbench,   "workbench.library"

do_BoingBag     moveq   #0,d3                   ;kein BoingBag
	;-- Workbench-Library öffnen -----------;
		lea     (bb_workbench,a4),a1
		moveq   #44,d0                  ;<V44 hat's keinen Sinn
		exec    OpenLibrary
		tst.l   d0
		beq     .found
		move.l  d0,a1
	;-- Version,Revision abfragen ----------;
		move    (LIB_VERSION,a1),d0
		move    (LIB_REVISION,a1),d1
	;-- V44 --------------------------------;
		cmp     #44,d0                  ;Muss exakt V44 sein für diesen Test
		bne     .non_v44
		cmp     #1479,d1                ;V44.1479 = BB1
		blo     .found
		moveq   #1,d3                   ;V44 BoingBag 1
		cmp     #1479,d1                ;V44.1479 = BB1
		beq     .found
		moveq   #2,d3                   ;BoingBag 2
		cmp     #1559,d1                ;V44.1559 = BB2
		bls     .found
		moveq   #3,d3                   ;vielleicht sogar mal BoingBag 3? :)
.non_v44
	;-- evtl. andere Versionen -------------;
		exec.q  CloseLibrary
	;-- Ergebnis liefern -------------------;
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_Emulated                             *
*                                                       *
* Funktion:     Prüft auf emulierten Amiga              *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 9. September 2001, 09:40:43)      *
*                                                       *
do_Emulated     moveq   #1,d0                   ;Ergebnis ist boolean
		lea     (flags_emulated,PC),a0
		tst.b   (a0)
		bne     .done
		moveq   #0,d0
.done           rts
*<
*-------------------------------------------------------*
* Name:         do_XLVersion                            *
*                                                       *
* Funktion:     AmigaXL-Environment: Version            *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 9. September 2001, 09:42:44)      *
*                                                       *
	;-- Strings ----------------------------;
	defhws  xl_native, "native.library"

do_XLVersion    moveq   #0,d3                   ;kein BoingBag
	;-- Native-Library öffnen --------------;
		lea     (xl_native,a4),a1
		moveq   #0,d0                   ;Jede Version tut's
		exec    OpenLibrary
		tst.l   d0
		beq     .found
		move.l  d0,a6
		jsr     (-90,a6)                ; GetXLVersion
		move.l  d0,d3
		move.l  a6,a1
		exec    CloseLibrary
	;-- Ergebnis liefern -------------------;
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_HostOS                               *
*                                                       *
* Funktion:     Emuliert: HostOS ermitteln              *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 9. September 2001, 09:42:44)      *
*                                                       *
do_HostOS       moveq   #0,d3                   ;N/A
	; Momentan nur AmigaXL
	;-- Native-Library öffnen --------------;
		lea     (xl_native,a4),a1
		moveq   #0,d0                   ;Jede Version tut's
		exec    OpenLibrary
		tst.l   d0
		beq     .found
		move.l  d0,a6
		moveq   #NATIVE_HOST_OSNAME,d0
		jsr     (-84,a6)                ; GetHostString
		move.l  d0,d3
		move.l  a6,a1
		exec    CloseLibrary
	;-- Ergebnis liefern -------------------;
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_HostVers                             *
*                                                       *
* Funktion:     Emuliert: Host Version ermitteln        *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 9. September 2001, 09:42:44)      *
*                                                       *
do_HostVers     moveq   #0,d3                   ;N/A
	; Momentan nur AmigaXL
	;-- Native-Library öffnen --------------;
		lea     (xl_native,a4),a1
		moveq   #0,d0                   ;Jede Version tut's
		exec    OpenLibrary
		tst.l   d0
		beq     .found
		move.l  d0,a6
		moveq   #NATIVE_HOST_OSVERS,d0
		jsr     (-84,a6)                ; GetHostString
		move.l  d0,d3
		move.l  a6,a1
		exec    CloseLibrary
	;-- Ergebnis liefern -------------------;
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_HostMachine                          *
*                                                       *
* Funktion:     Emuliert: Host Machine ermitteln        *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 9. September 2001, 09:42:44)      *
*                                                       *
do_HostMachine  moveq   #0,d3                   ;N/A
	; Momentan nur AmigaXL
	;-- Native-Library öffnen --------------;
		lea     (xl_native,a4),a1
		moveq   #0,d0                   ;Jede Version tut's
		exec    OpenLibrary
		tst.l   d0
		beq     .found
		move.l  d0,a6
		moveq   #NATIVE_HOST_MACHINE,d0
		jsr     (-84,a6)                ; GetHostString
		move.l  d0,d3
		move.l  a6,a1
		exec    CloseLibrary
	;-- Ergebnis liefern -------------------;
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_HostCPU                              *
*                                                       *
* Funktion:     Emuliert: Host CPU ermitteln            *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 9. September 2001, 09:42:44)      *
*                                                       *
do_HostCPU      moveq   #0,d3                   ;N/A
	; Momentan nur AmigaXL
	;-- Native-Library öffnen --------------;
		lea     (xl_native,a4),a1
		moveq   #0,d0                   ;Jede Version tut's
		exec    OpenLibrary
		tst.l   d0
		beq     .found
		move.l  d0,a6
		moveq   #NATIVE_HOST_CPUID,d0
		jsr     (-84,a6)                ; GetHostString
		move.l  d0,d3
		move.l  a6,a1
		exec    CloseLibrary
	;-- Ergebnis liefern -------------------;
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<
*-------------------------------------------------------*
* Name:         do_HostSpeed                            *
*                                                       *
* Funktion:     Emuliert: Host CPU speed ermitteln      *
*                                                       *
* Parameter:    -» D0.w AttnFlags                       *
*               -» a4.l ^strbase                        *
*               «- D0.l Numerisches Ergebnis            *
* Register:     Scratch: D0-D3/A0-A6                    *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 9. September 2001, 09:42:44)      *
*                                                       *
do_HostSpeed    moveq   #0,d3                   ;N/A
	; Momentan nur AmigaXL
	;-- Native-Library öffnen --------------;
		lea     (xl_native,a4),a1
		moveq   #0,d0                   ;Jede Version tut's
		exec    OpenLibrary
		tst.l   d0
		beq     .found
		move.l  d0,a6
		moveq   #NATIVE_HOST_CPUSPEED,d0
		jsr     (-84,a6)                ; GetHostString
		move.l  d0,d3
		move.l  a6,a1
		exec    CloseLibrary
	;-- String in Int konvertieren ---------;
.convert        tst.l   d3
		beq     .found
		move.l  d3,d1
		pea     0.w
		move.l  SP,d2
		dos     StrToLong
		move.l  (SP)+,d3
	;-- Ergebnis liefern -------------------;
.found          move.l  d3,d0                   ;Numerisches Ergebnis
		rts
*<


*---------------------------------------------------------------*
*       == HILFSFUNKTIONEN ==                                   *
*                                                               *
*-------------------------------------------------------*
* Name:         BuildRAMtab                             *
*                                                       *
* Funktion:     RAM-Tabelle erzeugen                    *
*                                                       *
* Parameter:                                            *
* Register:     d0/d1/a0/a1                             *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 17:07:37)            *
*                                                       *
BuildRAMtab     lea     (mem_all_plain,PC),a1   ;Liste
		moveq   #0,d0                   ;Kein spezielles RAM
		bsr     GetRAMSize
		move.l  d0,(a1)+
		move.l  d1,(a1)+
		move.l  #MEMF_FAST,d0           ;FAST RAM
		bsr     GetRAMSize
		move.l  d0,(a1)+
		move.l  d1,(a1)+
		move.l  #MEMF_CHIP,d0           ;CHIP RAM
		bsr     GetRAMSize
		move.l  d0,(a1)+
		move.l  d1,(a1)+
		rts
*<
*-------------------------------------------------------*
* Name:         GetRAMSize                              *
*                                                       *
* Funktion:     RAM-Speichergröße besorgen              *
*                                                       *
* Parameter:    -» D0.l TypeOfMem                       *
*               «- D0.l Größe (reines RAM)              *
*               «- D1.l Größe (Virtual RAM)             *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 17:07:37)            *
*                                                       *
GetRAMSize      movem.l d2-d4/a0-a1,-(SP)
		move.l  d0,d4                   ;Speichertyp merken
	;-- VMM-RAM berechnen ------------------;
		moveq   #0,d3                   ;Hier wird VMM-RAM addiert
		move.l  (execbase,PC),a0
		move.l  (MemList,a0),a0         ;^Erste MemHeader-Node
.loop           lea     (.vmmname,PC),a1
		exec    FindName
		beq     .novmm
		move.l  d0,a0
		move    (MH_ATTRIBUTES,a0),d0   ;Attribute testen
		and     d4,d0
		cmp     d4,d0
		bne     .loop
		move.l  (MH_UPPER,a0),d0        ;Speichergröße berechnen
		move.l  (MH_LOWER,a0),d1
		sub.l   #MH_SIZE,d1
		sub.l   d1,d0
		add.l   d0,d3                   ; auf VMM addieren
		bra     .loop
	;-- Größe des totalen RAMs berechnen ---;
.novmm          move.l  d4,d1
		bset    #MEMB_TOTAL,d1          ;gesamten Speicher berechnen lassen
		exec    AvailMem
		move.l  d3,d1
		sub.l   d3,d0
		movem.l (SP)+,d2-d4/a0-a1
		rts
	;-- Strings ----------------------------;
.vmmname        dc.b    "VMM Mem (paged)",0
		even
*<
*-------------------------------------------------------*
* Name:         CalcClock                               *
*                                                       *
* Funktion:     CPU-Takte berechnen                     *
*                                                       *
* Parameter:    keine                                   *
* Register:     a1,d0,d1                                *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 17:07:37)            *
*                                                       *
CalcClock       lea     (flags_gotclock,PC),a1
		tst.b   (a1)
		bne     .done
		bsr     GetClocks
		move.l  d0,cpuclk
		move.l  d1,fpuclk
		st      (a1)
.done           rts
*<


;;                lea     $dff000,a0              ;Custom-Chips
;;                exec    Disable                 ;Leider etwas harter Check
;;                move    $dc0002,d2              ;DMACONR-Spiegel vorher
;;                move    ($002,a0),d0            ;DMACONR
;;                btst    #10,d0                  ;BLTPRI = 0
;;                beq     .a1000_clrbp
;;                move    #$0400,($096,a0)        ;BLTPRI löschen
;;                move    $dc0002,d1              ;DMACONR-Spiegel lesen
;;                move    #$8400,($096,a0)        ;BLTPRI setzen
;;                bra     .a1000_done
;;.a1000_clrbp    move    #$8400,($096,a0)        ;BLTPRI setzen
;;                move    $dc0002,d1              ;DMACONR-Spiegel lesen
;;                move    #$0400,($096,a0)        ;BLTPRI löschen
;;.a1000_done     exec.q  Enable                  ;Das war's schon
;;                cmp     d0,d2                   ;Muß gleich sein!
;;                bne     .amigaocs               ;Nein: kein A1000
;;                eor     #$0400,d1               ;Bit wechseln
;;                cmp     d0,d1                   ;Muß gleich sein!
;;                bne     .amigaocs               ;nein: Amiga OCS


*---------------------------------------------------------------*
*       == VARIABLEN ==                                         *
*                                                               *

db_semaphore    dcb.b   SS_SIZE,0               ;Semaphore für Database

				;* REIHENFOLGE BELASSEN ! *
mem_all_plain   dc.l    0                       ;Alles reine RAM
mem_all_vmm     dc.l    0                       ;Alles VMM RAM
mem_fast_plain  dc.l    0                       ;Alles reine FAST RAM
mem_fast_vmm    dc.l    0                       ;Alles VMM FAST RAM
mem_chip_plain  dc.l    0                       ;Alles reine CHIP RAM
mem_chip_vmm    dc.l    0                       ;Alles VMM CHIP RAM
				;* BIS HIER HIN ! *

cpuclk          dc.l    0                       ;Takt der CPU
fpuclk          dc.l    0                       ;Takt der FPU
flags_draco     dc.b    0                       ;-1 wenn DraCo
flags_gotclock  dc.b    0                       ;-1 wenn Clock bereits ermittelt
flags_emulated  dc.b    0                       ;-1 wenn Rechner emuliert wird
		even

		SAVE
		SECTION blank,BSS
entrynums       ds.l    IDHW_NUMBEROF           ;Numerische Ergebnisse
buildflags      ds.b    IDHW_NUMBEROF           ;Flag: Eintrag erzeugt
		RESTORE

*---------------------------------------------------------------*
*       == ENDE ==                                              *
*                                                               *
		END OF SOURCE
