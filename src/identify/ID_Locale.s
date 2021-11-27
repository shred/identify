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

		INCLUDE lvo/exec.i
		INCLUDE lvo/locale.i
		INCLUDE lvo/utility.i
		INCLUDE libraries/locale.i

		IFD	_MAKE_68020
		  MACHINE 68020
		ENDC

		SECTION text,CODE

**
* Initialize the Locale module.
*
* If there is an error, a local copy of the English strings is used as a fallback.
*
		public	InitLocale
InitLocale	movem.l d0-d3/a0-a3,-(sp)
	;-- open locale.library
		lea	(localename,PC),a1
		moveq	#38,d0
		exec	OpenLibrary
		move.l	d0,localebase
		beq	.nolocale
	;-- open catalog
		sub.l	a0,a0
		lea	(.locname,PC),a1
		lea	(.nulltag,PC),a2
		locale	OpenCatalogA
		move.l	d0,MyCatalog
	;-- done
.exit		movem.l (sp)+,d0-d3/a0-a3
		rts

	;-- no locale.library
.nolocale	clr.l	MyCatalog
		bra	.exit

.nulltag	dc.l	TAG_DONE
.locname	dc.b	"identify.catalog",0
		even


**
* Exit Locale module.
*
* Safe to invoke even if initialization has failed.
*
		public	ExitLocale
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
* Translate a string.
*
* If there is no string with that resource number, "-?-" is returned instead.
*
*	-> D0.l	String resource number
*	<- A0.l	^String (READ ONLY!)
*
		public	GetLocString
GetLocString	move.l	d1,-(SP)
		st	d1
		bsr	GetNewLocString
		move.l	(SP)+,d1
		rts


**
* Translate a string, either from the catalog or a local English fallback.
*
* If there is no string with that resource number, "-?-" is returned instead.
*
*	-> D0.l	String resource number
*	-> D1.b	0: local fallback, ~0: catalog
*	<- A0.l	^String (READ ONLY!)
*
		public	GetNewLocString
GetNewLocString movem.l d0-d3/a1-a3,-(SP)
	;-- get default string
		lea	CatCompBlock,a1		; table of string definitions
.check		move.l	(a1)+,d2
		bmi	.notfound
		cmp.l	d0,d2			; wanted ID?
		beq	.strfound
		adda.w	(a1)+,a1		; no, skip to next definition
		bra	.check
.strfound	addq.l	#2,a1
	;-- is library present?
.insert		tst.b	d1
		beq	.nolocale
		move.l	(localebase,PC),d1
		beq	.nolocale
	;-- try to translate via library
		move.l	(MyCatalog,PC),a0
		locale	GetCatalogStr
		move.l	d0,a0
	;-- done
.exit		movem.l (sp)+,d0-d3/a1-a3
		rts

	;-- no library
.nolocale	move.l	a1,a0			; use fallback string
		bra	.exit

	;-- no string definition
.notfound	lea	(.errstring,PC),a1	; return error string
		bra	.insert
.errstring	dc.b	"-?-",0
		even



MyCatalog	dc.l	0
localebase	dc.l	0
localename	dc.b	"locale.library",0
		even


		SECTION strings,DATA
CATCOMP_BLOCK	SET	1			; generate the string table
		INCLUDE ID_Locale.i
		dc.l	-1			; end marker
