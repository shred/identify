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
		INCLUDE libraries/locale.i
		INCLUDE lvo/exec.i		s
		INCLUDE lvo/dos.i
		INCLUDE lvo/identify.i
		INCLUDE lvo/locale.i

VERSION		MACRO
		  dc.b	"1.7"
		ENDM
DATE		MACRO
		  dc.b	"11.11.2022"
		ENDM

		SECTION strings,DATA
CATCOMP_BLOCK	SET	1
		INCLUDE LocaleTools.i
		dc.l	-1

IDENTIFY_VER	EQU	6

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
		move.l	#MSG_GURU_HAIL,d0
		bsr	GetLocString
		move.l	a0,d1
		pea	(url,PC)
		pea	(versionstr,PC)
		move.l	SP,d2
		dos	VPrintf
		addq.l	#2*4,SP
		move.l	#MSG_GURU_HELP,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
		bra	.error2
	;-- open identify
.parseok	move.l	#MSG_GURU_HAIL,d0
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
	;-- convert code
.gotid		move.l	(ArgList+arg_LastAlert,PC),d0
		beq	.notlast
		move.l	#IDHW_LASTALERT,d0
		sub.l	a0,a0
		idfy	IdHardwareNum
		cmp.l	#-1,d0
		bne	.getguru
		move.l	#MSG_GURU_NOLAST,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
		bra	.done
.notlast	move.l	(ArgList+arg_Guru,PC),d0
		beq	.bad
		move.l	d0,a0
		moveq	#7,d1
		moveq	#0,d0
.convert	move.b	(a0)+,d2
		sub.b	#"0",d2
		bcs	.bad
		cmp.b	#9,d2
		bls	.addit
		sub.b	#"A"-"9"-1,d2
		bcs	.bad
		cmp.b	#$F,d2
		bls	.addit
		sub.b	#"a"-"A",d2
		bcs	.bad
		cmp.b	#$F,d2
		bhi	.bad
.addit		lsl.l	#4,d0
		or.b	d2,d0
		dbra	d1,.convert
		tst.b	(a0)
		beq	.getguru
.bad		move.l	#MSG_GURU_BADCODE,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
		bra	.error4
	;-- generate Guru message
.getguru	move.l	sp,d7
		pea	TAG_DONE.w
		pea	100.w
		pea	IDTAG_StrLength
		pea	(buf_dead,PC)
		pea	IDTAG_DeadStr
		pea	(buf_subsys,PC)
		pea	IDTAG_SubsysStr
		pea	(buf_general,PC)
		pea	IDTAG_GeneralStr
		pea	(buf_spec,PC)
		pea	IDTAG_SpecStr
		move.l	sp,a0
		move.l	(identifybase,PC),a6
		move.l	d0,d6
		jsr	(-42,a6)
		move.l	d7,sp
	;-- output
		pea	(buf_spec,PC)
		pea	(buf_general,PC)
		pea	(buf_subsys,PC)
		pea	(buf_dead,PC)
		move.l	d6,-(SP)
		move.l	sp,a0
		move.l	a0,d2
		move.l	#MSG_GURU_RESULT,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	VPrintf
		move.l	d7,sp
	;-- done
.done		move.l	(identifybase,PC),a1
		exec	CloseLibrary
		move.l	(args,PC),d1
		dos	FreeArgs
		move.l	(dosbase,PC),a1
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
version		dc.b	0,"$VER: Guru V"	;Versions-String
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
arg_Guru	rs.l	1
arg_LastAlert	rs.l	1
arg_SIZEOF	rs.w	0

ArgList		ds.b	arg_SIZEOF
template	dc.b	"GURU,L=LASTALERT/S",0

url		dc.b	"https://identify.shredzone.org",0
versionstr	VERSION
		dc.b	0

buf_dead	ds.b	100
buf_subsys	ds.b	100
buf_general	ds.b	100
buf_spec	ds.b	100

dosname		dc.b	"dos.library",0
identifyname	dc.b	"identify.library",0
		even
