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

		INCLUDE exec/ports.i
		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i
		INCLUDE dos/dos.i
		INCLUDE dos/rdargs.i
		INCLUDE utility/tagitem.i
		INCLUDE libraries/identify.i
		INCLUDE libraries/configregs.i
		INCLUDE libraries/configvars.i
		INCLUDE libraries/commodities.i
		INCLUDE libraries/commodities_private.i
		INCLUDE libraries/locale.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/dos.i
		INCLUDE lvo/identify.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/commodities.i
		INCLUDE lvo/locale.i

VERSION		MACRO
		  dc.b	"13.2"
		ENDM
DATE		MACRO
		  dc.b	"20.11.2021"
		ENDM

IDENTIFY_VER	EQU	13

		SECTION strings,DATA
CATCOMP_BLOCK	SET	1
		INCLUDE LocaleTools.i
		dc.l	-1

		SECTION text,CODE

Start	;-- open resources
		lea	(dosname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,dosbase
		beq	.error1
		bsr	InitLocale
	;-- read parameters
		lea	(template,PC),a0
		move.l	a0,d1
		lea	(ArgList,PC),a0
		move.l	a0,d2
		moveq	#0,d3
		dos	ReadArgs
		move.l	d0,args
		bne	.parseok
		move.l	#MSG_LISTEXP_HAIL,d0
		bsr	GetLocString
		move.l	a0,d1
		pea	(url,PC)
		pea	(versionstr,PC)
		move.l	SP,d2
		dos	VPrintf
		addq.l	#2*4,SP
		move.l	#MSG_LISTEXP_HELP,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
		bra	.error2
	;-- open identify
.parseok	 move.l	#MSG_LISTEXP_HAIL,d0
		bsr	GetLocString
		move.l	a0,d1
		pea	(url,PC)
		pea	(versionstr,PC)
		move.l	SP,d2
		dos	VPrintf
		addq.l	#2*4,SP
		lea	(identifyname,PC),a1
		moveq	#IDENTIFY_VER,d0
		exec	OpenLibrary
		move.l	d0,identifybase
		bne	.gotid
		move.l	#MSG_NOIDENTIFY,d0
		bsr	GetLocString
		move.l	a0,d1
		pea	IDENTIFY_VER.w
		move.l	SP,d2
		dos	VPrintf
		addq.l	#4,SP
		bra	.error3
	;-- let's go
.gotid		move.l	(ArgList+arg_Update,PC),d0 	; Update?
		beq	.noupdate
		idfy	IdHardwareUpdate
		bra	.done
.noupdate	move.l	(ArgList+arg_Manuf,PC),d0 	; Manuf-ID
		beq	.nospec
		move.l	d0,a0
		move.l	(a0),d0
		move.l	(ArgList+arg_Prod,PC),d1	; Prod-ID
		beq	.nospec
		move.l	d1,a0
		move.l	(a0),d1
		bsr	Specific
		tst.l	d0
		bne	.error4
		bra	.done
.nospec		bsr	HardList
		bsr	ExpList
		move.l	(ArgList+arg_Full,PC),d0 	; also Commodities
		beq	.nocx
		bsr	CdityList
.nocx		lea	(msg_newline,PC),a0
		move.l	a0,d1
		dos	PutStr
	;-- done
.done		move.l	(identifybase,PC),a1
		exec	CloseLibrary
		move.l	(args,PC),d1
		dos	FreeArgs
		exec	CloseLibrary
		moveq	#0,d0
.exit		bsr	ExitLocale
		rts

	;-- error
.error4		move.l	(identifybase,PC),a1
		exec	CloseLibrary
.error3		move.l	(args,PC),d1
		dos	FreeArgs
.error2		move.l	(dosbase,PC),a1
		exec	CloseLibrary
.error1		moveq	#10,d0
		bra.b	.exit

**
* Find specific board.
*
*	-> D0.l	Manufacturer ID
*	-> D1.l Product ID
*	<- D0.l 0:OK, -1:Error
*
Specific	move.l	sp,d7
		cmp.l	#65535,d0		; max. 65535!
		bhi	.overflow
		cmp.l	#255,d1			; max. 255!
		bhi	.overflow
	;-- set up stack
		pea	TAG_DONE.w
		pea	(buf_class,PC)
		pea	IDTAG_ClassStr
		pea	(buf_prod,PC)
		pea	IDTAG_ProdStr
		pea	(buf_manuf,PC)
		pea	IDTAG_ManufStr
		move.l	d1,-(sp)
		pea	IDTAG_ProdID
		move.l	d0,-(sp)
		pea	IDTAG_ManufID
		move.l	sp,a0
		idfy	IdExpansion
		move.l	d7,sp
	;-- output
		pea	(buf_class,PC)
		pea	(buf_prod,PC)
		pea	(buf_manuf,PC)
		move.l	sp,d2
		move.l	#MSG_LISTEXP_SPECBOARD,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	VPrintf
		move.l	d7,sp
	;-- done
		moveq	#0,d0
		rts
	;-- error
.overflow	move.l	#MSG_LISTEXP_OVERFLOW,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
.error		moveq	#-1,d0
		rts

**
* Show hardware.
*
HardList	 move.l	sp,d7			; remember stack
	;-- first line
		sub.l	a0,a0
		lea	(.idtab1,PC),a1
.putloop1	move.l	(a1)+,d0
		bmi	.loopdone1
		idfy	IdHardware
		move.l	d0,-(sp)
		bra	.putloop1
.loopdone1	move.l	SP,d2
		move.l	#MSG_LISTEXP_HARDWARE,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	VPrintf
		move.l	d7,sp			; restore stack
	;-- PowerPC line
		moveq	#IDHW_POWERPC,d0
		sub.l	a0,a0
		idfy	IdHardwareNum
		tst.l	d0
		beq	.noppc
		sub.l	a0,a0
		lea	(.idtab2,PC),a1
.putloop2	move.l	(a1)+,d0
		bmi	.loopdone2
		idfy	IdHardware
		move.l	d0,-(sp)
		bra	.putloop2
.loopdone2	move.l	SP,d2
		move.l	#MSG_LISTEXP_POWERPC,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	VPrintf
		move.l	d7,sp			; restore stack
	;-- third line
.noppc		sub.l	a0,a0
		lea	(.idtab3,PC),a1
.putloop4	move.l	(a1)+,d0
		bmi	.loopdone4
		idfy	IdHardware
		move.l	d0,-(sp)
		bra	.putloop4
.loopdone4	move.l	SP,d2
		move.l	#MSG_LISTEXP_HARDWARE2,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	VPrintf
		move.l	d7,sp			; restore stack
		rts

	;-- output table for each row
.idtab3		dc.l	IDHW_RAM,IDHW_FASTRAM,IDHW_CHIPRAM
		dc.l	IDHW_VMMRAM,IDHW_VMMFASTRAM,IDHW_VMMCHIPRAM
		dc.l	IDHW_PLNRAM,IDHW_PLNFASTRAM,IDHW_PLNCHIPRAM
		dc.l	IDHW_SLOWRAM,IDHW_ROMSIZE,IDHW_RAMBANDWIDTH
		dc.l	IDHW_RAMCAS,IDHW_RAMACCESS,IDHW_RAMWIDTH
		dc.l	IDHW_ECLOCK,IDHW_VBLANKFREQ,IDHW_POWERFREQ
		dc.l	IDHW_TCPIP,IDHW_AUDIOSYS,IDHW_GFXSYS
		dc.l	IDHW_WBVER,IDHW_EXECVER,IDHW_SETPATCHVER
		dc.l	IDHW_BOINGBAG,IDHW_OSVER,IDHW_OSNR
		dc.l	IDHW_DENISEREV,IDHW_DENISE
		dc.l	IDHW_AGNUSMODE,IDHW_AGNUS
		dc.l	IDHW_VBR,IDHW_CHUNKYPLANAR,IDHW_GARY,IDHW_RAMSEY
		dc.l	IDHW_CHIPSET,-1
		dc.l	IDHW_HOSTVERS,IDHW_HOSTOS,IDHW_XLVERSION,-1
.idtab2		dc.l	IDHW_PPCOS,IDHW_PPCCLOCK,IDHW_POWERPC,-1
.idtab1		dc.l	IDHW_MMU,IDHW_FPUCLOCK,IDHW_FPU
		dc.l	IDHW_CPUREV,IDHW_CPUCLOCK,IDHW_CPU,IDHW_SYSTEM,-1


**
* List all expansions.
*
ExpList		move.l	SP,d7			; remember stack
		moveq	#1,d6
	;-- title row
		move.l	#MSG_LISTEXP_LISTTITLE,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
	;-- iterate through list
.loop		pea	TAG_DONE.w
		pea	(buf_class,PC)
		pea	IDTAG_ClassStr
		pea	(buf_prod,PC)
		pea	IDTAG_ProdStr
		pea	(buf_manuf,PC)
		pea	IDTAG_ManufStr
		pea	(.expvar,PC)
		pea	IDTAG_Expansion
		move.l	sp,a0
		idfy	IdExpansion
		move.l	d7,SP
		tst.l	d0
		bne	.done
	;-- output
		move.l	(.expvar,PC),a4
		pea	(buf_class,PC)		; board name
		pea	(buf_prod,PC)
		pea	(buf_manuf,PC)
		move.l	(cd_BoardSize,a4),d0	; board size
		moveq	#" ",d1
		cmp.l	#1024,d0		; >1024
		blo	.sizeok
		lsr.l	#8,d0
		lsr.l	#2,d0
		moveq	#"K",d1
		cmp.l	#1024,d0		; >1024K
		blo	.sizeok
		lsr.l	#8,d0
		lsr.l	#2,d0
		moveq	#"M",d1
		cmp.l	#1024,d0		; >1024M
		blo	.sizeok
		lsr.l	#8,d0
		lsr.l	#2,d0
		moveq	#"G",d1
.sizeok		move.l	d1,-(sp)
		move.l	d0,-(sp)
		move.l	(cd_BoardAddr,a4),-(sp)
		moveq	#0,d0
		move.b	(cd_Rom+er_Product,a4),d0
		move.l	d0,-(sp)
		moveq	#0,d0
		move	(cd_Rom+er_Manufacturer,a4),d0
		move.l	d0,-(sp)
		move.l	d6,-(sp)
		addq.l	#1,d6
		move.l	sp,d2
		move.l	#MSG_LISTEXP_BOARDLINE,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	VPrintf
		bra	.loop
	;-- done
.done		move.l	d7,SP
		rts

.expvar		dc.l	0

**
* Show Commodities.
*
CdityList	lea	(cxname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,cxbase
		beq	.nocx
	;-- print title
		move.l	#MSG_LISTEXP_CXTITLE,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
	;-- copy broker list
		sub.l	#LH_SIZE,sp
		move.l	sp,a0
		NEWLIST a0
		cx	CopyBrokerList
	;-- output list
		move.l	(sp),a4			; ^first node
.loop		tst.l	(a4)			; end of list?
		beq	.listdone
		move.l	sp,d7			; remember stack
		pea	(bc_Title,a4)
		pea	(bc_Name,a4)
		move.l	#MSG_LISTEXP_CXLINE,d0
		bsr	GetLocString
		move.l	a0,d1
		move.l	sp,d2
		dos	VPrintf
		move.l	d7,sp			; restore stack
		move.l	(a4),a4			; next node
		bra	.loop
	;-- release broker list
.listdone	move.l	sp,a0
		cx	FreeBrokerList
		add.l	#LH_SIZE,sp
	;-- close resources
		move.l	(cxbase,PC),a1
		exec	CloseLibrary
	;-- done
.nocx		rts

cxbase		dc.l	0
cxname		dc.b	"commodities.library",0
		even

**
* Initialize locale.
*
* If it fails, an internal set of English strings will be used as fallback.
*
InitLocale	movem.l d0-d3/a0-a3,-(sp)
	;-- open library
		lea	(.localename,PC),a1
		moveq	#38,d0
		exec	OpenLibrary
		move.l	d0,localebase
		beq	.nolocale
	;-- open catalog
		sub.l	a0,a0			; user's language
		lea	(.locname,PC),a1	; catalog name
		lea	(.nulltag,PC),a2	; no tags
		locale	OpenCatalogA
		move.l	d0,MyCatalog
	;-- done
.exit		movem.l (sp)+,d0-d3/a0-a3
		rts
	;-- fallback
.nolocale	clr.l	MyCatalog
		bra	.exit

.nulltag	dc.l	TAG_DONE
.localename	dc.b	"locale.library",0
.locname	dc.b	"identifytools.catalog",0
		even

**
* Close locale.
*
* Can be invoked even if initialization failed.
*
ExitLocale	movem.l d0-d3/a0-a3,-(sp)
		move.l	(localebase,PC),d0
		beq	.nolib
	;-- close catalog
		move.l	(MyCatalog,PC),a0
		locale	CloseCatalog
	;-- close library
		move.l	(localebase,PC),a1
		exec	CloseLibrary
	;-- done
.nolib		movem.l (sp)+,d0-d3/a0-a3
		rts

**
* Get a localized string.
*
* Returns "-?-" if there is no such string.
*
*	-> D0.l	String number
*	<- A0.l ^String (read only!)
*
GetLocString	movem.l d0-d3/a1-a3,-(sp)
		lea	CatCompBlock,a1
.check		move.l	(a1)+,d1
		bmi	.notfound
		cmp.l	d0,d1			; wanted ID?
		beq	.strfound
		adda.w	(a1)+,a1		; next ID
		bra	.check
.strfound	addq.l	#2,a1
	;-- library is opened?
.insert		move.l	(localebase,PC),d1
		beq	.nolocale
	;-- use library
		move.l	(MyCatalog,PC),a0
		locale	GetCatalogStr
		move.l	d0,a0
	;-- done
.exit		movem.l (sp)+,d0-d3/a1-a3
		rts

	;-- library is missing
.nolocale	move.l	a1,a0
		bra	.exit
	;-- string is missing
.notfound	lea	(.errstring,PC),a1
		bra	.insert

.errstring	dc.b	"-?-",0
		even


*
* ======== Variables ========
*
version		dc.b	0,"$VER: ListExp V"
		VERSION
		dc.b	" ("
		DATE
		dc.b	")",$d,$a,0
		even

dosbase		dc.l	0
identifybase	dc.l	0
localebase	dc.l	0
MyCatalog	dc.l	0
args		dc.l	0

	;-- Arguments
		rsreset
arg_Full	rs.l	1
arg_Manuf	rs.l	1
arg_Prod	rs.l	1
arg_Update	rs.l	1
arg_SIZEOF	rs.w	0

ArgList		ds.b	arg_SIZEOF
template	dc.b	"FULL/S,MID=MANUFID/K/N,PID=PRODID/K/N,U=UPDATE/S",0

url		dc.b	"https://identify.shredzone.org",0
versionstr	VERSION
		dc.b	0
msg_newline	dc.b	"\n",0

dosname		dc.b	"dos.library",0
identifyname	dc.b	"identify.library",0
		even

buf_class	ds.b	50
buf_prod	ds.b	50
buf_manuf	ds.b	50
		even
