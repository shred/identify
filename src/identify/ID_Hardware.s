*
* identify.library
*
* Copyright (C) 2021 Richard "Shred" Koerber
*	http://identify.shredzone.org
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published
* by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*

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

		INCLUDE ID_Hardware.i
		INCLUDE ID_Locale.i

		IFD	_MAKE_68020
		  MACHINE 68020
		ENDC

		SECTION strings,DATA
strbase		ds.w	0

		SECTION text,CODE

**
* Initialize the hardware module.
*
		public	InitHardware
InitHardware	movem.l d0-d3/a0-a6,-(sp)
	;-- create semaphore
		lea	(db_semaphore,PC),a0
		exec	InitSemaphore
	;-- check for DraCo
		lea	(.draconame,PC),a1
		exec	OpenResource
		lea	(flags_draco,PC),a0	; set DraCo flag
		tst.l	d0
		sne	(a0)
	;-- build RAM table
		bsr	BuildRAMtab
	;-- check hardware type
		moveq	#IDHW_SYSTEM,d0
		bsr	IdHardwareNum		; set emulation flag
	;-- done
		movem.l (sp)+,d0-d3/a0-a6
		rts

.draconame	dc.b	"draco.resource",0
		even


**
* Exit hardware module.
*
		public	ExitHardware
ExitHardware	movem.l d0-d1/a0-a1,-(SP)
		lea	(db_semaphore,PC),a0
		exec	ObtainSemaphore
		movem.l (SP)+,d0-d1/a0-a1
		rts


**
* Fetch hardare description as number.
*
*	-> D0.l	Description type
*	-> A0.l	^Tags
*	<- D0.l	Value
*
		public	IdHardwareNum
IdHardwareNum	movem.l d1-d3/a0-a6,-(SP)
		lea	strbase,a4
		move.l	a0,a3
		lea	entrynums,a5
		move.l	d0,d3
		cmp.l	#IDHW_NUMBEROF,d3
		bhs	.err_unknown
	;-- obtain cache lock
		lea	(db_semaphore,PC),a0
		exec	ObtainSemaphore
	;-- record already present?
		lea	buildflags,a0
		tst.b	(a0,d3.w)
		bne	.is_built
	;-- create record
		st	(a0,d3.w)		; important: BEFORE jumping into the routine
		lea	(.calltab,PC),a0	; fetch init function ptr
		IFD	_MAKE_68020
		 move.l (a0,d3.w*4),a2
		ELSE
		 move	d3,d0
		 add	d0,d0
		 add	d0,d0
		 move.l (a0,d0.w),a2
		ENDC
		move.l	(execbase,PC),a0
		move	(AttnFlags,a0),d0
		movem.l d3-d7/a5,-(SP)
		jsr	(a2)			; jump into function
		movem.l (SP)+,d3-d7/a5
		IFD	_MAKE_68020
		 move.l d0,(a5,d3.w*4)
		ELSE
		 move	d3,d1
		 add	d1,d1
		 add	d1,d1
		 move.l d0,(a5,d1.w)
		ENDC
		bra	.free
	;-- read cached record
.is_built	IFD	_MAKE_68020
		 move.l (a5,d3.w*4),d0
		ELSE
		 move	d3,d0
		 add	d0,d0
		 add	d0,d0
		 move.l (a5,d0.w),d0
		ENDC
	;-- release cache log
.free		lea	(db_semaphore,PC),a0
		exec	ReleaseSemaphore
	;-- done
.exit		movem.l (SP)+,d1-d3/a0-a6
		rts

	;-- error
.err_unknown	moveq	#0,d0
		bra	.exit

	;-- table of functions
.calltab	dc.l	do_System,	do_CPU,		do_FPU,		do_MMU
		dc.l	do_OsVer,	do_ExecVer,	do_WbVer,	do_RomSize
		dc.l	do_Chipset,	do_GfxSys,	do_ChipRAM,	do_FastRAM
		dc.l	do_RAM,		do_SetPatchVer, do_AudioSys,	do_OsNr
		dc.l	do_VMChipRAM,	do_VMFastRAM,	do_VMRAM,	do_PlainChipRAM
		dc.l	do_PlainFastRAM, do_PlainRAM,	do_VBR,		do_LastAlert
		dc.l	do_VBlankFreq,	do_PowerFreq,	do_EClock,	do_SlowRAM
		dc.l	do_Gary,	do_Ramsey,	do_BattClock,	do_ChunkyPlanar
		dc.l	do_PowerPC,	do_PPCClock,	do_CPURev,	do_CPUClock
		dc.l	do_FPUClock,	do_RAMAccess,	do_RAMWidth,	do_RAMCAS
		dc.l	do_RAMBandwidth, do_TCPIP,	do_PPCOS,	do_Agnus
		dc.l	do_AgnusMode,	do_Denise,	do_DeniseRev,	do_BoingBag
		dc.l	do_Emulated,	do_XLVersion,	do_HostOS,	do_HostVers
		dc.l	do_HostMachine,	do_HostCPU,	do_HostSpeed,	do_LastAlertTask
		dc.l	do_Paula,       do_RomVer,	do_RTC


**
* Fetch hardare description as string.
*
*	-> D0.l	Description type
*	-> A0.l	^Tags
*	<- D0.l	^String or NULL
*
		public	IdHardware
IdHardware	movem.l d1-d3/a0-a3/a6,-(SP)
		link	a4,#idhws_SIZEOF
		move.l	a0,(idhws_Tags,a4)
		move.l	d0,(idhws_Type,a4)
		cmp.l	#IDHW_NUMBEROF,d0
		bhs	.err_unknown
	;-- evaluate tags
		move.l	(idhws_Tags,a4),a0	; translation requested?
		move.l	#IDTAG_Localize,d0
		moveq	#-1,d1
		utils	GetTagData
		tst.l	d0
		sne	(idhws_Localize,a4)
		move.l	(idhws_Tags,a4),a0	; NULL for N/A
		move.l	#IDTAG_NULL4NA,d0
		moveq	#0,d1
		utils	GetTagData
		tst.l	d0
		sne	(idhws_NullNA,a4)
	;-- fetch numerical result
		move.l	(idhws_Type,a4),d0
		move.l	(idhws_Tags,a4),a0
		bsr	IdHardwareNum
	;-- convert to string
		move.l	(idhws_Type,a4),d1
		lea	(.calltab,PC),a0
		IFD	_MAKE_68020
		 move.l (a0,d1.w*4),a0
		ELSE
		 add	d1,d1
		 add	d1,d1
		 move.l (a0,d1.w),a0
		ENDC
		jsr	(a0)			; invoke formatter
		move.l	a0,d0
	;-- done
.exit		unlk	a4
		movem.l (sp)+,d1-d3/a0-a3/a6
		rts

	;-- error
.err_unknown	moveq	#0,d0
		bra	.exit

	;-- table of formatters
.calltab	dc.l	cv_System,	cv_CPU,		cv_FPU,		cv_MMU
		dc.l	cv_OsVer,	cv_ExecVer,	cv_WbVer,	cv_RomSize
		dc.l	cv_Chipset,	cv_GfxSys,	cv_ChipRAM,	cv_FastRAM
		dc.l	cv_RAM,		cv_SetPatchVer, cv_AudioSys,	cv_OsNr
		dc.l	cv_VMChipRAM,	cv_VMFastRAM,	cv_VMRAM,	cv_PlainChipRAM
		dc.l	cv_PlainFastRAM, cv_PlainRAM,	cv_VBR,		cv_LastAlert
		dc.l	cv_VBlankFreq,	cv_PowerFreq,	cv_EClock,	cv_SlowRAM
		dc.l	cv_Gary,	cv_Ramsey,	cv_BattClock, 	cv_ChunkyPlanar
		dc.l	cv_PowerPC,	cv_PPCClock,	cv_CPURev,	cv_CPUClock
		dc.l	cv_FPUClock,	cv_RAMAccess,	cv_RAMWidth,	cv_RAMCAS
		dc.l	cv_RAMBandwidth, cv_TCPIP,	cv_PPCOS,	cv_Agnus
		dc.l	cv_AgnusMode,	cv_Denise,	cv_DeniseRev,	cv_BoingBag
		dc.l	cv_Emulated,	cv_XLVersion,	cv_HostOS,	cv_HostVers
		dc.l	cv_HostMachine,	cv_HostCPU,	cv_HostSpeed,	cv_LastAlertTask
		dc.l	cv_Paula,       cv_RomVer,	cv_RTC


*
* ======== Formatter Functions ========
*
* These functions take care for properly formatting a requested hardware detail.
*
*	-> D0.l	Numerical result of the hardware detail
*	-> A4.l	^Stack frame
*	<- A0.l	^String
*

cv_System	add.l	#MSG_HW_AMIGA1000,d0
		bra	quick_loc

cv_CPU		lea	(.systab,PC),a0
		move.b	(a0,d0.l),d0
		add.l	#MSG_HW_68000,d0
		bra	quick_loc
.systab		dc.b	MSG_HW_68000-MSG_HW_68000
		dc.b	MSG_HW_68010-MSG_HW_68000
		dc.b	MSG_HW_68020-MSG_HW_68000
		dc.b	MSG_HW_68030-MSG_HW_68000
		dc.b	MSG_HW_68EC030-MSG_HW_68000
		dc.b	MSG_HW_68040-MSG_HW_68000
		dc.b	MSG_HW_68LC040-MSG_HW_68000
		dc.b	MSG_HW_68060-MSG_HW_68000
		dc.b	MSG_HW_68LC060-MSG_HW_68000
		dc.b	MSG_HW_FPGA-MSG_HW_68000
		even

cv_FPU		subq.l	#1,d0
		bcs	quick_none
		lea	(.systab,PC),a0
		move.b	(a0,d0.l),d0
		add.l	#MSG_HW_68000,d0
		bra	quick_loc
.systab		dc.b	MSG_HW_68881-MSG_HW_68000
		dc.b	MSG_HW_68882-MSG_HW_68000
		dc.b	MSG_HW_68040-MSG_HW_68000
		dc.b	MSG_HW_68060-MSG_HW_68000
		dc.b	MSG_HW_FPGA-MSG_HW_68000
		even

cv_MMU		subq.l	#1,d0
		bcs	quick_none
		lea	(.systab,PC),a0
		move.b	(a0,d0.l),d0
		add.l	#MSG_HW_68000,d0
		bra	quick_loc
.systab		dc.b	MSG_HW_68851-MSG_HW_68000
		dc.b	MSG_HW_68030-MSG_HW_68000
		dc.b	MSG_HW_68040-MSG_HW_68000
		dc.b	MSG_HW_68060-MSG_HW_68000
		dc.b	MSG_HW_FPGA-MSG_HW_68000
		even

cv_OsVer	lea	buf_OsVer,a0
		lea	buf_OsVerLoc,a1
		bra	quick_ver

cv_ExecVer	lea	buf_ExecVer,a0
		lea	buf_ExecVerLoc,a1
		bra	quick_ver

cv_WbVer	tst.l	d0
		beq	quick_na
		lea	buf_WbVer,a0
		lea	buf_WbVerLoc,a1
		bra	quick_ver

cv_RomSize	lea	buf_RomSize,a0
		lea	buf_RomSizeLoc,a1
		bra	quick_size

cv_Chipset	add.l	#MSG_HW_OCS,d0
		bra	quick_loc

cv_GfxSys	add.l	#MSG_HW_AMIGAOS,d0
		bra	quick_loc

cv_ChipRAM	lea	buf_ChipRAM,a0
		lea	buf_ChipRAMLoc,a1
		bra	quick_size

cv_FastRAM	lea	buf_FastRAM,a0
		lea	buf_FastRAMLoc,a1
		bra	quick_size

cv_RAM		lea	buf_RAM,a0
		lea	buf_RAMLoc,a1
		bra	quick_size

cv_SetPatchVer	tst.l	d0
		beq	quick_na
		lea	buf_SetPatchVer,a0
		lea	buf_SetPatchVerLoc,a1
		bra	quick_ver

cv_AudioSys	add.l	#MSG_HW_AUDAMIGAOS,d0
		bra	quick_loc

cv_OsNr		subq.l	#1,d0
		bcc	.os_ok
		tst.b	(idhws_NullNA,a4)
		beq	.strna
		sub.l	a0,a0
		rts
.strna		move.l	#MSG_HW_OS_UNKNOWN,d0
		bra	quick_loc
.os_ok		add.l	#MSG_HW_OS_36,d0
		bra	quick_loc

cv_VMChipRAM	lea	buf_VMChipRAM,a0
		lea	buf_VMChipRAMLoc,a1
		bra	quick_size

cv_VMFastRAM	lea	buf_VMFastRAM,a0
		lea	buf_VMFastRAMLoc,a1
		bra	quick_size

cv_VMRAM	lea	buf_VMRAM,a0
		lea	buf_VMRAMLoc,a1
		bra	quick_size

cv_PlainChipRAM lea	buf_PlainChipRAM,a0
		lea	buf_PlainChipRAMLoc,a1
		bra	quick_size

cv_PlainFastRAM lea	buf_PlainFastRAM,a0
		lea	buf_PlainFastRAMLoc,a1
		bra	quick_size

cv_PlainRAM	lea	buf_PlainRAM,a0
		lea	buf_PlainRAMLoc,a1
		bra	quick_size

cv_VBR		lea	buf_VBR,a0
		sf	(a0)			; no caching!
		bra	quick_addr

cv_LastAlert	lea	buf_LastAlert,a0
		sf	(a0)			; no caching!
		bra	quick_hex

cv_VBlankFreq	lea	buf_VBlankFreq,a0
		bra	quick_freq

cv_PowerFreq	lea	buf_PowerFreq,a0
		bra	quick_freq

cv_EClock	lea	buf_EClock,a0
		bra	quick_freq

cv_SlowRAM	lea	buf_SlowRAM,a0
		lea	buf_SlowRAMLoc,a1
		bra	quick_size

cv_Gary		subq.l	#1,d0
		bcs	quick_none
		add.l	#MSG_HW_NORMAL,d0
		bra	quick_loc

cv_Ramsey	subq.l	#1,d0
		bcs	quick_none
		add.l	#MSG_HW_REVD,d0
		bra	quick_loc

cv_BattClock	bra	quick_found

cv_ChunkyPlanar bra	quick_found

cv_PowerPC	subq.l	#1,d0
		bcs	quick_none
		add.l	#MSG_HW_PPCFOUND,d0
		bra	quick_loc

cv_PPCClock	lea	buf_PPCClock,a0
		bra	quick_mhz

cv_CPURev	tst.l	d0
		bmi	quick_na
		lea	buf_CPURev,a0
		bra	quick_num

cv_CPUClock	lea	buf_CPUClock,a0
		bra	quick_mhz

cv_FPUClock	lea	buf_FPUClock,a0
		bra	quick_mhz

cv_RAMAccess	tst.l	d0
		beq	quick_na
		lea	buf_RAMAccess,a0
		bra	quick_ns

cv_RAMWidth	tst.l	d0
		beq	quick_na
		lea	buf_RAMWidth,a0
		bra	quick_num

cv_RAMCAS	subq.l	#1,d0
		bcs	quick_none
		add.l	#MSG_HW_RAMCAS_NORMAL,d0
		bra	quick_loc

cv_RAMBandwidth tst.l	d0
		beq	quick_na
		lea	buf_RAMBandwidth,a0
		bra	quick_num

cv_TCPIP	add.l	#MSG_HW_TCPIP_NONE,d0
		bra	quick_loc

cv_PPCOS	add.l	#MSG_HW_PPCOS_NONE,d0
		bra	quick_loc

cv_Agnus	add.l	#MSG_HW_AGNUS_NONE,d0
		bra	quick_loc

cv_AgnusMode	add.l	#MSG_HW_AMODE_NONE,d0
		bra	quick_loc

cv_Denise	add.l	#MSG_HW_DENISE_NONE,d0
		bra	quick_loc

cv_DeniseRev	tst.l	d0
		bmi	quick_na
		lea	buf_DeniseRev,a0
		bra	quick_num

cv_BoingBag	tst.l	d0
		beq	quick_na
		lea	buf_BoingBag,a0
		bra	quick_num

cv_Emulated	bra	quick_found

cv_XLVersion	lea	buf_XLVersion,a0
		bra	quick_num

cv_HostOS	lea	buf_HostOS,a0
		bra	quick_strptr

cv_HostVers	lea	buf_HostVers,a0
		bra	quick_strptr

cv_HostMachine	lea	buf_HostMachine,a0
		bra	quick_strptr

cv_HostCPU	lea	buf_HostCPU,a0
		bra	quick_strptr

cv_HostSpeed	lea	buf_HostSpeed,a0
		bra	quick_mhz

cv_LastAlertTask lea	buf_LastAlertTask,a0
		sf	(a0)			; no caching!
		bra	quick_addr

cv_Paula	add.l	#MSG_HW_PAULA_NONE,d0
		bra	quick_loc

cv_RomVer	lea	buf_RomVer,a0
		lea	buf_RomVerLoc,a1
		bra	quick_ver

cv_RTC		add.l	#MSG_HW_RTC_NONE,d0
		bra	quick_loc


*
* ======== Quick Formatter Functions ========
*

**
* Output "Found"
*
quick_found	tst.l	d0			 ;OK?
		beq	quick_none
		move.l	#MSG_HW_FOUND,d0
		bra	quick_loc

**
* Output "Not Available" or NULL
*
quick_na	tst.b	(idhws_NullNA,a4)
		beq	.strna
		sub.l	a0,a0
		rts
.strna		move.l	#MSG_HW_NOVERSION,d0
		bra	quick_loc

**
* Output "Not Found"
*
quick_none	tst.b	(idhws_NullNA,a4)
		beq	.strna
		sub.l	a0,a0
		rts
.strna		move.l	#MSG_HW_NONE,d0

**
* Just localize a string.
*
quick_loc	move.b	(idhws_Localize,a4),d1
		bra	GetNewLocString

**
* Format a version number.
*
quick_ver	move.b	(idhws_Localize,a4),d1
		beq	.noloc
		move.l	a1,a0
.noloc		tst.b	(a0)
		bne	.exit
		move.l	a0,a1
		moveq	#0,d2
		swap	d0
		move	d0,d2
		move.l	d2,-(sp)
		swap	d0
		move	d0,d2
		move.l	d2,-(sp)
		move.l	#MSG_HW_VERSION,d0
		bsr	GetNewLocString
		exg	a0,a1
		move.l	sp,a2
		bsr	SPrintF
		add.l	#2*4,sp
.exit		rts

**
* Format a size.
*
quick_size	move.b	(idhws_Localize,a4),d1
		beq	.noloc
		move.l	a1,a0
.noloc		tst.b	(a0)
		bne	.exit
		bra	SPrintSize
.exit		rts

**
* Format a hex value.
*
quick_hex	tst.b	(a0)
		bne	.exit
		lea	(.hex,PC),a1
		bra	quick_sconv
.exit		rts
.hex		dc.b	"%08lx",0
		even

**
* Format an address.
*
quick_addr	tst.b	(a0)
		bne	.exit
		lea	(.addr,PC),a1
		bra	quick_sconv
.exit		rts
.addr		dc.b	"0x%08lx",0
		even

**
* Format a frequency in Hz.
*
quick_freq	tst.b	(a0)
		bne	.exit
		lea	(.freq,PC),a1
		bra	quick_sconv
.exit		rts
.freq		dc.b	"%ld Hz",0
		even

**
* Format a frequency in MHz.
*
quick_mhz	tst.b	(a0)
		bne	.exit
		tst.l	d0
		beq	.notavailable
		lea	(.mhz,PC),a1
		bra	quick_sconv
.exit		rts
.notavailable	move.l	#MSG_HW_NOVERSION,d0
		bra	quick_loc
.mhz		dc.b	"%ld MHz",0
		even

**
* Format a duration in ns.
*
quick_ns	tst.b	(a0)
		bne	.exit
		lea	(.ns,PC),a1
		bra	quick_sconv
.exit		rts
.ns		dc.b	"%ld ns",0
		even

**
* Format an integer.
*
quick_num	tst.b	(a0)
		bne	.exit
		lea	(.num,PC),a1
		bra	quick_sconv
.exit		rts
.num		dc.b	"%ld",0
		even

**
* Format a string.
*
quick_strptr	tst.b	(a0)
		bne	.exit
		tst.l	d0
		beq	quick_none
		lea	(.strptr,PC),a1
		bra	quick_sconv
.exit		rts
.strptr		dc.b	"%.29ls",0
		even

**
* Format as SPrintF.
*
quick_sconv	move.l	d0,-(sp)
		move.l	sp,a2
		bsr	SPrintF
		add.l	#1*4,sp
		rts


*
* ======== String Caches ========
*
		SECTION blank,BSS
STRSIZE		EQU	30

buf_STARTOFBUF		ds.b	0
buf_OsVer		ds.b	STRSIZE
buf_OsVerLoc		ds.b	STRSIZE
buf_ExecVer		ds.b	STRSIZE
buf_ExecVerLoc		ds.b	STRSIZE
buf_WbVer		ds.b	STRSIZE
buf_WbVerLoc		ds.b	STRSIZE
buf_RomSize		ds.b	STRSIZE
buf_RomSizeLoc		ds.b	STRSIZE
buf_ChipRAM		ds.b	STRSIZE
buf_ChipRAMLoc		ds.b	STRSIZE
buf_FastRAM		ds.b	STRSIZE
buf_FastRAMLoc		ds.b	STRSIZE
buf_RAM			ds.b	STRSIZE
buf_RAMLoc		ds.b	STRSIZE
buf_SetPatchVer		ds.b	STRSIZE
buf_SetPatchVerLoc	ds.b	STRSIZE
buf_VMChipRAM		ds.b	STRSIZE
buf_VMChipRAMLoc	ds.b	STRSIZE
buf_VMFastRAM		ds.b	STRSIZE
buf_VMFastRAMLoc	ds.b	STRSIZE
buf_VMRAM		ds.b	STRSIZE
buf_VMRAMLoc		ds.b	STRSIZE
buf_PlainChipRAM	ds.b	STRSIZE
buf_PlainChipRAMLoc	ds.b	STRSIZE
buf_PlainFastRAM	ds.b	STRSIZE
buf_PlainFastRAMLoc	ds.b	STRSIZE
buf_PlainRAM		ds.b	STRSIZE
buf_PlainRAMLoc		ds.b	STRSIZE
buf_VBR			ds.b	STRSIZE
buf_LastAlert		ds.b	STRSIZE
buf_VBlankFreq		ds.b	STRSIZE
buf_PowerFreq		ds.b	STRSIZE
buf_EClock		ds.b	STRSIZE
buf_SlowRAM		ds.b	STRSIZE
buf_SlowRAMLoc		ds.b	STRSIZE
buf_PPCClock		ds.b	STRSIZE
buf_CPURev		ds.b	STRSIZE
buf_CPUClock		ds.b	STRSIZE
buf_FPUClock		ds.b	STRSIZE
buf_RAMAccess		ds.b	STRSIZE
buf_RAMWidth		ds.b	STRSIZE
buf_RAMBandwidth	ds.b	STRSIZE
buf_DeniseRev		ds.b	STRSIZE
buf_BoingBag		ds.b	STRSIZE
buf_XLVersion		ds.b	STRSIZE
buf_HostOS		ds.b	STRSIZE
buf_HostVers		ds.b	STRSIZE
buf_HostMachine		ds.b	STRSIZE
buf_HostCPU		ds.b	STRSIZE
buf_HostSpeed		ds.b	STRSIZE
buf_LastAlertTask	ds.b	STRSIZE
buf_Paula		ds.b	STRSIZE
buf_RomVer		ds.b	STRSIZE
buf_RomVerLoc		ds.b	STRSIZE
buf_RTC			ds.b	STRSIZE
buf_ENDOFBUF		ds.b	0

		SECTION text,CODE

*
* ======== Database Functions ========
*

**
* Update the hardware database.
*
* This function flushes all hardware value caches.
*
		public	IdHardwareUpdate
IdHardwareUpdate
		movem.l d0-d3/a0-a6,-(SP)
	;-- lock cache
		lea	(db_semaphore,PC),a0
		exec	ObtainSemaphore
	;-- delete creation flags
		moveq	#IDHW_NUMBEROF-1,d0
		lea	buildflags,a0
.clrloop	sf	(a0,d0.w)
		dbra	d0,.clrloop
	;-- invalidate strings
		lea	buf_STARTOFBUF,a0
		move	#((buf_ENDOFBUF-buf_STARTOFBUF)/STRSIZE)-1,d0
.invloop	sf	(a0)
		add.l	#STRSIZE,a0
		dbra	d0,.invloop
	;-- rebuild RAM tab
		bsr	BuildRAMtab
	;-- unlock cache
		lea	(db_semaphore,PC),a0
		exec	ReleaseSemaphore
	;-- done
.exit		movem.l (SP)+,d0-d3/a0-a6
		rts


**
* Format a string with parameters.
*
*	-> A0.l	^Format string
*	-> A1.l	^Target buffer
*	-> D0.l Buffer size
*	-> A2.l	^Tags or NULL
*	<- D0.l Used buffer length, null terminator included
*
		public	IdFormatString
IdFormatString	movem.l d1-d7/a0-a6,-(SP)
		move.l	a1,d7
		move.l	a1,a4
		lea	(-1,a1,d0.l),a5
		move.l	a0,a3
	;-- copy format string
.copy		cmp.l	a5,a4
		bhs	.terminate
		move.b	(a3)+,d0
		beq	.terminate
		cmp.b	#"$",d0			; Escape character?
		beq	.escape
.insert		move.b	d0,(a4)+
		bra	.copy
	;-- escape character
.escape		move.b	(a3)+,d0
		cmp.b	#"$",d0			; Another escape character?
		beq	.insert			; then just insert it
		lea	fmtcommands,a0		; load command tab
		moveq	#0,d2
.findloop	lea	(-1,a3),a2
.innerfind	move.b	(a2),d0
		beq	.terminate
		cmpm.b	(a0)+,(a2)+
		bne	.nextcmd
		cmp.b	#"$",d0			; terminated?
		bne	.innerfind		; no: continue
	;-- found
		move.l	d2,d0			; get command code
		sub.l	a0,a0
		bsr	IdHardware
		tst.l	d0
		beq	.copy
		move.l	d0,a0
.fcopy		cmp.l	a5,a4
		bhs	.terminate
		move.b	(a0)+,d0
		beq	.copy
		move.b	d0,(a4)+
		move.l	a2,a3
		bra	.fcopy
	;-- find next command
.nextcmd	subq.l	#1,a0
.nextloop	move.b	(a0)+,d0
		beq	.unknown
		cmp.b	#"$",d0
		bne	.nextloop
		tst.b	(a0)
		beq	.unknown
		addq.l	#1,d2
		bra	.findloop
	;-- unknown command
.unknown	move.b	(a3)+,d0
		beq	.terminate
		cmp.b	#"$",d0
		bne	.unknown
		bra	.copy
	;-- terminate buffer
.terminate	move.b	#0,(a4)+
		move.l	a4,d0
		sub.l	d7,d0
.exit		movem.l (SP)+,d1-d7/a0-a6
		rts

*
* ======== Table of Command Names ========
		SECTION strings,DATA

fmtcommands	dc.b	"SYSTEM$CPU$FPU$MMU$"
		dc.b	"OSVER$EXECVER$WBVER$ROMSIZE$"
		dc.b	"CHIPSET$GFXSYS$CHIPRAM$FASTRAM$"
		dc.b	"RAM$SETPATCHVER$AUDIOSYS$OSNR$"
		dc.b	"VMMCHIPRAM$VMMFASTRAM$VMMRAM$PLNCHIPRAM$"
		dc.b	"PLNFASTRAM$PLNRAM$VBR$LASTALERT$"
		dc.b	"VBLANKFREQ$POWERFREQ$ECLOCK$SLOWRAM$"
		dc.b	"GARY$RAMSEY$BATTCLOCK$CHUNKYPLANAR$"
		dc.b	"POWERPC$PPCCLOCK$CPUREV$CPUCLOCK$"
		dc.b	"FPUCLOCK$RAMACCESS$RAMWIDTH$RAMCAS$"
		dc.b	"RAMBANDWIDTH$TCPIP$PPCOS$AGNUS$"
		dc.b	"AGNUSMODE$DENISE$DENISEREV$BOINGBAG$"
		dc.b	"EMULATED$XLVERSION$HOSTOS$HOSTVERS$"
		dc.b	"HOSTMACHINE$HOSTCPU$HOSTSPEED$LASTALERTTASK$"
		dc.b	"PAULA$ROMVER$RTC$"
		dc.b	0
		even

		SECTION text,CODE


**
* Estimate size of required format buffer. It is guaranteed that the formatted string
* will fit into a buffer of the given size. However, the estimation can be considerably
* larger than the actual requirement.
*
*	-> A0.l	^Format string
*	<- D0.l Estimated buffer length, termination included
*
		public	IdEstimateFormatSize
IdEstimateFormatSize
		movem.l d1/a0,-(SP)
		moveq	#1,d0
.loop		addq.l	#1,d0
		move.b	(a0)+,d1
		beq	.done
		cmp.b	#"$",d1			; escape character?
		bne	.loop
		move.b	(a0)+,d1
		beq	.done
		cmp.b	#"$",d1			; another escape character?
		beq	.loop
		add.l	#IDENTIFYBUFLEN,d0	; table of buffer sizes
.seek		move.b	(a0)+,d1
		beq	.done
		cmp.b	#"$",d1
		bne	.seek
		bra	.loop
.done		addq.l	#6,d0			; add some more space
		movem.l (SP)+,d1/a0
		rts




*
* ======== Hardware Detection Functions ========
*
* The following functions are used to detect all kind of hardware stuff. They all have
* the same register allocation:
*
*	-> D0.w	AttnFlags
*	-> A4.l	^String base
*	<- D0.l	Numerical result
*
* All registers can be scratched.
*

**
* What Amiga system are we running on?
*
	defhws	a1000bonus,	"A1000 Bonus"		; A1000 bonus resident
	defhws	a4000bonus,	"A4000 bonus"		; A4000 bonus resident
	defhws	nd2scsiname,	"2nd.scsi.device" 	; A4000T SCSI device
	defhws	cardresource,	"card.resource"		; card resource
	defhws	cduiname,	"cdui.library"		; cdui library
	defhws	dmacsemaphore,	"dmac.semaphore"	; dmac semaphore
	defhws	nativename,	"native.library"	; AmigaXL library
	defhws	a690id,		"A690ID"		; A690ID resident

;; TODO: This checks mostly base on the presence of certain libraries or other
; resources. It may lead to wrong results if such a resource is unexpectedly
; present on the machine. Maybe there is a better way, using hardware properties.

do_System	move	d0,d7
		move.l	(execbase,PC),a6
	;-- DraCo?
		move.b	(flags_draco,PC),d0
		bne	.draco
	;-- AmigaXL emulator?
		lea	(nativename,a4),a1
		moveq	#0,d0
		exec.q	OpenLibrary
		tst.l	d0
		beq	.no_amigaxl
		move.l	d0,a1
		exec.q	CloseLibrary
		bra	.amigaxl
	;-- UAE emulator?
.no_amigaxl	sub.l	a0,a0
		move	#1803,d0		; UAE 1 (1803/??)
		moveq	#-1,d1
		expans	FindConfigDev
		tst.l	d0
		bne	.uae
		sub.l	a0,a0
		move	#2011,d0		; UAE 2 (2011/4)
		moveq	#4,d1
		expans	FindConfigDev
		tst.l	d0
		bne	.uae
	;-- Amiga 4000, OS 3.1
		lea	(a4000bonus,a4),a1
		exec	FindResident
		tst.l	d0
		bne	.amiga4000

	;-- Check for AGA machines in general
		move	$dff07c,d1
		cmp.b	#$f8,d1
		bne	.no_aga
	;---- Amiga 4000 (OS 3.0)
		lea	(a1000bonus,a4),a1	; called "A1000 bonus" under OS3.0
		exec.q	FindResident
		tst.l	d0
		bne	.amiga4000
	;---- CD32
		lea	(cduiname,a4),a1	; cdui.library
		moveq	#0,d0
		exec.q	OpenLibrary
		tst.l	d0
		beq	.no_cd32
		move.l	d0,a1
		exec.q	CloseLibrary
		bra	.cd32
	;---- Must be Amiga 1200 otherwise
	;; TODO: Better: Check for CD32, then check for Amiga 1200 using card.resource,
	;  otherwise Amiga 4000.
.no_cd32	bra	.amiga1200

	;-- Check for ECS machines in general
.no_aga		cmp.b	#$fc,d1
		bne	.no_ecs
	;---- Amiga 500, Viper 520
		sub.l	a0,a0
		move	#2157,d0		; DCE (2157)
		moveq	#0,d1			; Viper 520 CD (0)
		expans	FindConfigDev		; Viper provides a card.resource,
		tst.l	d0			; so check before Amiga 600!
		bne	.amiga500
	;---- Amiga 600
		lea	(cardresource,a4),a1
		exec	OpenResource
		tst.l	d0
		bne	.amiga600
		move.l	(execbase,PC),a0
		lea	(MemList,a0),a0
		lea	(cardresource,a4),a1
		exec.q	FindName
		tst.l	d0
		bne	.amiga600
	;---- CDTV
		exec.q	Forbid
		lea	(dmacsemaphore,a4),a1
		exec.q	FindSemaphore
		exec.q	Permit
		tst.l	d0			; is there a dmac.resource
		beq	.no_cdtv		;  yes: might be a CDTV or A500 with A570
		lea	(a690id,a4),a1		; A570 present?
		exec.q	FindResident
		tst.l	d0
		bne	.amiga500		;  yes: so it's an Amiga 500
		bra	.cdtv			;  no: it's a CDTV
	;---- Amiga 3000
.no_cdtv	movem.l d1-d7/a0-a5,-(SP)
		lea	(.getramsey,PC),a5	; get ramsey revision
		exec.q	Supervisor
		movem.l (SP)+,d1-d7/a0-a5
		cmp.b	#$0d,d0			; Ramsey D or Ramsey F
		beq	.amiga3000		;   yes: Amiga 3000
		cmp.b	#$0f,d0
		beq	.amiga3000
	;---- Amiga 2000/060
		btst	#AFB_68060,d7		; There is no 68060 extension for the
		bne	.amiga2000		; Amiga 500, so must be an Amiga 2000
	;---- Amiga 500/Amiga 2000
	;; TODO: Are there other ways to distinguish an A500 from A2000?
		bra	.amigaecs

	;-- Check for OCS machines in general
.no_ecs ;---- Amiga 1000
		exec	Disable
		move	$dff002,d0		; Custom chip registers are mirrored
		move	$dc0002,d1		; on Amiga 1000
		exec.q	Enable
		cmp	d0,d1
		beq	.amiga1000
	;---- Any other OCS Amiga
	;; TODO: Are there other ways to distinguish an A500 from A2000?
		bra	.amigaocs

.amiga1000	moveq	#IDSYS_AMIGA1000,d0
		rts
.amiga2000	moveq	#IDSYS_AMIGA2000,d0
		rts
.amigaocs	moveq	#IDSYS_AMIGAOCS,d0
		rts
.amigaecs	moveq	#IDSYS_AMIGAECS,d0
		rts
.amiga3000	moveq	#IDSYS_AMIGA3000,d0
		rts
.amiga500	moveq	#IDSYS_AMIGA500,d0
		rts
.cdtv		moveq	#IDSYS_CDTV,d0
		rts
.amiga600	moveq	#IDSYS_AMIGA600,d0
		rts
.amiga1200	moveq	#IDSYS_AMIGA1200,d0
		rts
.amiga4000	lea	(nd2scsiname,a4),a1	; maybe an Amiga 4000T?
		move.l	(execbase,PC),a6
		lea	(DeviceList,a6),a0
		exec	FindName
		tst.l	d0
		bne	.amiga4000t
		moveq	#IDSYS_AMIGA4000,d0
		rts
.amiga4000t	moveq	#IDSYS_AMIGA4000T,d0
		rts
.cd32		moveq	#IDSYS_CD32,d0
		rts
.draco		moveq	#IDSYS_DRACO,d0
		rts
.uae		lea	(flags_emulated,PC),a0
		st	(a0)
		moveq	#IDSYS_UAE,d0
		rts
.amigaxl	lea	(flags_emulated,PC),a0
		st	(a0)
		moveq	#IDSYS_AMIGAXL,d0
		rts

		cnop	0,4
.getramsey	lea	$de0003,a0
		move.b	($40,a0),d0
		nop
		rte

**
* What CPU is used?
*
do_CPU		move	d0,d2
		moveq	#IDCPU_FPGA,d0
		btst	#AFB_FPGA,d2
		bne	.found
		btst	#AFB_68060,d2
		bne	.found060
		btst	#AFB_68040,d2
		bne	.found040
		moveq	#IDCPU_68030,d0
		btst	#AFB_68030,d2
		bne	.found
		moveq	#IDCPU_68020,d0
		btst	#AFB_68020,d2
		bne	.found
		moveq	#IDCPU_68010,d0
		btst	#AFB_68010,d2
		bne	.found
		moveq	#IDCPU_68000,d0
.found		rts

	;; TODO: 68EC030?

	;-- 68060 or 68LC060?
.found060	moveq	#IDCPU_68060,d0
		btst	#AFB_FPU40,d2		; also set if 060 FPU is present
		bne	.found
		moveq	#IDCPU_68LC060,d0
		rts

	;-- 68040 or 68LC040?
.found040	moveq	#IDCPU_68040,d0
		btst	#AFB_FPU40,d2
		bne	.found
		moveq	#IDCPU_68LC040,d0
		rts

**
* What FPU is present?
*
do_FPU		move	d0,d2
		moveq	#IDFPU_FPGA,d0
		btst	#AFB_FPGA,d2
		beq	.nofpga
		btst	#AFB_FPU40,d2
		bne	.found
.nofpga		moveq	#IDFPU_68060,d0
		btst	#AFB_68060,d2
		beq	.no68060
		btst	#AFB_FPU40,d2
		bne	.found
.no68060	moveq	#IDFPU_68040,d0
		btst	#AFB_68040,d2
		beq	.no68040
		btst	#AFB_FPU40,d2
		bne	.found
.no68040	moveq	#IDFPU_68882,d0
		btst	#AFB_68882,d2
		bne	.found
		moveq	#IDFPU_68881,d0
		btst	#AFB_68881,d2
		bne	.found
		moveq	#IDFPU_NONE,d0
.found		rts

**
* Is there a MMU available?
*
do_MMU		move	d0,d2			;; TODO: MMU check for FPGA. 68080 has no MMU yet.
		moveq	#IDMMU_68060,d0
		btst	#AFB_68060,d2
		bne	.found
		moveq	#IDMMU_68040,d0
		btst	#AFB_68040,d2
		bne	.found
		moveq	#IDMMU_68030,d0
		btst	#AFB_68030,d2		;; TODO: What about 68EC030?
		bne	.found
	;; TODO: Are there Amigas with 68851 MMU?
	;	moveq	#IDMMU_68851,d0
	;	btst	#AFB_68020,d2
	;	bne	.found
		moveq	#IDMMU_NONE,d0
.found		rts

**
* Active AmigaOS Version (e.g. 40.68).
*
do_OsVer	move.l	(execbase,PC),a0
		moveq	#0,d0
		move	(SoftVer,a0),d0
		swap	d0
		move	(LIB_VERSION,a0),d0
		rts

**
* Exec Version.
*
do_ExecVer	move.l	(execbase,PC),a0
		moveq	#0,d0
		move	(LIB_REVISION,a0),d0
		swap	d0
		move	(LIB_VERSION,a0),d0
		rts

**
* Workbench Version.
*
	defhws	versionname,"version.library"

do_WbVer	lea	(versionname,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		move.l	d0,a1
		tst.l	d0
		beq	.none
		move	(LIB_REVISION,a1),d2
		swap	d2
		move	(LIB_VERSION,a1),d2
		exec.q	CloseLibrary
		move.l	d2,d0
		rts
.none		moveq	#0,d0
		rts

**
* AmigaOS Version (e.g. OS 3.1).
*
do_OsNr	;-- get version.library version
		moveq	#0,d2
		moveq	#0,d3
		lea	(versionname,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.noversion
		move.l	d0,a1
		move	(LIB_VERSION,a1),d2
		move	(LIB_REVISION,a1),d3
		exec.q	CloseLibrary
.noversion	move.l	(execbase,PC),a0
		move	(SoftVer,a0),d1
		move	(LIB_VERSION,a0),d0
	;-- test AmigaOS versions
	;  D0: Kickstart Version
	;  D1: ROM Revision
	;  D2: Workbench Version
	;  D3: Workbench Revision
		cmp	#47,d0
		bne	.not_47
		moveq	#IDOS_3_2_1,d4		; AmigaOS 3.2.1 (>= 47.102)
		cmp	#102,d1
		bge	.found			;   (3.2.1 ROM was found)
		cmp	#3,d3
		bge	.found			;   (3.2.1 module was found)
		moveq	#IDOS_3_2,d4		; AmigaOS 3.2
		bra	.found

.not_47		moveq	#IDOS_3_1_4,d4		; AmigaOS 3.1.4
		cmp	#46,d0
		beq	.found

		moveq	#IDOS_3_2_PROTO,d4	; AmigaOS 3.2 (Walker prototype)
		cmp	#43,d0
		beq	.found

		cmp	#40,d0			; AmigaOS 3.1, 3.5 or 3.9?
		bne	.not_40

		moveq	#IDOS_3_9_BB2,d4	; AmigaOS 3.9 BB2
		cmp	#45,d2
		bne	.not_wb_45
		cmp	#3,d3			;   (45.3)
		beq	.found
		moveq	#IDOS_3_9_BB1,d4	; AmigaOS 3.9 BB1
		cmp	#2,d3			;   (45.2)
		beq	.found
		moveq	#IDOS_3_9,d4		; AmigaOS 3.9
		bra	.found

.not_wb_45	moveq	#IDOS_3_5_BB2,d4	; AmigaOS 3.5 BB2
		cmp	#44,d2
		bne	.not_wb_44
		cmp	#5,d3			;   (44.5)
		beq	.found
		moveq	#IDOS_3_5_BB1,d4	; AmigaOS 3.5 BB1
		cmp	#4,d3			;   (44.4)
		beq	.found
		moveq	#IDOS_3_5,d4		; AmigaOS 3.5
		bra	.found

.not_wb_44	moveq	#IDOS_3_1,d4		; AmigaOS 3.1
		bra	.found

.not_40		moveq	#IDOS_3_0,d4		; AmigaOS 3.0
		cmp	#39,d0
		beq	.found

		moveq	#IDOS_2_1,d4		; AmigaOS 2.1
		cmp	#38,d0
		beq	.found

		moveq	#IDOS_2_04,d4		; AmigaOS 2.04 (or 2.05)
		cmp	#37,d0
		bne	.not_37
		cmp	#299,d1
		blo	.found
		moveq	#IDOS_2_05,d4		; AmigaOS 2.05
		bra	.found

.not_37		moveq	#IDOS_2_0,d4		; AmigaOS 2.0
		cmp	#36,d0
		beq	.found
	;-- unknown OS
		moveq	#IDOS_UNKNOWN,d4
.found		move.l	d4,d0
		rts

**
* Version of the ROM.
*
do_RomVer	bsr	RomStart
		move	(14,a0),d0		; Revision
		swap	d0
		move	(12,a0),d0		; Version
		rts

**
* Size of the ROM, in KB.
*
do_RomSize	bsr	RomStart
		move	(a0),d0
		cmp	#$1111,d0		; 256K ROM?
		beq	.is256k
		cmp	#$1114,d0		; 512K ROM?
		beq	.is512k
		move.l	$ffffec,d0		; read ROM size directly
.correct	rts
	;-- fixed ROM sizes
.is256k		moveq	#$4,d0			; = $40000 = 256KB
		swap	d0
		bra	.correct
.is512k		moveq	#$8,d0			; = $80000 = 512KB
		swap	d0
		bra	.correct

**
* What chipset is in this Amiga?
*
do_Chipset
	;-- Altais (DraCo)
		moveq	#IDCS_ALTAIS,d0
		move.b	(flags_draco,PC),d1
		bne	.done
	;-- SAGA?
	; see http://www.apollo-core.com/knowledge.php?b=3&note=29581&z=HDbIdQ
		moveq	#IDCS_SAGA,d0
		move	$dff016,d1
		and	#$00FE,d1		; Paula revision (bits 7..1)
		cmp	#$0002,d1		;   0 for classic Amiga, 1 for SAGA
		beq	.done
	;-- read Amiga type bits
		move	$dff07c,d1
		and	#$000F,d1
	;-- AGA?
		moveq	#IDCS_AGA,d0
		cmp	#$0008,d1		; Lisa?
		beq	.done
	;-- ECS?
		cmp	#$000c,d1		; HiRes Denise?
		seq	d2
		move	$dff004,d1		;
		btst	#13,d1			; also HiRes Agnus?
		sne	d3
		move.b	d3,d1
		and.b	d2,d1
		bne	.done_ecs		; HiRes Agnus+Denise = ECS
		or.b	d3,d2
		beq	.done_ocs		; classic Agnus+Denise = OCS
		moveq	#IDCS_NECS,d0		; only HiRes Denise = Nearly ECS
		rts
.done_ecs	moveq	#IDCS_ECS,d0
		rts
.done_ocs	moveq	#IDCS_OCS,d0
.done		rts

**
* Which RTG (Graphic OS) is used?
*
	defhws	gfx_cgx3,	"cgxsystem.library"	; CyberGraphX 3
	defhws	gfx_cybergfx,	"cybergraphics.library"	; CyberGraphX
	defhws	gfx_egs,	"egs.library"		; EGS
	defhws	gfx_tiga,	"gfx.library"		; Tiga
	defhws	gfx_graffiti,	"graffiti.library"	; Graffiti
	defhws	gfx_hrgblitter, "hrgblitter.library"	; ProBench
	defhws	gfx_retina,	"retina.library"	; Retina
	defhws	gfx_picasso,	"vilintuisup.library"	; Picasso
	defhws	gfx_pic96,	"rtg.library"		; Picasso96
	defhws	cyber_name,	"ENVARC:CyberGraphics"	; Drawer for CGX

do_GfxSys	move.l	(execbase,PC),a6
		lea	(LibList,a6),a3
	;-- Picasso96
		move.l	#IDGOS_PICASSO96,d3
		lea	(gfx_pic96,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		bne	.found
	;-- ProBench
		move.l	#IDGOS_PROBENCH,d3
		lea	(gfx_hrgblitter,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		bne	.found
	;-- CyberGraphX
		lea	(gfx_cgx3,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		beq	.nocgx
		move.l	d0,a0
		move.l	#IDGOS_CGX3,d3
		cmp	#42,(LIB_VERSION,a0)
		blt	.found			; CyberGraphX 3
		move.l	#IDGOS_CGX4,d3
		bra	.found			; CyberGraphX 4
	;-- Older CyberGraphX
.nocgx		move.l	#IDGOS_CGX,d3
		lea	(gfx_cybergfx,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		beq	.nocybergfx
		lea	(cyber_name,a4),a0
		move.l	a0,d1
		moveq	#ACCESS_READ,d2
		dos	Lock
		move.l	d0,d1
		beq	.nocybergfx
		dos	UnLock
		bra	.found
	;-- EGS
.nocybergfx	move.l	#IDGOS_EGS,d3
		lea	(gfx_egs,a4),a1
		move.l	a3,a0
		exec	FindName		; do not use exec.q here #LFMF
		tst.l	d0
		bne	.found
	;-- Retina
		move.l	#IDGOS_RETINA,d3
		lea	(gfx_retina,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		bne	.found
	;-- Graffiti
		move.l	#IDGOS_GRAFFITI,d3
		lea	(gfx_graffiti,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		bne	.found
	;-- TIGA
		move.l	#IDGOS_TIGA,d3
		lea	(gfx_tiga,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		bne	.found
	;-- Picasso
		move.l	#IDGOS_PICASSO,d3
		lea	(gfx_picasso,a4),a1
		move.l	a3,a0
		exec.q	FindName
		tst.l	d0
		bne	.found
	;-- none or unknown
		move.l	#IDGOS_AMIGAOS,d3
.found		move.l	d3,d0
		rts

**
* What audio driver/framework is used?
*
	defhws	audio_maestix,	"maestix.library"	; Maestix
	defhws	audio_toccata,	"toccata.library"	; Toccata
	defhws	audio_prelude,	"prelude.library"	; Prelude
	defhws	audio_maudio,	"macroaudio.library"	; MacroAudio
	defhws	ahi_name,	"devs:AHI"		; Drawer for AHI

do_AudioSys
	;-- AHI
		move.l	#IDAOS_AHI,d3
		lea	(ahi_name,a4),a0
		move.l	a0,d1
		moveq	#ACCESS_READ,d2
		dos	Lock
		move.l	d0,d1
		beq	.noahi
		dos	UnLock
		bra	.found
	;-- MacroAudio
.noahi		move.l	#IDAOS_MACROAUDIO,d3
		lea	(audio_maudio,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		bne	.found2
	;-- Maestix
		move.l	#IDAOS_MAESTIX,d3
		lea	(audio_maestix,a4),a1
		moveq	#0,d0
		exec.q	OpenLibrary
		tst.l	d0
		bne	.found2
	;-- Toccata
		move.l	#IDAOS_TOCCATA,d3
		lea	(audio_toccata,a4),a1
		moveq	#0,d0
		exec.q	OpenLibrary
		tst.l	d0
		bne	.found2
	;-- Prelude
		move.l	#IDAOS_PRELUDE,d3
		lea	(audio_prelude,a4),a1
		moveq	#0,d0
		exec.q	OpenLibrary
		tst.l	d0
		bne	.found2
	;-- none or unknown
		move.l	#IDAOS_AMIGAOS,d3
		bra	.found
.found2		move.l	d0,a1
		exec.q	CloseLibrary
.found		move.l	d3,d0
		rts

**
* Return total Chip RAM size (real + virtual).
*
do_ChipRAM	move.l	(mem_chip_plain,PC),d0
		add.l	(mem_chip_vmm,PC),d0
		rts

**
* Return total Fast RAM size (real + virtual).
*
do_FastRAM	move.l	(mem_fast_plain,PC),d0
		add.l	(mem_fast_vmm,PC),d0
		rts

**
* Return total RAM (real + virtual).
*
do_RAM		move.l	(mem_all_plain,PC),d0
		add.l	(mem_all_vmm,PC),d0
		rts

**
* Return virtual Chip RAM.
*
do_VMChipRAM	move.l	(mem_chip_vmm,PC),d0
		rts


**
* Return virtual Fast RAM.
*
do_VMFastRAM	move.l	(mem_fast_vmm,PC),d0
		rts

**
* Return total virtual RAM.
*
do_VMRAM	move.l	(mem_all_vmm,PC),d0
		rts

**
* Return real Chip RAM.
*
do_PlainChipRAM move.l	(mem_chip_plain,PC),d0
		rts

**
* Return real Fast RAM.
*
do_PlainFastRAM move.l	(mem_fast_plain,PC),d0
		rts

**
* Return total real RAM.
*
do_PlainRAM	move.l	(mem_all_plain,PC),d0
		rts

**
* SetPatch version.
*
		rsreset
sps_Sem		rs.b	SS_SIZE
sps_Private	rs.b	MLH_SIZE
sps_Version	rs.w	1
sps_Revision	rs.w	1
sps_SIZEOF	rs.w	0

	defhws	semaphore, "\xAB SetPatch \xBB"

do_SetPatchVer	exec	Forbid
		lea	(semaphore,a4),a1
		exec.q	FindSemaphore
		tst.l	d0
		beq	.na
		move.l	d0,a0
		moveq	#0,d0
		move	(sps_Revision,a0),d0
		swap	d0
		move	(sps_Version,a0),d0
		exec.q	Permit
		bra	.doit
.na		exec.q	Permit
		moveq	#0,d0
.doit		rts

**
* Read VBR.
*
do_VBR		lea	buildflags,a0
		sf	(IDHW_VBR,a0)
		btst	#AFB_68010,d0		; VBR requires 68010+
		beq	.no_vbr
		lea	(.vbr_trap,PC),a5
		exec	Supervisor
		rts
	;-- no VBR
.no_vbr		moveq	#0,d0			; base address always 0
		rts
	;-- read VBR register
		MACHINE 68010
		cnop	0,4
.vbr_trap	movec.l vbr,d0
		nop
		rte
		IFD	_MAKE_68020
		  MACHINE 68020
		ELSE
		  MACHINE 68000
		ENDC

**
* Read last alert code.
*
do_LastAlert	lea	buildflags,a0
		sf	(IDHW_LASTALERT,a0)	; never cache this value
		sf	(IDHW_LASTALERTTASK,a0)	; never cache this value
		move.l	(execbase,PC),a0
		move.l	(LastAlert,a0),d0	; is there an alert in execbase?
		cmp.l	#-1,d0
		bne	.showalert		;  yes: use this one
		bsr	ReadLastAlert		; read from $100/$104
		btst	#31,d0			; must be deadend, otherwise invalid
		bne	.showalert
		moveq	#-1,d0			; there was no alert yet
.showalert	rts

**
* Read last alert task.
*
do_LastAlertTask lea	buildflags,a0
		sf	(IDHW_LASTALERT,a0)	; never cache this value
		sf	(IDHW_LASTALERTTASK,a0)	; never cache this value
		move.l	(execbase,PC),a0
		move.l	(LastAlert,a0),d0	; is there an alert in execbase?
		cmp.l	#-1,d0
		bne	.showexecalert		;  yes: use this one
		bsr	ReadLastAlert		; read from $100/$104
		btst	#31,d0			; alert must be deadend, otherwise invalid
		beq	.noalerttask
		move.l	d1,d0			; read alert task from $104
		rts
.showexecalert	move.l	(LastAlert+4,a0),d0	; Last Alert Task
		rts
.noalerttask	moveq	#0,d0			; No last alert yet
		rts

**
* Get VBlank frequency.
*
do_VBlankFreq	move.l	(execbase,PC),a0
		moveq	#0,d0
		move.b	(VBlankFrequency,a0),d0
		rts

**
* Get power frequency.
*
do_PowerFreq	move.l	(execbase,PC),a0
		moveq	#0,d0
		move.b	(PowerSupplyFrequency,a0),d0
		rts

**
* Get e-clock frequency.
*
do_EClock	move.l	(execbase,PC),a0
		move.l	(ex_EClockFrequency,a0),d0
		rts

**
* Get size of "Slow RAM".
*
do_SlowRAM	moveq	#0,d0
		move.l	(execbase,PC),a0
		move.l	(MemList,a0),a0
	;-- iterate through memory list
.getramloop	tst.l	(a0)			; reached the end?
		beq	.getramdone
	;-- correct RAM address
		move.l	(MH_LOWER,a0),d1	; Slow RAM starts at $C00000
		and.l	#$FFFFF000,d1
		cmp.l	#$00C00000,d1
		bne	.getramnext
	;-- evaluate RAM block size
		move.l	(MH_UPPER,a0),d0
		sub.l	#MH_SIZE,d1
		sub.l	d1,d0
		bra	.getramdone
	;-- next node
.getramnext	move.l	(a0),a0
		bra	.getramloop
	;-- done
.getramdone	rts

**
* What Gary chip is present?
*
do_Gary		move.b	(flags_draco,PC),d1	; DraCo has no Gary at all
		bne	.none
	;-- read Gary version
		lea	(.garytest,PC),a5
		exec	Supervisor
		tst.b	d0			; Normal Gary
		beq	.normal
		cmp.b	#$90,d0			; Enhanced Gary
		beq	.enhanced
.none		moveq	#IDGRY_NONE,d0
		rts
.normal		moveq	#IDGRY_NORMAL,d0
		rts
.enhanced	moveq	#IDGRY_ENHANCED,d0
		rts

		cnop	0,4
.garytest	lea	$de1002,a0
		moveq	#0,d0			; access register $00
		moveq	#7,d1
		move.b	d0,(a0)
.garyloop	move.b	(a0),d2			; read via shift register
		lsl.b	#1,d2
		roxl.b	#1,d0
		dbra	d1,.garyloop
		nop
		rte

**
* What Ramsey chip is present?
*
do_Ramsey	move.b	(flags_draco,PC),d1	; DraCo has no Ramsey at all
		bne	.none
	;-- read Ramsey version
		lea	(.ramseytest,PC),a5
		exec	Supervisor
		cmp.b	#$0d,d0			; Revision D
		beq	.rev_d
		cmp.b	#$0f,d0			; Revision F
		beq	.rev_f
.none		moveq	#IDRSY_NONE,d0
		rts
.rev_d		moveq	#IDRSY_REVD,d0
		rts
.rev_f		moveq	#IDRSY_REVF,d0
		rts

		cnop	0,4
.ramseytest	move.b	$de0043,d0
		nop
		rte

**
* Is there a battery backed-up clock?
*
	defhws	battclockname,	"battclock.resource"	;Resource

do_BattClock	lea	(battclockname,a4),a1
		exec	OpenResource
		tst.l	d0			; no resource -> no RTC
		beq	.noclock
		move.l	d0,a6
		jsr	(-12,a6)		; ReadBattClock()
		tst.l	d0			; error -> no RTC
		beq	.noclock
	;-- RTC present
		moveq	#1,d0
		rts
	;-- no RTC present
.noclock	moveq	#0,d0
		rts

**
* Is there a Chunky to Planar hardware present?
*
	defhws	sgfxname,"graphics.library"

do_ChunkyPlanar lea	(sgfxname,a4),a1
		moveq	#40,d0			; requires OS3.1+
		exec	OpenLibrary
		tst.l	d0
		beq	.nohw
		move.l	d0,a1
		move.l	(gb_ChunkyToPlanarPtr,a1),d3 ; remember pointer to hardware
		exec.q	CloseLibrary
		tst.l	d3
		beq	.nohw
	;-- C2P hardware present
		moveq	#1,d0
		rts
	;-- no C2P hardware present
.nohw		moveq	#0,d0
		rts

**
* What PowerPC is present?
*
	defhws	warpname,"powerpc.library"
	defhws	ppcname, "ppc.library"

do_PowerPC	move.l	4.w,a6
		lea	(LibList,a6),a0
		lea	(ppcname,a4),a1
		exec.q	FindName
		tst.l	d0
		bne	.nowarp			; ppc.library present
	;-- WarpOS
		lea	(warpname,a4),a1
		moveq	#7,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.nowarp
		move.l	d0,a6
		jsr	(-42,a6)		; GetCPU()
		move.l	d0,d2
		move.l	a6,a1
		exec	CloseLibrary
		lea	(.warptype,PC),a0
		lea	(.warpbit,PC),a1
		moveq	#0,d0
.warploop	move.b	(a0)+,d0
		move.b	(a1)+,d1
		bmi	.other
		btst	d1,d2
		beq	.warploop
		rts

	;-- PowerUP ----------------------------;
.nowarp		lea	(ppcname,a4),a1
		moveq	#40,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.noppc
		move.l	d0,a6
		lea	(.ppctags,PC),a0
		jsr	(-138,a6)
		move.l	d0,d2
		move.l	a6,a1
		exec	CloseLibrary
		subq.l	#3,d2
		bcs	.other
		moveq	#6,d0
		cmp.l	d0,d2
		bgt	.other
		move.l	d2,d0
		lea	(.ppctype,PC),a0
		move.b	(a0,d0.w),d0
		rts

	;-- PPC present, but unknown
.other		moveq	#IDPPC_OTHER,d0
		rts
	;-- no PPC available
.noppc		moveq	#IDPPC_NONE,d0
		rts

		cnop	0,4
.ppctags	dc.l	$8001F001,0,TAG_DONE
.ppctype	dc.b	IDPPC_603,IDPPC_604,IDPPC_602,IDPPC_603E,IDPPC_603P,IDPPC_OTHER,IDPPC_604E
.warpbit	dc.b	20,16,12,8,4,-1
.warptype	dc.b	IDPPC_620,IDPPC_604E,IDPPC_604,IDPPC_603E,IDPPC_603
		even

**
* Read PowerPC clock.
*
do_PPCClock	move.l	4.w,a6
		lea	(LibList,a6),a0
		lea	(warpname,a4),a1
		exec.q	FindName
		tst.l	d0
		bne	.noppc
	;-- read clock frequency
		lea	(ppcname,a4),a1
		moveq	#40,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.noppc
		move.l	d0,a6
		lea	(.ppctags,PC),a0
		jsr	(-138,a6)
		move.l	d0,d2
		move.l	a6,a1
		exec	CloseLibrary
		move.l	d2,d0
		rts
	;-- read via WarpUP
.noppc		movem.l d4-d7,-(SP)
		jsr	_PPC_CPU_Clock
		movem.l (SP)+,d4-d7
		tst.l	d0			; nada?
		beq	.nowarp
		IFD	_MAKE_68020
		 divu.l #1000000,d0
		ELSE
		 move.l #1000000,d1		; This is just stupid. Who would have a
		 utils	UDivMod32		; PowerPC and an 68000 as companion CPU?
		ENDC
.nowarp		rts

		cnop	0,4
.ppctags	dc.l	$8001F003,0,TAG_DONE

**
* What CPU revision is used?
*
do_CPURev	btst	#AFB_68060,d0
		bne	.found060
		moveq	#-1,d0			; only provided by 68060
		rts
.found060	lea	(.getcpurev,PC),a5
		exec	Supervisor
		lsr	#8,d0
		and.l	#$FF,d0
		rts

		MACHINE 68060
		cnop	0,4
.getcpurev	movec.l pcr,d0
		nop
		rte
		IFD	_MAKE_68020
		  MACHINE 68020
		ELSE
		  MACHINE 68000
		ENDC

**
* Find the CPU clock.
*
do_CPUClock	bsr	CalcClock
		move.l	(cpuclk,PC),d0
		rts

**
* Find the FPU clock.
*
do_FPUClock	bsr	CalcClock
		move.l	(fpuclk,PC),d0
		rts

**
* Get the RAM access time, in ns.
*
do_RAMAccess	moveq	#80,d0			; default is 80ns
		move.b	(flags_draco,PC),d1	; DraCo?
		bne	.done			;   only has 80ns
		lea	(.getramsey,PC),a5	; try to read from Ramsey
		exec	Supervisor
.done		rts

		cnop	0,4
.getramsey	lea	$de0003,a0		; ptr to Ramsey
		cmp.b	#$0f,$40(a0)		; must be Ramsey F
		bne	.ramseydone		; other rev or no Ramsey
		btst	#4,(a0)			; 60ns mode activated?
		beq	.ramseydone
		moveq	#60,d0			; yes -> 60ns access time
.ramseydone	nop
		rte

**
* RAM bus width.
*
do_RAMWidth	moveq	#16,d0			; default 16 bit
		move.l	(gfxbase,PC),a0
		btst	#0,(gb_MemType,a0)
		beq	.done
		moveq	#32,d0			; this system has 32 bit
.done		rts

**
* RAM CAS mode.
*
do_RAMCAS	moveq	#IDCAS_NORMAL,d0	; default: normal CAS
		move.l	(gfxbase,PC),a0
		btst	#1,(gb_MemType,a0)
		beq	.done
		moveq	#IDCAS_DOUBLE,d0	; here: double CAS
.done		rts

**
* RAM bandwidth.
*
do_RAMBandwidth moveq	#1,d0			; default: 1x
		move.l	(gfxbase,PC),a0
		move.b	(gb_MemType,a0),d1
		and.b	#%11,d1
		beq	.done
		moveq	#4,d0			; 4x
		cmp.b	#%11,d1
		beq	.done
		moveq	#2,d0			; 2x
.done		rts

**
* What TCP/IP stack is present?
*
	defhws	tcp_miami,	"miami.library"		; Miami
	defhws	tcp_termite,	"tsocket.library"	; Termite
	defhws	tcp_genesis,	"genesis.library"	; Genesis
	defhws	tcp_amitcp,	"bsdsocket.library"	; AmiTCP
	defhws	tcp_miamidx,	"MiamiDx"		; Miami Deluxe
	defhws	tcp_roadshow,	"C:RoadshowControl"	; Roadshow

do_TCPIP	lea	buildflags,a0
		sf	(IDHW_TCPIP,a0)		; do not cache result
	;-- Miami
		move.l	#IDTCP_MIAMI,d3
		lea	(tcp_miami,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.no_miami
		move.l	d0,a1
		exec.q	CloseLibrary
	;-- MiamiDX
		lea	(tcp_miamidx,a4),a1
		exec.q	Forbid
		exec.q	FindTask
		exec.q	Permit
		tst.l	d0
		beq	.found
		move.l	#IDTCP_MIAMIDX,d3
		bra	.found
	;-- Genesis
.no_miami	move.l	#IDTCP_GENESIS,d3
		lea	(tcp_genesis,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		bne	.found2
	;-- Termite
		move.l	#IDTCP_TERMITE,d3
		lea	(tcp_termite,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		bne	.found2
	;-- AmiTCP
		move.l	#IDTCP_AMITCP,d3
		lea	(tcp_amitcp,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		bne	.roadshow
	;-- none or unknown
		move.l	#IDTCP_NONE,d3
		bra	.found
.found2		move.l	d0,a1
		exec.q	CloseLibrary
.found		move.l	d3,d0
		rts

	;-- maybe roadshow?
.roadshow	move.l	d0,a1			; first close the bsdsocket.library
		exec.q	CloseLibrary
		lea	(tcp_roadshow,a4),a0	; check for RoadshowControl
		move.l	a0,d1
		moveq	#ACCESS_READ,d2
		dos	Lock
		move.l	d0,d1
		beq	.found			;  file not found -> AmiTCP
		dos	UnLock
		moveq	#IDTCP_ROADSHOW,d3	;  file found -> Roadshow
		bra	.found

**
* What PowerPC operating system is used?
*
do_PPCOS	move.l	4.w,a6
		lea	(LibList,a6),a3
	;-- WarpOS
		moveq	#IDPOS_WARPOS,d2
		lea	(warpname,a4),a1
		move.l	a3,a0
		exec	FindName
		tst.l	d0
		bne	.found
	;-- PowerUP
		moveq	#IDPOS_POWERUP,d2
		lea	(ppcname,a4),a1
		move.l	a3,a0
		exec	FindName
		tst.l	d0
		bne	.found
	;-- none or unknown
		moveq	#IDPOS_NONE,d0
		rts
.found		move.l	d2,d0
		rts

**
* What Agnus/Alice/Anni version is present?
*
do_Agnus	moveq	#IDAG_NONE,d0
		move.b	(flags_draco,PC),d1	; DraCo has no Agnus at all
		bne	.done
	;-- Anni (SAGA)
		moveq	#IDAG_ANNI,d0
		move	$dff016,d1
		and	#$00FE,d1		; Paula revision (bits 7..1)
		cmp	#$0002,d1		;   0 for classic Amiga, 1 for SAGA
		beq	.done
	;-- 8361/8370
		moveq	#IDAG_8361,d0
		move	$dff004,d1		; VPOSR
		and	#$7f00,d1		; mask
		cmp	#$1000,d1
		beq	.tst_fat
	;-- 8367/8371
		addq	#1,d0
		tst	d1
		beq	.tst_fat
	;-- 8372/8374
		addq	#3,d0
		bclr	#12,d1			; ignore PAL/NTSC flag
		sub	#$2000,d1		; bring revision number in range
		bcs	.unknown
		cmp	#$0300,d1
		bhi	.unknown
		lsr	#8,d1			; add to result number
		add	d1,d0
.done		rts
	;-- unknown Agnus revision, new Amiga?!
.unknown	moveq	#IDAG_UNKNOWN,d0
		rts

	;-- check if Fat (8370/8371) or Classic (8361/8367) Agnus
.tst_fat	exec	Disable
		move	$dff002,d2		; classic Agnus has a register mirror
		move	$dc0002,d3		; at $DC00000.
		exec.q	Enable
		cmp	d2,d3
		beq	.is_old
		addq	#2,d0
.is_old		rts

**
* Evaluates Agnus PAL/NTSC mode.
*
do_AgnusMode	moveq	#IDAM_NONE,d0
		move.b	(flags_draco,PC),d1	; DraCo has no Agnus at all.
		bne	.done
		move	$dff004,d1
		moveq	#IDAM_NTSC,d0
		btst	#12,d1
		bne	.done
		moveq	#IDAM_PAL,d0
.done		rts

**
* What Denise/Lisa/Isabel version is present?
*
do_Denise	moveq	#IDDN_NONE,d0
		move.b	(flags_draco,PC),d1	; DraCo has no Denise at all.
		bne	.done
	;-- Isabel (SAGA)
		moveq	#IDDN_ISABEL,d0
		move	$dff016,d1
		and	#$00FE,d1		; Paula revision (bits 7..1)
		cmp	#$0002,d1		;   0 for classic Amiga, 1 for SAGA
		beq	.done
	;-- 8362
		moveq	#IDDN_8362,d0
		move	$dff07c,d1		; LISAID
		and	#$00FF,d1
		moveq	#32,d3
.checkloop	move	$dff07c,d2
		and	#$00FF,d2
		cmp	d1,d2			; both reads must be equal
		bne	.done			;  no -> very old 8362 Denise
		dbra	d3,.checkloop
	;-- 8373
		and	#$000F,d1
		moveq	#IDDN_8373,d0
		cmp	#$0C,d1
		beq	.done
	;-- 4203 (AGA/Lisa)
		moveq	#IDDN_4203,d0		; wrongly called IDDN_8364 before
		cmp	#$08,d1
		beq	.done
	;-- unknown, a new Amiga? :-)
.unknown	moveq	#IDDN_UNKNOWN,d0
.done		rts

**
* What Denise Revision is present?
*
do_DeniseRev	moveq	#-1,d0
		move.b	(flags_draco,PC),d1	; DraCo has no Denise at all.
		bne	.done
	;-- 8362
		move	$dff07c,d1		; LISAID
		and	#$00FF,d1
		move	$dff07c,d2
		and	#$00FF,d2
		cmp	d1,d2			; both reads must be equal
		bne	.done			;   no -> very old Denise without rev
	;-- 8373/8364
		move	$dff07c,d0
		and.l	#$000000F0,d0
		eor	#$00F0,d0		; invert revision (F->0, E->1 ...)
		lsr	#4,d0
.done		rts

**
* What Paula/Arne version is present?
*
do_Paula	moveq	#IDPL_NONE,d0
		move.b	(flags_draco,PC),d1	; DraCo has no Paula at all.
		bne	.done
	;-- Paula
		moveq	#IDPL_8364,d0
		move	$dff016,d1
		and	#$00FE,d1		; Paula revision (bits 7..1)
		beq	.done			;   0 = Paula
	;-- Arne (SAGA)
		moveq	#IDPL_ARNE,d0
		cmp	#$0002,d1		;   1 = Arne
		beq	.done
	;-- unknown, a new Amiga? :-)
.unknown	moveq	#IDPL_UNKNOWN,d0
.done		rts

**
* What BoingBag is installed?
*
do_BoingBag	moveq	#0,d3
		lea	(versionname,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.nobb
		move.l	d0,a1
	;-- read version,revision
		move	(LIB_VERSION,a1),d0
		move	(LIB_REVISION,a1),d1
	;-- V44
		cmp	#44,d0
		bne	.non_v44
		cmp	#2,d1			; <= V44.2 -> no BB
		bls	.found
		moveq	#1,d3
		cmp	#4,d1			; <= V44.4 -> BB1
		bls	.found
		moveq	#2,d3
		cmp	#5,d1			; <= V44.5 -> BB2
		bls	.found
		moveq	#3,d3			; must be a BB3 :)
		bra	.found
	;-- V45
.non_v44	cmp	#45,d0
		bne	.non_v45
		cmp	#1,d1			; <= V45.1 -> no BB
		bls	.found
		moveq	#1,d3
		cmp	#2,d1			; <= V45.2 -> BB1
		bls	.found
		moveq	#2,d3
		cmp	#3,d1			; <= V45.3 -> BB2
		bls	.found
		moveq	#3,d3			; must be a BB3 :)
	;-- no more BoingBags in later versions
.non_v45
.found		exec.q	CloseLibrary
.nobb		move.l	d3,d0
		rts

**
* Check if we're living in an emulator.
*
do_Emulated	moveq	#1,d0
		lea	(flags_emulated,PC),a0
		tst.b	(a0)
		bne	.done
		moveq	#0,d0
.done		rts

**
* Check the AmigaXL version.
*
	defhws	xl_native, "native.library"

do_XLVersion	moveq	#0,d3
		lea	(xl_native,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.found
		move.l	d0,a6
		jsr	(-90,a6)		; GetXLVersion()
		move.l	d0,d3
		move.l	a6,a1
		exec	CloseLibrary
.found		move.l	d3,d0
		rts

**
* Get the AmigaXL host operating system.
*
do_HostOS	moveq	#0,d3
		lea	(xl_native,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.found
		move.l	d0,a6
		moveq	#NATIVE_HOST_OSNAME,d0
		jsr	(-84,a6)		; GetHostString()
		move.l	d0,d3
		move.l	a6,a1
		exec	CloseLibrary
.found		move.l	d3,d0
		rts

**
* Get the AmigaXL host version.
*
do_HostVers	moveq	#0,d3
		lea	(xl_native,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.found
		move.l	d0,a6
		moveq	#NATIVE_HOST_OSVERS,d0
		jsr	(-84,a6)		; GetHostString()
		move.l	d0,d3
		move.l	a6,a1
		exec	CloseLibrary
.found		move.l	d3,d0
		rts

**
* Get the AmigaXL host machine.
*
do_HostMachine	moveq	#0,d3
		lea	(xl_native,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.found
		move.l	d0,a6
		moveq	#NATIVE_HOST_MACHINE,d0
		jsr	(-84,a6)		; GetHostString()
		move.l	d0,d3
		move.l	a6,a1
		exec	CloseLibrary
.found		move.l	d3,d0
		rts

**
* Get the AmigaXL host CPU.
*
do_HostCPU	moveq	#0,d3
		lea	(xl_native,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.found
		move.l	d0,a6
		moveq	#NATIVE_HOST_CPUID,d0
		jsr	(-84,a6)		; GetHostString()
		move.l	d0,d3
		move.l	a6,a1
		exec	CloseLibrary
.found		move.l	d3,d0
		rts

**
* Get the AmigaXL host CPU speed.
*
do_HostSpeed	moveq	#0,d3
		lea	(xl_native,a4),a1
		moveq	#0,d0
		exec	OpenLibrary
		tst.l	d0
		beq	.found
		move.l	d0,a6
		moveq	#NATIVE_HOST_CPUSPEED,d0
		jsr	(-84,a6)		; GetHostString()
		move.l	d0,d3
		move.l	a6,a1
		exec	CloseLibrary
	;-- convert to int
.convert	tst.l	d3
		beq	.found
		move.l	d3,d1
		pea	0.w
		move.l	SP,d2
		dos	StrToLong
		move.l	(SP)+,d3
.found		move.l	d3,d0
		rts

**
* Get the hardware Realtime Clock.
*
do_RTC	; This code assumes that the battclock.resource has already
	; initialized the RTC.
		lea	$dc0000,a0		; RTC base address
		moveq	#$f,d1			; mask for lower nibble
	;-- check OKI
		moveq	#IDRTC_OKI,d3
		move.b	($3f,a0),d0		; read register F
		and	d1,d0
		cmp	#%0100,d0		;   only 24/12 bit must be set
		beq	.found
	;-- check Ricoh
		moveq	#IDRTC_RICOH,d3
		move.b	($37,a0),d0		; read mode register
		and	d1,d0
		cmp	#%1001,d0		; Mode 01?
		beq	.fastRicoh
	;-- check Ricoh in wrong mode
		exec	Forbid
		move	d0,d2			; remember current Mode register
		move.b	#%1001,($37,a0)		; set TimerEN + Mode 01
		move.b	($2b,a0),d0		; read 12/24 select register
		move.b	d2,($37,a0)		; restore Mode register
		exec.q	Permit
		bra	.checkRicoh
.fastRicoh	move.b	($2b,a0),d0		; read 12/24 select register
.checkRicoh	btst	#0,d0
		bne	.found
	;-- unknown or not found
.notRicoh	moveq	#IDRTC_NONE,d3
.found		move.l	d3,d0
		rts


*
* ======== Helper Functions ========
*

**
* Build the table of available RAM sizes.
*
BuildRAMtab	lea	(mem_all_plain,PC),a1
		moveq	#0,d0			; all RAM types
		bsr	GetRAMSize
		move.l	d0,(a1)+
		move.l	d1,(a1)+
		move.l	#MEMF_FAST,d0		; Fast RAM only
		bsr	GetRAMSize
		move.l	d0,(a1)+
		move.l	d1,(a1)+
		move.l	#MEMF_CHIP,d0		; Chip RAM only
		bsr	GetRAMSize
		move.l	d0,(a1)+
		move.l	d1,(a1)+
		rts

**
* Get the available RAM sizes of a certain type.
*
*	-> D0.l Type of mem
*	<- D0.l Size of real RAM
*	<- D1.l Size of virtual RAM
*
GetRAMSize	movem.l d2-d4/a0-a1,-(SP)
		move.l	d0,d4
	;-- evaluate virtual RAM
		moveq	#0,d3			; aggregate here
		move.l	(execbase,PC),a0
		move.l	(MemList,a0),a0		; iterate through memory list
.loop		lea	(.vmmname,PC),a1
		exec	FindName
		beq	.novmm
		move.l	d0,a0
		move	(MH_ATTRIBUTES,a0),d0
		and	d4,d0
		cmp	d4,d0
		bne	.loop
		move.l	(MH_UPPER,a0),d0	; compute memory size
		move.l	(MH_LOWER,a0),d1
		sub.l	#MH_SIZE,d1
		sub.l	d1,d0
		add.l	d0,d3			; add to VMM aggregator
		bra	.loop
	;-- evaluate total RAM
.novmm		move.l	d4,d1
		bset	#MEMB_TOTAL,d1
		exec	AvailMem
		move.l	d3,d1
		sub.l	d3,d0
		movem.l (SP)+,d2-d4/a0-a1
		rts

.vmmname	dc.b	"VMM Mem (paged)",0
		even

**
* Fill CPU and FPU clock table.
*
CalcClock	lea	(flags_gotclock,PC),a1	; Clock present?
		tst.b	(a1)
		bne	.done			;  yes -> done
		lea	(flags_emulated,PC),a0
		tst.b	(a0)
		bne	.emulated		;  yes -> don't measure the clock
		bsr	GetClocks
.complete	move.l	d0,cpuclk
		move.l	d1,fpuclk
		st	(a1)
.done		rts
.emulated	moveq	#0,d0
		moveq	#0,d1
		bra	.complete

**
* Read last alert and last alert task.
*
* Use the Blitter if possible, to avoid an Enforcer hit. People are starting to
* get on my nerves with that. :(
*
*	<- D0.l	Last alert (from $100)
*	<- D1.l	Last alert task (from $104)
*
ReadLastAlert	move.b	(flags_draco,PC),d0	; DraCo has no Blitter
		bne	.noblit			;   so read immediately
	;-- allocate target memory
		moveq	#8,d0
		move.l	#MEMF_CHIP,d1		; must be Chip-RAM
		exec	AllocMem
		move.l	d0,a3
		tst.l	d0			; read immediately if no memory left
		beq	.noblit
	;-- read via Blitter
		gfx	OwnBlitter		; ugly, but simple...
		gfx	WaitBlit
		lea	$dff000,a2
		move.l	a3,($054,a2)		; target: our memory allocation
		moveq	#0,d0
		move.l	d0,($064,a2)		; no modulo
		move	#$0100,d0
		move.l	d0,($050,a2)		; source: $00000100
		moveq	#-1,d0
		move.l	d0,($044,a2)		; do not mask bits
		move.l	#$09F00000,($040,a2)	; DMA-A DMA-D, simple copy miniterm
		move	#$0042,($058,a2)	; size is 2 row with 2 words
		gfx	WaitBlit		; wait for Blitter do be done
		gfx	DisownBlitter
		move.l	(a3),d3			; read alert code from allocated memory
		move.l	(4,a3),d4		; read alert task
	;-- free target memory
		move.l	a3,a1
		moveq	#8,d0
		exec	FreeMem
	;-- return alert code
		move.l	d3,d0
		move.l	d4,d1
		rts
	;-- cannot use blitter
.noblit		move.l	$100.w,d0		; read $100 immediately
		move.l	$104.w,d1		; read $104 immediately
		rts

**
* Find the start address of the physical ROM.
*
*	-> A0.l	ROM address
*
RomStart	lea	$FC0000,a0		; Assume FC0000 first
		cmp	#$1111,(a0)		; verify there is a 256KB ROM structure
		bne	.bad
		cmp	#$4EF9,(2,a0)		; jmp instruction?
		bne	.bad
		move.l	(4,a0),d0		; read jmp target
		and.l	#$FFFC0000,d0		; round down to actual ROM start
		move.l	d0,a0
		rts
	;-- must be a 512KB ROM
.bad		lea	$F80000,a0
		rts


*
* ======== Variables ========
*
db_semaphore	dcb.b	SS_SIZE,0	; Cache Semaphore

	; -- vvv KEEP ORDER OF THESE VARIABLES!!! vvv --
mem_all_plain	dc.l	0		; total real RAM
mem_all_vmm	dc.l	0		; total virtual RAM
mem_fast_plain	dc.l	0		; real Fast RAM
mem_fast_vmm	dc.l	0		; virtual Fast RAM
mem_chip_plain	dc.l	0		; real Chip RAM
mem_chip_vmm	dc.l	0		; virtual Chip RAM
	; -- ^^^ KEEP ORDER OF THESE VARIABLES!!! ^^^ --

cpuclk		dc.l	0		; CPU clock
fpuclk		dc.l	0		; FPU clock
flags_draco	dc.b	0		; -1 on DraCo systems
flags_gotclock	dc.b	0		; -1 when CPU/FPU clock is evaluated
flags_emulated	dc.b	0		; -1 if sytem is emulated
		even

		SECTION blank,BSS
entrynums	ds.l	IDHW_NUMBEROF	; Cache of numerical results
buildflags	ds.b	IDHW_NUMBEROF	; true if numerical result is present
