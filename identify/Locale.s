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

ID_LOCALE       SET     -1
CATCOMP_NUMBERS SET     1                       ;Numbers haben wollen...
FAR             SET     1

		INCLUDE lvo/exec.i
		INCLUDE lvo/locale.i
		INCLUDE lvo/utility.i
		INCLUDE libraries/locale.i

		INCLUDE Refs.i

		IFD     _MAKE_68020
		MACHINE 68020
		ENDC

CATNAME         MACRO                   ;Name der Katalog-Datei
		dc.b    "identify.catalog",0
		ENDM

*---------------------------------------------------------------*
*       Los geht's                                              *
*                                                               *
		SECTION text,CODE

*-------------------------------------------------------*
* Name:         InitLocale                              *
*                                                       *
* Funktion:     Initialisiert die Locale-Features       *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  · Bei Fehlschlag (keine locale.library  *
*                 oder kein Katalog) werden automatisch *
*                 die eingebauten Strings verwendet     *
*>                                                      *
* Revision:     1.0 (19. März 1996, 23:10:37)           *
*                                                       *
		XDEF    InitLocale
InitLocale      movem.l d0-d3/a0-a3,-(sp)
	;-- Versuche, Lib zu öffnen ------------;
		lea     (localename,PC),a1      ;locale.library öffnen
		moveq   #38,d0
		exec    OpenLibrary
		move.l  d0,localebase
		beq     .nolocale               ;Locale nicht bekommen
	;-- Katalog öffnen ---------------------;
		sub.l   a0,a0                   ;Benutzer's lokal
		lea     (.locname,PC),a1        ;Name des Katalogs
		lea     (.nulltag,PC),a2        ;Keine Tags
		locale  OpenCatalogA            ;Catalog öffnen
		move.l  d0,MyCatalog            ;merken
	;-- Fertig -----------------------------;
.exit           movem.l (sp)+,d0-d3/a0-a3
		rts
	;-- Locale nicht da --------------------;
.nolocale       clr.l   MyCatalog               ; und kein Katalog
		bra     .exit
	;-- Ein paar Variablen -----------------;
.nulltag        dc.l    TAG_DONE                ;Kein Tag
.locname        CATNAME
		even
*<
*-------------------------------------------------------*
* Name:         ExitLocale                              *
*                                                       *
* Funktion:     Locale wieder freigeben                 *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  · Kann in jedem Fall aufgerufen werden  *
*>                                                      *
* Revision:     1.0 (19. März 1996, 23:10:49)           *
*                                                       *
		XDEF    ExitLocale
ExitLocale      movem.l d0-d3/a0-a3,-(sp)
		move.l  (localebase,PC),d0      ;Locale bekommen?
		beq     .nolib                  ; nein -> 'raus
	;-- Katalog schließen ------------------;
		move.l  (MyCatalog,PC),a0       ;Catalog holen
		locale  CloseCatalog            ;evtl. 0 ist erlaubt
	;-- Library schließen ------------------;
		move.l  (localebase,PC),a1      ;LibBase
		exec    CloseLibrary
	;-- Fertig -----------------------------;
.nolib          movem.l (sp)+,d0-d3/a0-a3
		rts
*<
*-------------------------------------------------------*
* Name:         GetLocString                            *
*                                                       *
* Funktion:     Einen String wandeln                    *
*                                                       *
* Parameter:    -» D0.l String-Nummer                   *
*               «- A0.l ^String (** READ ONLY **)       *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  · Wenn String nicht existiert, wird ein *
*                 "-?-" zurückgegeben...                *
*>                                                      *
* Revision:     1.0 (19. März 1996, 23:11:50)           *
*                                                       *
		XDEF    GetLocString
GetLocString    move.l  d1,-(SP)
		st      d1
		bsr     GetNewLocString
		move.l  (SP)+,d1
		rts
*<
*-------------------------------------------------------*
* Name:         GetNewLocString                         *
*                                                       *
* Funktion:     Einen String wandeln (optional)         *
*                                                       *
* Parameter:    -» d0.l String-Nummer                   *
*               -» d1.b 0:builtin ~0:locale             *
*               «- A0.l ^String (** READ ONLY **)       *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  · Wenn String nicht existiert, wird ein *
*                 "-?-" zurückgegeben...                *
*>                                                      *
* Revision:     1.0 (19. März 1996, 23:11:50)           *
*                                                       *
		XDEF    GetNewLocString
GetNewLocString movem.l d0-d3/a1-a3,-(SP)
	;-- ^Default-String holen --------------;
		lea     CatCompBlock,a1         ;String-Tabelle
.check          move.l  (a1)+,d2                ;String holen
		bmi     .notfound
		cmp.l   d0,d2                   ;Richtige ID?
		beq     .strfound
		adda.w  (a1)+,a1                ;nächste ID
		bra     .check
.strfound       addq.l  #2,a1                   ;String holen
	;-- Ist die Library offen? -------------;
.insert         tst.b   d1                      ;Wandeln?
		beq     .nolocale               ; nope
		move.l  (localebase,PC),d1      ;Base da?
		beq     .nolocale
	;-- Library benutzen -------------------;
		move.l  (MyCatalog,PC),a0       ;^Catalog holen
		locale  GetCatalogStr           ;String holen
		move.l  d0,a0                   ;Ergebnis zurück
	;-- Ende -------------------------------;
.exit   movem.l (sp)+,d0-d3/a1-a3
		rts
	;-- Library fehlt ----------------------;
.nolocale       move.l  a1,a0                   ;Defaultstring ist Ergebnis
		bra     .exit
	;-- String nicht da --------------------;
.notfound       lea     (.errstring,PC),a1      ;^ErrorString
		bra     .insert
	;-- Variablen --------------------------;
.errstring      dc.b    "-?-",0                 ;Sollte NIEMALS auftauchen
		even
*<

*---------------------------------------------------------------*
*       == VARIABLEN ==                                         *
*                                                               *
MyCatalog       dc.l    0                       ;^Catalog-Struktur
localebase      dc.l    0                       ;^Local-Base
localename      dc.b    "locale.library",0      ;Locale-Name
		even

		SECTION strings,DATA
	;-- Die Texte etc. folgen --------------;
CATCOMP_BLOCK   SET     1                       ;Block definieren
		INCLUDE Locale.i                ;Locale-Defs nachladen
		dc.l    -1                      ;Endmarke
		even

*---------------------------------------------------------------*
*       == Ende ==                                              *
*                                                               *
		END
