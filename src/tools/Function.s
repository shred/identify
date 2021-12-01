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
		INCLUDE lvo/exec.i
		INCLUDE lvo/dos.i
		INCLUDE lvo/identify.i
		INCLUDE lvo/locale.i

VERSION		MACRO
		  dc.b	"1.3"
		ENDM
DATE		MACRO
		  dc.b	"30.11.2021"
		ENDM

		SECTION strings,DATA
CATCOMP_BLOCK	SET	1			;Block definieren
		INCLUDE LocaleTools.i		;Locale-Defs nachladen
		dc.l	-1			;Endmarke

IDENTIFY_VER	EQU	4

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
		move.l	#MSG_FUNC_HAIL,d0
		bsr	GetLocString
		move.l	a0,d1
		pea	(url,PC)
		pea	(versionstr,PC)
		move.l	SP,d2
		dos	VPrintf
		addq.l	#2*4,SP
		move.l	#MSG_FUNC_HELP,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
		bra	.error2
	;-- open identify
.parseok	move.l	#MSG_FUNC_HAIL,d0
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
.gotid		move.l	(ArgList+arg_Name,PC),a0
		move.l	(ArgList+arg_Offset,PC),a1
		move.l	(a1),d0
	;-- create Fn-Msg
		move.l	sp,d7
		pea	TAG_DONE.w
		pea	(buf_fnname,PC)
		pea	IDTAG_FuncNameStr
		move.l	sp,a1
		move.l	(identifybase,PC),a6
		jsr	(-48,a6)
		move.l	d7,sp
	;-- output
		pea	(buf_fnname,PC)
		move.l	(ArgList+arg_Offset,PC),a0
		move.l	(a0),d0
		bmi	.isneg
		neg.l	d0
.isneg		move.l	d0,-(sp)
		move.l	(ArgList+arg_Name,PC),-(sp)
		move.l	sp,a0
		move.l	a0,d2
		move.l	#MSG_FUNC_RESULT,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	VPrintf
		move.l	d7,sp
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
version		dc.b	0,"$VER: Function V"
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
arg_Name	rs.l	1
arg_Offset	rs.l	1
arg_SIZEOF	rs.w	0

ArgList		ds.b	arg_SIZEOF
template	dc.b	"LN=LIBNAME/A,O=OFFSET/N/A",0

url		dc.b	"https://identify.shredzone.org",0
versionstr	VERSION
		dc.b	0

buf_fnname	ds.b	50

dosname		dc.b	"dos.library",0
identifyname	dc.b	"identify.library",0
		even
