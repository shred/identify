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

		INCLUDE exec/ports.i		;C= includes
		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i
		INCLUDE dos/dos.i
		INCLUDE dos/rdargs.i
		INCLUDE utility/tagitem.i
		INCLUDE libraries/identify.i
		INCLUDE libraries/locale.i
		INCLUDE lvo/exec.i		;LVOs
		INCLUDE lvo/dos.i
		INCLUDE lvo/identify.i
		INCLUDE lvo/locale.i

VERSION		MACRO
		  dc.b	"1.2"
		ENDM
DATE		MACRO
		  dc.b	"27.12.1999"
		ENDM

		SECTION text,CODE

		SECTION strings,DATA
CATCOMP_NUMBERS SET	1
CATCOMP_BLOCK	SET	1			;Block definieren
CATCOMP_FUNC	SET	1
		INCLUDE LocaleTools.i		;Locale-Defs nachladen
		dc.l	-1			;Endmarke

		SECTION text,CODE

*---------------------------------------------------------------*
*       == Function ==                                          *
*                                                               *
*-------------------------------------------------------*
* Name:		Start					*
*							*
* Funktion:	Statet das Tool				*
*							*
* Parameter:						*
* Register:	keine Änderungen			*
*>							*
* Revision:	1.0 (19. März 1996, 23:10:37)		*
*							*
Start	;-- DOS-Lib öffnen ---------------------;
		lea	(dosname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,dosbase
		beq	.error1
		bsr	InitLocale
	;-- Parameter einlesen -----------------;
		lea	(template,PC),a0	;Parsen
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
		pea	(email,PC)
		pea	(versionstr,PC)
		move.l	SP,d2
		dos	VPrintf
		addq.l	#2*4,SP
		move.l	#MSG_FUNC_HELP,d0
		bsr	GetLocString
		move.l	a0,d1
		dos	PutStr
		bra	.error2
	;-- Identify-Library öffnen ------------;
.parseok	move.l	#MSG_FUNC_HAIL,d0	;Hail-Msg
		bsr	GetLocString
		move.l	a0,d1
		pea	(email,PC)
		pea	(versionstr,PC)
		move.l	SP,d2
		dos	VPrintf
		addq.l	#2*4,SP
		lea	(identifyname,PC),a1	;Lib öffnen
		moveq	#4,d0			;  auch unten ändern
		exec	OpenLibrary
		move.l	d0,identifybase
		bne	.gotid
		move.l	#MSG_NOIDENTIFY,d0
		bsr	GetLocString
		move.l	a0,d1
		pea	4.w			;<<--- HIER
		move.l	SP,d2
		dos	VPrintf
		addq.l	#4,SP
		bra	.error3
	;-- Code wandeln -----------------------;
.gotid		move.l	(ArgList+arg_Name,PC),a0
		move.l	(ArgList+arg_Offset,PC),a1
		move.l	(a1),d0			;auf jeden Fall da!
	;-- Fn-Msg erzeugen --------------------;
		move.l	sp,d7
		pea	TAG_DONE.w
		pea	(buf_fnname,PC)
		pea	IDTAG_FuncNameStr
		move.l	sp,a1
		move.l	(identifybase,PC),a6
		jsr	(-48,a6)
		move.l	d7,sp
	;-- Ausgeben ---------------------------;
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
	;-- Fertig -----------------------------;
.done		move.l	(identifybase,PC),a1	;Identify freigeben
		exec	CloseLibrary
		move.l	(args,PC),d1		;Result freigeben
		dos	FreeArgs
		exec	CloseLibrary
		moveq	#0,d0			;Alles OK
.exit		bsr	ExitLocale
		rts
	;-- Fehler -----------------------------;
.error4		move.l	(identifybase,PC),a1	;Identify freigeben
		exec	CloseLibrary
.error3		move.l	(args,PC),d1		;Result freigeben
		dos	FreeArgs
.error2		move.l	(dosbase,PC),a1		;DOS freigeben
		exec	CloseLibrary
.error1		moveq	#10,d0			;Schlug fehl
		bra.b	.exit
*<
*-------------------------------------------------------*
* Name:		InitLocale				*
*							*
* Funktion:	Initialisiert die Locale-Features	*
*							*
* Parameter:						*
* Register:	keine Änderungen			*
*							*
* Bemerkungen:	· Bei Fehlschlag (keine locale.library	*
*		  oder kein Katalog) werden automatisch *
*		  die eingebauten Strings verwendet	*
*>							*
* Revision:	1.0 (19. März 1996, 23:10:37)		*
*							*
InitLocale	movem.l d0-d3/a0-a3,-(sp)
	;-- Versuche, Lib zu öffnen ------------;
		lea	(.localename,PC),a1	;locale.library öffnen
		moveq	#38,d0
		exec	OpenLibrary
		move.l	d0,localebase
		beq	.nolocale		;Locale nicht bekommen
	;-- Katalog öffnen ---------------------;
		sub.l	a0,a0			;Benutzer's lokal
		lea	(.locname,PC),a1	;Name des Katalogs
		lea	(.nulltag,PC),a2	;Keine Tags
		locale	OpenCatalogA		;Catalog öffnen
		move.l	d0,MyCatalog		;merken
	;-- Fertig -----------------------------;
.exit		movem.l (sp)+,d0-d3/a0-a3
		rts
	;-- Locale nicht da --------------------;
.nolocale	clr.l	MyCatalog		; und kein Katalog
		bra	.exit
	;-- Ein paar Variablen -----------------;
.nulltag	dc.l	TAG_DONE		;Kein Tag
.localename	dc.b	"locale.library",0	;Locale-Name
.locname	dc.b	"identifytools.catalog",0 ;Katalog-Name
		even
*<
*-------------------------------------------------------*
* Name:		ExitLocale				*
*							*
* Funktion:	Locale wieder freigeben			*
*							*
* Parameter:						*
* Register:	keine Änderungen			*
*							*
* Bemerkungen:	· Kann in jedem Fall aufgerufen werden	*
*>							*
* Revision:	1.0 (19. März 1996, 23:10:49)		*
*							*
ExitLocale	movem.l d0-d3/a0-a3,-(sp)
		move.l	(localebase,PC),d0	;Locale bekommen?
		beq	.nolib			; nein -> 'raus
	;-- Katalog schließen ------------------;
		move.l	(MyCatalog,PC),a0	;Catalog holen
		locale	CloseCatalog		;evtl. 0 ist erlaubt
	;-- Library schließen ------------------;
		move.l	(localebase,PC),a1	;LibBase
		exec	CloseLibrary
	;-- Fertig -----------------------------;
.nolib		movem.l (sp)+,d0-d3/a0-a3
		rts
*<
*-------------------------------------------------------*
* Name:		GetLocString				*
*							*
* Funktion:	Einen String wandeln			*
*							*
* Parameter:	-» D0.l String-Nummer			*
*		«- A0.l ^String (** READ ONLY **)	*
* Register:	keine Änderungen			*
*							*
* Bemerkungen:	· Wenn String nicht existiert, wird ein *
*		  "-?-" zurückgegeben...		*
*>							*
* Revision:	1.0 (19. März 1996, 23:11:50)		*
*							*
GetLocString	movem.l d0-d3/a1-a3,-(sp)
	;-- ^Default-String holen --------------;
		lea	CatCompBlock,a1		;String-Tabelle
.check		move.l	(a1)+,d1		;String holen
		bmi	.notfound
		cmp.l	d0,d1			;Richtige ID?
		beq	.strfound
		adda.w	(a1)+,a1		;nächste ID
		bra	.check
.strfound	addq.l	#2,a1			;String holen
	;-- Ist die Library offen? -------------;
.insert		move.l	(localebase,PC),d1	;Base da?
		beq	.nolocale
	;-- Library benutzen -------------------;
		move.l	(MyCatalog,PC),a0	;^Catalog holen
		locale	GetCatalogStr		;String holen
		move.l	d0,a0			;Ergebnis zurück
	;-- Ende -------------------------------;
.exit	movem.l (sp)+,d0-d3/a1-a3
		rts
	;-- Library fehlt ----------------------;
.nolocale	move.l	a1,a0			;Defaultstring ist Ergebnis
		bra	.exit
	;-- String nicht da --------------------;
.notfound	lea	(.errstring,PC),a1	;^ErrorString
		bra	.insert
	;-- Variablen --------------------------;
.errstring	dc.b	"-?-",0			;Sollte NIEMALS auftauchen
		even
*<

*---------------------------------------------------------------*
*	== VARIABLEN ==						*
*								*
version		dc.b	0,"$VER: Function V"	    ;Versions-String
		VERSION
		dc.b	" ("
		DATE
		dc.b	")",$d,$a,0
		even

	;-- Variablen --------------------------;
dosbase		dc.l	0			;^DOS-Library
identifybase	dc.l	0			;^Identify Library
localebase	dc.l	0			;^Local-Base
MyCatalog	dc.l	0			;^Catalog-Struktur
args		dc.l	0			;^Ergebnis von Parse

	;-- Argumente --------------------------;
		rsreset
arg_Name	rs.l	1			;Lib-Name
arg_Offset	rs.l	1			;Offset
arg_SIZEOF	rs.w	0

ArgList		ds.b	arg_SIZEOF		;Parameter-Array
template	dc.b	"LN=LIBNAME/A,O=OFFSET/N/A",0

email		dc.b	"rkoerber@gmx.de",0
versionstr	VERSION
		dc.b	0

buf_fnname	ds.b	50			;Puffer

	;-- Strings ----------------------------;
dosname		dc.b	"dos.library",0		;DOS-Lib
identifyname	dc.b	"identify.library",0
		even

*---------------------------------------------------------------*
*	== ENDE DES SOURCES ==					*
*								*
		END
