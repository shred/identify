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
		INCLUDE exec/resident.i
		INCLUDE exec/execbase.i
		INCLUDE exec/memory.i
		INCLUDE libraries/configvars.i
		INCLUDE libraries/commodities.i
		INCLUDE libraries/commodities_private.i
		INCLUDE utility/tagitem.i
		INCLUDE rexx/rxslib.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/rexxsyslib.i
		INCLUDE lvo/identify.i
		INCLUDE lvo/commodities.i

		INCLUDE libraries/identify.i

		INCLUDE RI_Base.i

		SECTION text,CODE

VERSION		EQU	1		;<- Version
REVISION	EQU	13		;<- Revision

SETRELEASE	MACRO
		dc.b	"11"		;<- Command Release
		ENDM

SETVER		MACRO			;<- Version String Macro
		dc.b	"1.13"
		ENDM

SETDATE		MACRO			;<- Date String Macro
		dc.b	"20.11.2011"
		ENDM


CXSLOTS		EQU	32		; number of commodity slots

**
* Initialize library
*							*
Start		moveq	#0,d0
		rts

**
* Describe library
*							*
InitDDescrip	dc.w	RTC_MATCHWORD
		dc.l	InitDDescrip
		dc.l	EndCode
		dc.b	RTF_AUTOINIT,VERSION,NT_LIBRARY,0
		dc.l	libname,libidstring,Init
libname		dc.b	"rexxidentify.library",0
libidstring	dc.b	"rexxidentify.library "
		SETVER
		dc.b	" ("
		SETDATE
		dc.b	")",13,10,0

**
* Copyright note for hex reader
*
		dc.b	"ARexx support for the identify.library ",$a
		dc.b	"(C) 1997-2021 Richard 'Shred' K\xF6rber ",$a
		dc.b	"License: GNU Lesser General Public License v3 ",$a
		dc.b	"Source: https://identify.shredzone.org",0
		even
		cnop	0,4

**
* Init table
*
Init		dc.l	idb_SIZEOF,FuncTab,DataTab,InitFct

**
* Function table. Keep this order, only append!
*
FuncTab		dc.l	LOpen,LClose,LExpunge,LNull	;Standard
		dc.l	Query				;-30
		dc.l	-1					;-- Ende --

**
* Data table
*
DataTab		INITBYTE	 LN_TYPE,NT_LIBRARY
		INITLONG	 LN_NAME,libname
		INITBYTE	 LIB_FLAGS,LIBF_SUMUSED|LIBF_CHANGED
		INITWORD	 LIB_VERSION,VERSION
		INITWORD	 LIB_REVISION,REVISION
		INITLONG	 LIB_IDSTRING,libidstring
		dc.l	0

**
* Initialize library
*
*	-> D0.l	^LibBase
*	-> A0.l	^SegList
*	-> A6.l	^SysLibBase
*	<- D0.l	^LibBase
*
InitFct		movem.l d1-d7/a0-a6,-(sp)
	;-- remember vectors
		move.l	d0,a5
		move.l	a6,(idb_SysLib,a5)
		move.l	a0,(idb_SegList,a5)
	;-- open resources
		lea	(.rexxsyslibname,PC),a1
		moveq	#33,d0
		exec	OpenLibrary
		move.l	d0,rexxsyslibbase
		beq	.error1
		lea	(.expansionname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,expbase
		beq	.error2
		lea	(.cxname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,cxbase
		beq	.error3
		lea	(.identifyname,PC),a1
		moveq	#IDENTIFYVERSION,d0
		exec	OpenLibrary
		move.l	d0,identifybase
		beq	.error4
	;-- iterate list of expansions
		sub.l	a0,a0
		lea	expansions,a2
		moveq	#-1,d2
.exploop	moveq	#-1,d0
		moveq	#-1,d1
		expans	FindConfigDev
		addq	#1,d2
		move.l	d0,a0
		move.l	d0,(a2)+
		bne	.exploop
		move	d2,expnumbers		; remember number of boards
	;-- done
		move.l	a5,d0
.exit		movem.l (sp)+,d1-d7/a0-a6
		rts
	;-- error
.error4		move.l	(cxbase,PC),a1
		exec	CloseLibrary
.error3		move.l	(expbase,PC),a1
		exec	CloseLibrary
.error2		move.l	(rexxsyslibbase,PC),a1
		exec	CloseLibrary
.error1		moveq	#0,d0
		bra	.exit

.rexxsyslibname dc.b	"rexxsyslib.library",0
.expansionname	dc.b	"expansion.library",0
.cxname		dc.b	"commodities.library",0
.identifyname	dc.b	"identify.library",0
		even

**
* Open library
*
*	-> D0.l	Version
*	-> A6.l	^LibBase
*	<- D0.l	^LibBase if successful
*
LOpen		addq	#1,(LIB_OPENCNT,a6)
		bclr	#IDLB_DELEXP,(idb_Flags+1,a6)
		move.l	a6,d0
		rts

**
* Close library
*
*	-> A6.l	^LibBase
*	<- D0.l	^SegList or 0
*
LClose		moveq	#0,d0
		subq	#1,(LIB_OPENCNT,a6)
		bne.b	.notlast
		btst	#IDLB_DELEXP,(idb_Flags+1,a6)
		beq.b	.notlast
		bsr.b	LExpunge
.notlast	rts

**
* Expunge library
*
*	-> A6.l	^LibBase
*
LExpunge	 movem.l d2/a5-a6,-(sp)
	;-- check state
		move.l	a6,a5
		move.l	(idb_SysLib,a5),a6
		tst	(LIB_OPENCNT,a5)
		beq.b	.expimmed
.abort		bset	#IDLB_DELEXP,(idb_Flags+1,a5)
		moveq	#0,d0
		bra	.exit
	;-- close library
.expimmed	move.l	(idb_SegList,a5),d2
		move.l	a5,a1
		exec	Remove
	;-- free own resources
		move.l	(identifybase,PC),a1
		exec	CloseLibrary
		move.l	(cxbase,PC),a1
		exec	CloseLibrary
		move.l	(expbase,PC),a1
		exec	CloseLibrary
		move.l	(rexxsyslibbase,PC),a1
		exec	CloseLibrary
	;-- release memory
		moveq	#0,d0
		move.l	a5,a1
		move	(LIB_NEGSIZE,a5),d0
		sub.l	d0,a1
		add	(LIB_POSSIZE,a5),d0
		exec	FreeMem
	;-- done
		move.l	d2,d0
.exit		movem.l (sp)+,d2/a5-a6
		rts

**
* Do nothing
*
LNull		moveq	#0,d0
		rts

**
* Handle an ARexx query.
*
*	-> A0.l ^RexxMsg
*	<- A0.l ^RexxArg result or NULL
*	<- D0.l	return code
*
Query		movem.l d1-d7/a1-a6,-(SP)
		move.l	a0,a5
	;-- search command
		move.l	(rm_Args+0*4,a5),a0
		lea	(.commands,PC),a1
		bsr	strtoidx
		tst.l	d0			; found it?
		bmi	.err_program		;   no -> command not found
	;-- execute command
		add.l	d0,d0
		add.l	d0,d0
		lea	(.jumptab,PC),a4
		move.l	(a4,d0.l),a4
		jsr	(a4)
	;-- done
.exit		movem.l (SP)+,d1-d7/a1-a6
		rts
	;-- error
.err_program	moveq	#1,d0			; program not found
		sub.l	a0,a0			; no return string
		bra	.exit

	;-- Table of Commands Functions
.jumptab	dc.l	ID_Release
		dc.l	ID_Boards
		dc.l	ID_Expansion
		dc.l	ID_Hardware
		dc.l	ID_Function
		dc.l	ID_Alert
		dc.l	ID_ExpName
		dc.l	ID_LockCX
		dc.l	ID_CountCX
		dc.l	ID_GetCX
		dc.l	ID_UnlockCX
		dc.l	ID_Update

	;-- Table of Command Names
.commands	dc.b	"ID_RELEASE",0
		dc.b	"ID_NUMBOARDS",0
		dc.b	"ID_EXPANSION",0
		dc.b	"ID_HARDWARE",0
		dc.b	"ID_FUNCTION",0
		dc.b	"ID_ALERT",0
		dc.b	"ID_EXPNAME",0
		dc.b	"ID_LOCKCX",0
		dc.b	"ID_COUNTCX",0
		dc.b	"ID_GETCX",0
		dc.b	"ID_UNLOCKCX",0
		dc.b	"ID_UPDATE",0
		dc.b	0			; end marker
		even


*
* ======== ARexx Functions ========
*
* All function handlers use this register allocation:
*
*	-> A5.l	^RexxMsg
*	<- A0.l ^RexxArg result or NULL
*	<- D0.l Return Code
*
* All other registers can be scratched.
*

**
* Return release number of the library.
*
* ARexx:	IDRelease()
*
ID_Release	lea	(.releasestr,PC),a0
		strln.b a0,d0
		subq.l	#1,d0
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
		rts
.releasestr	SETRELEASE
		dc.b	" "
		SETVER
		dc.b	"("
		SETDATE
		dc.b	")",0
		even

**
* Return number of expansions in this system.
*
* ARexx:	IDBoards()
*
		clrfo
idb_Buffer	fo.b	20			; String buffer
idb_LENGTH	fo.w	0

ID_Boards	link	a4,#idb_LENGTH
		moveq	#0,d0
		move	expnumbers,d0
		lea	(idb_Buffer,a4),a0
		bsr	numtostr
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
		unlk	a4
		rts

**
* Evaluate an expansion.
*
* Arexx:	IDExpansion(BoardNr,[MANUF|PROD|CLASS|ADDRESS|SIZE|VALID|SECONDARY|
*			CLASSID|MANUFID|PRODID])
*
		clrfo
ide_Buffer	fo.b	IDENTIFYBUFLEN		; String buffer
ide_ConfigDev	fo.l	1			; ^ConfigDev
ide_ClassID	fo.l	1			; ClassID
ide_LENGTH	fo.w	0

ID_Expansion	link	a4,#ide_LENGTH
	;-- get board number
		move.l	(rm_Args+1*4,a5),d0	; read Args[1]
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay
		tst.b	(a0)
		bne	.error
.numokay	moveq	#0,d1			; in range?
		move	expnumbers,d1
		cmp.l	d1,d0
		bhi	.error			;   no -> error
		add.l	d0,d0
		add.l	d0,d0
		lea	expansions,a0
		move.l	(a0,d0.l),(ide_ConfigDev,a4)
	;-- what result type is requested?
		move.l	(rm_Args+2*4,a5),d0	; read Args[2]
		beq	.error
		move.l	d0,a0
		lea	(.results,PC),a1	; result table
		bsr	strtoidx
		tst.l	d0			; in range?
		bmi	.error
		subq.l	#3,d0			; what about identify?
		bcs	.identify
		subq.l	#1,d0
		bcs	.address
		subq.l	#1,d0
		bcs	.size
		subq.l	#1,d0
		bcs	.shutup
		subq.l	#1,d0
		bcs	.secondary
		subq.l	#1,d0
		bcs	.classid
		subq.l	#1,d0
		bcs	.manufid
		subq.l	#1,d0
		bcs	.prodid
		bra	.error
	;---- address
.address	move.l	(ide_ConfigDev,a4),a0
		move.l	(cd_BoardAddr,a0),d0
		lea	(ide_Buffer,a4),a0
		bsr	hextostr
		bra	.result
	;---- size
.size		move.l	(ide_ConfigDev,a4),a0
		move.l	(cd_BoardSize,a0),d0
		lea	(ide_Buffer,a4),a0
		lsr.l	#8,d0
		lsr.l	#2,d0			; result is in KB
		bsr	numtostr
		bra	.result
	;---- shutup
.shutup		move.l	(ide_ConfigDev,a4),a0
		moveq	#0,d0
		move.b	(cd_Flags,a0),d0
		btst	#CDB_SHUTUP,d0
		sne	d0
		neg.b	d0
		lea	(ide_Buffer,a4),a0
		bsr	numtostr
		bra	.result
	;---- classid
.classid	move.l	SP,d7
		pea	TAG_DONE.w
		move.l	(ide_ConfigDev,a4),-(SP)
		pea	IDTAG_ConfigDev		; IDTAG_ConfigDev,cdev
		pea	(ide_ClassID,a4)
		pea	IDTAG_ClassID
		move.l	SP,a0
		idfy	IdExpansion
		move.l	d7,SP
		lea	(ide_Buffer,a4),a0
		move.l	(ide_ClassID,a4),d0
		bsr	numtostr
		bra	.result
	;---- manufid
.manufid	move.l	(ide_ConfigDev,a4),a0
		moveq	#0,d0
		move	(cd_Rom+er_Manufacturer,a5),d0
		lea	(ide_Buffer,a4),a0
		bsr	numtostr
		bra	.result
	;---- prodid
.prodid		move.l	(ide_ConfigDev,a4),a0
		moveq	#0,d0
		move.b	(cd_Rom+er_Product,a5),d0
		lea	(ide_Buffer,a4),a0
		bsr	numtostr
		bra	.result
	;---- secondary
.secondary	move.l	SP,d7
		pea	TAG_DONE.w
		move.l	(ide_ConfigDev,a4),-(SP)
		pea	IDTAG_ConfigDev		; IDTAG_ConfigDev,cdev
		pea	(ide_Buffer,a4)
		pea	IDTAG_ProdStr
		pea	-1.w
		pea	IDTAG_Secondary
		move.l	SP,a0
		idfy	IdExpansion
		move.l	d7,SP
		lea	(.txt_secondary,PC),a0	; secondary?
		cmp.l	#IDERR_SECONDARY,d0
		beq	.result
		lea	(.txt_primary,PC),a0	; Primary?
		tst.l	d0
		beq	.result
		bra	.error
	;---- identify result
.identify	move.l	SP,d7
		pea	TAG_DONE.w
		move.l	(ide_ConfigDev,a4),-(SP)
		pea	IDTAG_ConfigDev		; IDTAG_ConfigDev,cdev
		pea	(ide_Buffer,a4)
		add.l	#IDTAG_ClassStr+1,d0
		move.l	d0,-(SP)		; ~IDTAG_ClassStr,buff
		move.l	SP,a0
		idfy	IdExpansion
		move.l	d7,SP
		tst.l	d0
		bne	.error
		lea	(ide_Buffer,a4),a0
	;-- format result
.result		strln.b a0,d0
		subq.l	#1,d0
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts
	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

.txt_primary	dc.b	"Primary",0
.txt_secondary	dc.b	"Secondary",0
		even

.results	dc.b	"MANUF",0
		dc.b	"PROD",0
		dc.b	"CLASS",0
		dc.b	"ADDRESS",0
		dc.b	"SIZE",0
		dc.b	"SHUTUP",0
		dc.b	"SECONDARY",0
		dc.b	"CLASSID",0
		dc.b	"MANUFID",0
		dc.b	"PRODID",0
		dc.b	0		; end marker
		even

**
* Evaluate expansion by ID.
*
* Arexx:	IDExpName(ManufID,BoardID,[MANUF|PROD|CLASS])
*
		clrfo
idn_Buffer	fo.b	IDENTIFYBUFLEN		; String buffer
idn_ManufID	fo.l	1
idn_ProdID	fo.l	1
idn_LENGTH	fo.w	0

ID_ExpName	link	a4,#idn_LENGTH
	;-- find manufacturer number
		move.l	(rm_Args+1*4,a5),d0	; read Args[1]
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay
		tst.b	(a0)
		bne	.error
.numokay	cmp.l	#65535,d0		; Manuf < 65536
		bhi	.error
		move.l	d0,(idn_ManufID,a4)
	;-- board number
		move.l	(rm_Args+2*4,a5),d0	; read Args[2]
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay2
		tst.b	(a0)
		bne	.error
.numokay2	cmp.l	#255,d0			; Prod < 256
		bhi	.error
		move.l	d0,(idn_ProdID,a4)
	;-- requested result type
		move.l	(rm_Args+3*4,a5),d0	; read Args[3]
		beq	.error
		move.l	d0,a0
		lea	(.results,PC),a1
		bsr	strtoidx
		tst.l	d0
		bmi	.error
	;---- identify result
		move.l	SP,d7
		pea	TAG_DONE.w
		move.l	(idn_ProdID,a4),-(SP)
		pea	IDTAG_ProdID
		move.l	(idn_ManufID,a4),-(SP)
		pea	IDTAG_ManufID
		pea	(idn_Buffer,a4)
		add.l	#IDTAG_ManufStr,d0
		move.l	d0,-(SP)		; ~IDTAG_ClassStr,buff
		move.l	SP,a0
		idfy	IdExpansion
		move.l	d7,SP
		tst.l	d0
		bne	.error
		lea	(idn_Buffer,a4),a0
	;-- format result
.result		strln.b a0,d0
		subq.l	#1,d0
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts
	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

.results	dc.b	"MANUF",0
		dc.b	"PROD",0
		dc.b	"CLASS",0
		dc.b	0		; end marker
		even

**
* Evaluate hardware string.
*
* Arexx:	IDHardware [SYSTEM|CPU|FPU|MMU|...],{EMPTYNA},{NOLOCALE}
*
		clrfo
idh_EmptyNA	fo.b	1			; -1: empty string when N/A
idh_Nolocale	fo.b	1			; -1: no locale
idh_Buffer	fo.b	IDENTIFYBUFLEN		; string buffer
idh_LENGTH	fo.w	0

ID_Hardware	link	a4,#idh_LENGTH
	;-- read options
		sf	(idh_EmptyNA,a4)
		sf	(idh_Nolocale,a4)
		move.l	(rm_Action,a5),d1
		lea	(rm_Args+2*4,a5),a3
.optloop	subq.b	#1,d1
		beq	.nona
		move.l	(a3)+,d0
		beq	.optloop
		move.l	d0,a0
		lea	(.options,PC),a1
		bsr	strtoidx
		tst.l	d0
		bmi	.error
		subq.l	#1,d0			; is it EMPTYNA?
		bcs	.emptyna
		subq.l	#1,d0			; is it NOLOCALE?
		bcs	.nolocale
		bra	.optloop
.emptyna	st	(idh_EmptyNA,a4)
		bra	.optloop
.nolocale	st	(idh_Nolocale,a4)
		bra	.optloop
.nona
	;-- check desired result type
		move.l	(rm_Args+1*4,a5),d0
		beq	.error
		move.l	d0,a0
		lea	(.results,PC),a1
		bsr	strtoidx
		tst.l	d0
		bmi	.error
	;-- evaluate
		move.l	SP,a3
		pea	TAG_DONE.w
		tst.b	(idh_EmptyNA,a4)
		beq	.tag_empty
		pea	-1.w			; TRUE
		pea	IDTAG_NULL4NA
.tag_empty	tst.b	(idh_Nolocale,a4)
		beq	.tag_localize
		pea	0.w			; FALSE
		pea	IDTAG_Localize
.tag_localize	move.l	SP,a0
		idfy	IdHardware
		move.l	a3,SP
		move.l	d0,a0
		tst.l	d0
		bne	.non_null
		lea	(.nullstr,PC),a0
.non_null	strln.b a0,d0
		subq.l	#1,d0
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts
	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

.results	dc.b	"SYSTEM",0
		dc.b	"CPU",0
		dc.b	"FPU",0
		dc.b	"MMU",0
		dc.b	"OSVER",0
		dc.b	"EXECVER",0
		dc.b	"WBVER",0
		dc.b	"ROMSIZE",0
		dc.b	"CHIPSET",0
		dc.b	"GFXSYS",0
		dc.b	"CHIPRAM",0
		dc.b	"FASTRAM",0
		dc.b	"RAM",0
		dc.b	"SETPATCHVER",0
		dc.b	"AUDIOSYS",0
		dc.b	"OSNR",0
		dc.b	"VMMCHIPRAM",0
		dc.b	"VMMFASTRAM",0
		dc.b	"VMMRAM",0
		dc.b	"PLNCHIPRAM",0
		dc.b	"PLNFASTRAM",0
		dc.b	"PLNRAM",0
		dc.b	"VBR",0
		dc.b	"LASTALERT",0
		dc.b	"VBLANKFREQ",0
		dc.b	"POWERFREQ",0
		dc.b	"ECLOCK",0
		dc.b	"SLOWRAM",0
		dc.b	"GARY",0
		dc.b	"RAMSEY",0
		dc.b	"BATTCLOCK",0
		dc.b	"CHUNKYPLANAR",0
		dc.b	"POWERPC",0
		dc.b	"PPCCLOCK",0
		dc.b	"CPUREV",0
		dc.b	"CPUCLOCK",0
		dc.b	"FPUCLOCK",0
		dc.b	"RAMACCESS",0
		dc.b	"RAMWIDTH",0
		dc.b	"RAMCAS",0
		dc.b	"RAMBANDWIDTH",0
		dc.b	"TCPIP",0
		dc.b	"PPCOS",0
		dc.b	"AGNUS",0
		dc.b	"AGNUSMODE",0
		dc.b	"DENISE",0
		dc.b	"DENISEREV",0
		dc.b	"BOINGBAG",0
		dc.b	"EMULATED",0
		dc.b	"XLVERSION",0
		dc.b	"HOSTOS",0
		dc.b	"HOSTVERS",0
		dc.b	"HOSTMACHINE",0
		dc.b	"HOSTCPU",0
		dc.b	"HOSTSPEED",0
		dc.b	0		; end marker

.options	dc.b	"EMPTYNA",0
		dc.b	"NOLOCALE",0
		dc.b	0		; end marker

.nullstr	dc.b	0		; empty string
		even

**
* Decode a library function offset.
*
* Arexx:	IDFunction(LibName,Offset)
*
		clrfo
idf_Buffer	fo.b	IDENTIFYBUFLEN		; string buffer
idf_LENGTH	fo.w	0

ID_Function	link	a4,#idf_LENGTH
	;-- get function offset
		move.l	(rm_Args+2*4,a5),d0
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay
		tst.b	(a0)
		bne	.error
	;-- get library name
.numokay	move.l	(rm_Args+1*4,a5),d1
		beq	.error
		move.l	d1,a0
		pea	TAG_DONE.w
		pea	(idf_Buffer,a4)
		pea	IDTAG_FuncNameStr
	;-- decode function
		move.l	SP,a1
		idfy	IdFunction
		add.l	#3*4,SP
		tst.l	d0
		bne	.error
	;-- build result
		lea	(idf_Buffer,a4),a0
		strln.b a0,d0
		subq.l	#1,d0
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts
	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

**
* Decode an alert.
*
* ARexx:	IDAlert(Code,[DEAD|SUBSYS|GENERAL|SPEC])
*
		clrfo
ida_Buffer	fo.b	IDENTIFYBUFLEN		; string buffer
ida_LENGTH	fo.w	0

ID_Alert	 link	a4,#ida_LENGTH
	;-- evaluate code
		move.l	(rm_Args+1*4,a5),d0	; Args[1]
		beq	.error
		move.l	d0,a0
		bsr	strtohex
		cmp.b	#" ",(a0)
		beq	.numokay
		tst.b	(a0)
		bne	.error
.numokay	move.l	d0,d6
	;-- what result type is requested?
		move.l	(rm_Args+2*4,a5),d0	; Args[2]
		beq	.error
		move.l	d0,a0
		lea	(.results,PC),a1
		bsr	strtoidx
		tst.l	d0
		bmi	.error
	;-- calculate result
		move.l	SP,d7
		pea	TAG_DONE.w
		pea	(ide_Buffer,a4)
		add.l	#IDTAG_DeadStr,d0
		move.l	d0,-(SP)		; ~IDTAG_DeadStr,buff
		move.l	SP,a0
		move.l	d6,d0
		idfy	IdAlert
		move.l	d7,SP
		tst.l	d0
		bne	.error
		lea	(ide_Buffer,a4),a0
	;-- format result
.result		strln.b a0,d0
		subq.l	#1,d0
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts

	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

.results	dc.b	"DEAD",0
		dc.b	"SUBSYS",0
		dc.b	"GENERAL",0
		dc.b	"SPEC",0
		dc.b	0
		even

**
* Lock a commodity slot.
*
* ARexx:	IDLockCX()
*
		clrfo
idlcx_Slot	fo.l	1			; slot number
idlcx_Buffer	fo.b	20			; string buffer
idlcx_LENGTH	fo.w	0

ID_LockCX	link	a4,#idlcx_LENGTH
	;-- find slot
		moveq	#0,d1			; slot number
		moveq	#CXSLOTS-1,d0		; number of slots
		lea	cxslots,a0
.find		tst.l	(a0)			; empty?
		beq	.found
		add.l	#MLH_SIZE,a0		; next list
		addq.l	#1,d1
		dbra	d0,.find
		bra	.error			; no empty slot
.found		move.l	d1,(idlcx_Slot,a4)
		NEWLIST a0
		cx	CopyBrokerList		; copy broker list
	;-- format result
		move.l	(idlcx_Slot,a4),d0
		lea	(idlcx_Buffer,a4),a0
		bsr	numtostr
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts

	;-- error
.error		moveq	#12,d0			;Fehler
		sub.l	a0,a0
		bra	.exit

**
* Count the commodities in a list.
*
* ARexx:	IDCountCX(Slot)
*
		clrfo
idccx_Buffer	fo.b	20			; string buffer
idccx_LENGTH	fo.w	0

ID_CountCX	link	a4,#idccx_LENGTH
	;-- evaluate slot number
		move.l	(rm_Args+1*4,a5),d0	; Args[1]
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay
		tst.b	(a0)
		bne	.error
	;-- calculate result
.numokay	cmp.l	#CXSLOTS,d0		; slot number in range?
		bhs	.error			;   nope -> error
		mulu	#MLH_SIZE,d0
		lea	cxslots,a0
		add.l	d0,a0
		tst.l	(a0)			; allocated
		beq	.error			;   nope -> error
		moveq	#-1,d0			; counter
.loop		move.l	(a0),a0
		addq.l	#1,d0
		tst.l	(a0)
		bne	.loop
		lea	(idccx_Buffer,a4),a0
		bsr	numtostr
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts

	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

**
* Read commodity entry.
*
* ARexx:	IDGetCX(Slot,Nr,[NAME|TITLE|DESC|GUI|ACTIVE])
*
		clrfo
idgcx_List	fo.l	1			; ^List of slots
idgcx_Buffer	fo.b	20			; String buffer
idgcx_LENGTH	fo.w	0

ID_GetCX	 link	a4,#idgcx_LENGTH
	;-- evaluate slot
		move.l	(rm_Args+1*4,a5),d0	; Args[1]
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay
		tst.b	(a0)
		bne	.error
.numokay	cmp.l	#CXSLOTS,d0		; in range?
		bhs	.error			;   nope -> error
		mulu	#MLH_SIZE,d0
		lea	cxslots,a0
		add.l	d0,a0
		tst.l	(a0)			; allocated?
		beq	.error			;   nope -> error
		move.l	a0,(idgcx_List,a4)
	;-- evaluate node number
		move.l	(rm_Args+2*4,a5),d0	; Args[2]
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay2
		tst.b	(a0)
		bne	.error
.numokay2	move.l	(idgcx_List,a4),a0
.loop		move.l	(a0),a0
		tst.l	(a0)			; end of list?
		beq	.error			;   yes -> error
		subq.l	#1,d0
		bcc	.loop
		move.l	a0,a3
	;-- evaluate result type
		move.l	(rm_Args+3*4,a5),d0	; Args[3]
		beq	.error
		move.l	d0,a0
		lea	(.results,PC),a1
		bsr	strtoidx
		subq.l	#1,d0			; name?
		bcs	.name
		subq.l	#1,d0			; title?
		bcs	.title
		subq.l	#1,d0			; description?
		bcs	.desc
		subq.l	#1,d0			; shown?
		bcs	.shown
		subq.l	#1,d0			; active?
		bcs	.active
		bra	.error
	;-- name
.name		lea	(bc_Name,a3),a0
		bra	.result
	;-- title
.title		lea	(bc_Title,a3),a0
		bra	.result
	;-- description
.desc		lea	(bc_Descr,a3),a0
		bra	.result
	;-- shown
.shown		move	(bc_Flags,a3),d0
		and	#COF_SHOW_HIDE,d0
		beq	.false
		bra	.true
	;-- active
.active		move	(bc_Flags,a3),d0
		and	#COF_ACTIVE,d0
		beq	.false
		bra	.true
	;-- is TRUE
.true		lea	(.truestr,PC),a0
		bra	.result
	;-- is FALSE
.false		lea	(.falsestr,PC),a0
	;-- format result
.result		strln.b a0,d0
		subq.l	#1,d0
		rexxsys CreateArgstring
		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts

	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

	;-- result types
.results	dc.b	"NAME",0
		dc.b	"TITLE",0
		dc.b	"DESC",0
		dc.b	"GUI",0
		dc.b	"ACTIVE",0
		dc.b	0

.truestr	dc.b	"1",0
.falsestr	dc.b	"0",0
		even

**
* Unlock a commodity slot.
*
* ARexx:	IDUnlockCX(Slot)
*
		clrfo
iducx_LENGTH	fo.w	0

ID_UnlockCX	link	a4,#iducx_LENGTH
	;-- get slot number
		move.l	(rm_Args+1*4,a5),d0	; Args[1]
		beq	.error
		move.l	d0,a0
		bsr	strtonum
		cmp.b	#" ",(a0)
		beq	.numokay
		tst.b	(a0)
		bne	.error
	;-- calculate result
.numokay	cmp.l	#CXSLOTS,d0		; in range?
		bhs	.error			;   nope -> error
		mulu	#MLH_SIZE,d0
		lea	cxslots,a0
		add.l	d0,a0
		tst.l	(a0)			; allocated?
		beq	.error			;   nope -> error
		move.l	a0,a3
		cx	FreeBrokerList		; release
		clr.l	(a3)			; clear pointer, slot is empty
		sub.l	a0,a0			; no result string
		moveq	#0,d0
.exit		unlk	a4
		rts

	;-- error
.error		moveq	#12,d0
		sub.l	a0,a0
		bra	.exit

**
* Update identify database. All internal caches are flushed.
*
* ARexx:	IDUpdate()
*
ID_Update	idfy	IdHardwareUpdate
		sub.l	a0,a0
		moveq	#0,d0
		rts


*
* ======== Helper Functions ========
*

**
* Convert string to index.
*
*	-> A0.l ^String to be converted (until next space)
*	-> A1.l ^Table of possible values
*	<- D0.l Index in this table, or -1: not found
*	<- A0.l ^First char after found string.
*
strtoidx	movem.l d1-d2/a1-a2,-(SP)
		moveq	#-1,d0
		move.l	a0,a2			; remember string
	;-- outer loop: iterate through table
.nexttry	addq.l	#1,d0
		tst.b	(a1)			; end of table?
		beq	.not_found
		move.l	a2,a0
	;-- inner loop: compare characters
.cmploop	move.b	(a0)+,d2
		cmp.b	#'a',d2			; to uppercase
		blo.b	.updone
		cmp.b	#'z',d2
		bhi.b	.updone
		sub.b	#$20,d2
.updone		move.b	(a1)+,d1
		beq	.test_found
		cmp.b	d2,d1			; same character?
		beq	.cmploop
	;-- find next table record
.skip		tst.b	(a1)+			; find end of this record
		bne	.skip
		bra	.nexttry
	;-- possibly found a record
.test_found	subq.l	#1,a0			; set ptr to first character after text
		tst.b	d2			; check last character
		beq	.done			; 0 termination -> ok
		cmp.b	#' ',d2			; space char -> ok
		beq	.done
		cmp.b	#'=',d2			; equal char -> ok
		beq	.done
		bra	.nexttry		; otherwise check next table record
	;-- string not found
.not_found	moveq	#-1,d0
	;-- string found
.done		movem.l (SP)+,d1-d2/a1-a2
		rts

**
* Convert integer to string.
*
*	-> D0.l	Number to convert
*	-> A0.l ^Buffer (20 chars or more)
*	<- A0.l ^Converted number in this buffer
*	<- D0.l Length of converted number
*
numtostr	movem.l d1-d2,-(SP)
		tst.l	d0			; negative?
		smi	d2			; remember sign
		bpl	.nosign
		neg.l	d0			; and make positive
.nosign		add.l	#20,a0			; move to buffer end
		clr.b	-(a0)			; set terminator
		moveq	#0,d1			; compute single numbers
.numloop	divu	#10,d0
		swap	d0
		add.b	#'0',d0			; to ASCII
		move.b	d0,-(a0)
		addq.l	#1,d1
		clr	d0
		swap	d0			; continue with result of division
		bne	.numloop		; until value is zero
		tst.b	d2			; was it negative?
		beq	.notneg
		move.b	#'-',-(a0)		; then prepend a '-' sign
		addq.l	#1,d1
.notneg		move.l	d1,d0
		movem.l (SP)+,d1-d2
		rts

**
* Convert integer to hex string.
*
*	-> D0.l Number to convert
*	-> A0.l ^Buffer (20 chars or more)
*	<- A0.l ^Converted number in this buffer
*	<- D0.l Length of converted number
*
hextostr	movem.l a0/d1-d2,-(SP)
		lea	(.hextab,PC),a1
		moveq	#7,d1
.loop		rol.l	#4,d0
		move	d0,d2
		and	#$F,d2
		move.b	(a1,d2.w),(a0)+
		dbra	d1,.loop
		clr.b	(a0)
		moveq	#8,d0
		movem.l (SP)+,a0/d1-d2
		rts
.hextab		dc.b	"0123456789ABCDEF"
		even

**
* Convert string to integer.
*
*	-> A0.l	^Buffer to convert
*	<- A0.l ^Position after number in this buffer
*	<- D0.l Converted number
*
strtonum	movem.l d1-d3,-(SP)
		moveq	#0,d0			; collect result here
.space		cmp.b	#' ',(a0)+		; skip all spaces
		beq	.space
		subq.l	#1,a0
		cmp.b	#'-',(a0)		; negative sign?
		seq	d2			; remember that
		bne	.loop
		addq.l	#1,a0
.loop		moveq	#0,d1
		move.b	(a0)+,d1		; read next character
		sub.b	#'0',d1			; convert to int
		bcs	.convdone		; <'0' -> we're done
		cmp.b	#9,d1			; >'9' -> we're done
		bhi	.convdone
		add.l	d0,d0			; multiply by 10
		move.l	d0,d3
		add.l	d0,d0
		add.l	d0,d0
		add.l	d3,d0			; (x*8)+(x*2) = (x*10)
		add.l	d1,d0			; add decoded digit
		bra	.loop
.convdone	tst.b	d2			; negative?
		beq	.nomin
		neg.l	d0			; then negate the result
.nomin		subq.l	#1,a0			; position to first invalid char
		movem.l (SP)+,d1-d3
		rts

**
* Convert hex string to integer.
*
*	-> A0.l	^Buffer to convert
*	<- A0.l ^Position after number in this buffer
*	<- D0.l Converted number
*
strtohex	movem.l d1-d2,-(SP)
		moveq	#7,d1			; we expect 8 digits
		moveq	#0,d0			; result is collected here
.convert	move.b	(a0)+,d2		; read next character
		sub.b	#"0",d2			; convert to int
		bcs	.done			; <'0' -> we're done
		cmp.b	#9,d2			; <='9' -> just add it
		bls	.addit
		sub.b	#"A"-"9"-1,d2		; handle 'A' to 'F'
		bcs	.done			; <'A' -> we're done
		cmp.b	#$F,d2			; <='F' -> just add it
		bls	.addit
		sub.b	#"a"-"A",d2		; handle 'a' to 'f'
		bcs	.done			; <'a' -> we're done
		cmp.b	#$F,d2			; >'f' -> we're done
		bhi	.done
.addit		lsl.l	#4,d0			; *16
		or.b	d2,d0			; +decoded digit
		dbra	d1,.convert
		addq.l	#1,a0
.done		subq.l	#1,a0			; position at first invalid char
		movem.l (SP)+,d1-d2
		rts


*
* ======== Variables ========
*

identifybase	dc.l	0
expbase		dc.l	0
rexxsyslibbase	dc.l	0
cxbase		dc.l	0
expnumbers	dc.w	0		; number of expansions in this system

		SECTION Bss,BSS
expansions	ds.l	32		; All expansions
cxslots		ds.b	CXSLOTS*MLH_SIZE ; Slots for commodities

		SECTION text,CODE
		cnop	0,4
EndCode		ds.w	0
