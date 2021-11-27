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

*
* This is a replacement for the former expname.library. It delegates all
* calls to the identify.library.
*
* The expname.library is deprecated. Do not use it in new code.
*

		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/initializers.i
		INCLUDE exec/resident.i
		INCLUDE exec/execbase.i
		INCLUDE exec/memory.i
		INCLUDE utility/tagitem.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/identify.i

		INCLUDE libraries/identify.i

		INCLUDE EX_Base.i

		SECTION text,CODE

VERSION		EQU	02		;<- Version
REVISION	EQU	101		;<- Revision

SETVER		MACRO			;<- Version String Macro
		dc.b	"2.101"
		ENDM

SETDATE		MACRO			;<- Date String Macro
		dc.b	"20.11.2021"
		ENDM

**
* Initialize library
*
Start		moveq	#0,d0
		rts

**
* Describe library
*								*
InitDDescrip	dc.w	RTC_MATCHWORD
		dc.l	InitDDescrip
		dc.l	EndCode
		dc.b	RTF_AUTOINIT,VERSION,NT_LIBRARY,0
		dc.l	libname,libidstring,Init
libname		dc.b	"expname.library",0
libidstring	dc.b	"expname.library "
		SETVER
		dc.b	" ("
		SETDATE
		dc.b	")",13,10,0

**
* Copyright note for hex reader
*
		dc.b	"Replacement for the old expname.library. Do not use in new code! ",$a
		dc.b	"(C) 1996-2021 Richard 'Shred' K\xF6rber ",$a
		dc.b	"License: GNU Lesser General Public License v3 ",$a
		dc.b	"Source: https://identify.shredzone.org",0
		even
		cnop	0,4

**
* Init table
*								*
Init		dc.l	idb_SIZEOF,FuncTab,DataTab,InitFct

**
* Function table. Keep this order, only append!
*								*
FuncTab		dc.l	LOpen,LClose,LExpunge,LNull	;Standard
		dc.l	GetExpName			;-30
		dc.l	GetSysInfo			;-36
		dc.l	-1

**
* Data table
*								*
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
		lea	(.identifyname,PC),a1	;identify aufmachen
		moveq	#1,d0
		exec	OpenLibrary
		move.l	d0,identifybase
		beq	.error1
	;-- done
		move.l	a5,d0
.exit		movem.l (sp)+,d1-d7/a0-a6
		rts
	;-- error
.error1		moveq	#0,d0
		bra	.exit

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
* Get the name of an expansion.
*
*	-> A0.l ^Target buffer for manufacturer name
*	-> A1.l ^Target buffer for product nane
*	-> A2.l ^ConfigDev or NULL
*	-> D0.w	Manufacturer ID
*	-> D1.b Product ID
*	<- D0.l 0:Success, ~0:Error
*
GetExpName	movem.l d1-d3/a0-a6,-(sp)
		move.l	sp,a5
	;-- buffer space for board class
		sub.l	#50,sp
		move.l	sp,a3
	;-- set string buffers to tag list
		pea	TAG_DONE.w
		move.l	a3,-(sp)
		pea	IDTAG_ClassStr
		move.l	a1,-(sp)
		pea	IDTAG_ProdStr
		move.l	a0,-(sp)
		pea	IDTAG_ManufStr
	;-- do we have a ConfigDev?
		move.l	a2,d2
		beq	.nocd
		move.l	a2,-(sp)
		pea	IDTAG_ConfigDev
		bra	.start
	;-- use manufacturer and prod instead
.nocd		move.l	d0,-(sp)
		pea	IDTAG_ManufID
		move.l	d1,-(sp)
		pea	IDTAG_ProdID
	;-- invoke identify
.start		move.l	sp,a0
		idfy	IdExpansion
		not.l	d0
	;-- concatenate
		move.l	a1,d1
		beq	.noprod
		moveq	#48,d1			; 49 chars max
.findstr	subq.l	#1,d1
		tst.b	(a1)+
		bne	.findstr
		move.b	#" ",(-1,a1)
.copystr	move.b	(a3)+,(a1)+
		dbeq	d1,.copystr
		clr.b	-(a1)
	;-- done
.noprod		move.l	a5,sp
		movem.l (sp)+,d1-d3/a0-a6
		rts

**
* Get a system string.
*
*	-> A0.l ^Buffer for string (50 chars)
*	-> D0.l Desired string type
*	-> D1.l Reserved, must be 0
*	<- D0.l String or NULL: unknown/not present
*
GetSysInfo	movem.l d1-d7/a0-a6,-(sp)
		move.l	a0,a4
		move.l	a0,d7
		sub.l	a0,a0
		idfy	IdHardware
		tst.l	d0
		beq	.done
		move.l	d0,a0
		moveq	#48,d1
.copystr	move.b	(a0)+,(a4)+
		dbeq	d1,.copystr
		clr.b	-(a4)
.done		move.l	d7,d0
		movem.l (sp)+,d1-d7/a0-a6
		rts


*
* ======== Variables ========
*
identifybase	dc.l	0

		cnop	0,4
EndCode		ds.w	0
