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

		INCLUDE exec/ports.i            ;C= includes
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
		INCLUDE lvo/exec.i                  ;LVOs
		INCLUDE lvo/dos.i
		INCLUDE lvo/identify.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/commodities.i
		INCLUDE lvo/locale.i

VERSION         MACRO
		  dc.b  "13.1"
		ENDM
DATE            MACRO
		  dc.b  "15.03.2010"
		ENDM

		SECTION text,CODE

		SECTION strings,DATA
CATCOMP_NUMBERS SET     1
CATCOMP_BLOCK   SET     1                       ;Block definieren
CATCOMP_LISTEXP SET     1
		INCLUDE LocaleTools.i           ;Locale-Defs nachladen
		dc.l    -1                      ;Endmarke

		SECTION text,CODE

*---------------------------------------------------------------*
*       == ListExp ==                                           *
*                                                               *
*-------------------------------------------------------*
*       Start   Startet ListExp                         *
*               -» A0.l ^Parameter                      *
*               -» D0.l Parameter-Länge                 *
*               «- D0.l Result                          *
*                                                       *
*>
Start   ;-- DOS-Lib öffnen ---------------------;
		lea     (dosname,PC),a1
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,dosbase
		beq     .error1
		bsr     InitLocale
	;-- Parameter einlesen -----------------;
		lea     (template,PC),a0        ;Parsen
		move.l  a0,d1
		lea     (ArgList,PC),a0
		move.l  a0,d2
		moveq   #0,d3
		dos     ReadArgs
		move.l  d0,args
		bne     .parseok
		move.l  #MSG_LISTEXP_HAIL,d0
		bsr     GetLocString
		move.l  a0,d1
		pea     (email,PC)
		pea     (versionstr,PC)
		move.l  SP,d2
		dos     VPrintf
		addq.l  #2*4,SP
		move.l  #MSG_LISTEXP_HELP,d0       ;Hilfe anzeigen
		bsr     GetLocString
		move.l  a0,d1
		dos     PutStr
		bra     .error2
	;-- Identify-Library öffnen ------------;
.parseok        move.l  #MSG_LISTEXP_HAIL,d0    ;Hail
		bsr     GetLocString
		move.l  a0,d1
		pea     (email,PC)
		pea     (versionstr,PC)
		move.l  SP,d2
		dos     VPrintf
		addq.l  #2*4,SP
		lea     (identifyname,PC),a1    ;Lib öffnen
		moveq   #13,d0                   ;Auch unten ändern
		exec    OpenLibrary
		move.l  d0,identifybase
		bne     .gotid
		move.l  #MSG_NOIDENTIFY,d0
		bsr     GetLocString
		move.l  a0,d1
		pea     13.w                     ;<---- HIER
		move.l  SP,d2
		dos     VPrintf
		addq.l  #4,SP
		bra     .error3
	;-- Los geht's -------------------------;
.gotid          move.l  (ArgList+arg_Update,PC),d0 ;Update?
		beq     .noupdate
		idfy    IdHardwareUpdate
		bra     .done
.noupdate       move.l  (ArgList+arg_Manuf,PC),d0 ;Manuf-ID eingegeben
		beq     .nospec
		move.l  d0,a0
		move.l  (a0),d0                 ;Manuf-ID
		move.l  (ArgList+arg_Prod,PC),d1  ;Prod-ID eingeben
		beq     .nospec
		move.l  d1,a0
		move.l  (a0),d1
		bsr     Specific                ;Spezielle ID gewünscht
		tst.l   d0                      ;okay?
		bne     .error4
		bra     .done
.nospec         bsr     HardList
		bsr     ExpList
		move.l  (ArgList+arg_Full,PC),d0 ;Auch Commodities
		beq     .nocx
		bsr     CdityList
.nocx           lea     (msg_newline,PC),a0
		move.l  a0,d1
		dos     PutStr
	;-- Fertig -----------------------------;
.done           move.l  (identifybase,PC),a1    ;Identify freigeben
		exec    CloseLibrary
		move.l  (args,PC),d1            ;Result freigeben
		dos     FreeArgs
		exec    CloseLibrary
		moveq   #0,d0                   ;Alles OK
.exit           bsr     ExitLocale
		rts
	;-- Fehler -----------------------------;
.error4         move.l  (identifybase,PC),a1    ;Identify freigeben
		exec    CloseLibrary
.error3         move.l  (args,PC),d1            ;Result freigeben
		dos     FreeArgs
.error2         move.l  (dosbase,PC),a1         ;DOS freigeben
		exec    CloseLibrary
.error1         moveq   #10,d0                  ;Schlug fehl
		bra.b   .exit
*<

*-------------------------------------------------------*
* Name:         Specific                                *
*                                                       *
* Funktion:     Spezifische Board-Anfrage               *
*                                                       *
* Parameter:    -» D0.l Manuf-ID                        *
*               -» D1.l Prod-ID                         *
*               «- D0.l Fehler (-1:Ja 0:Nein)           *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 6. Juni 1996, 18:38:10)           *
*                                                       *
Specific        move.l  sp,d7
		cmp.l   #65535,d0               ;max. 65535!
		bhi     .overflow
		cmp.l   #255,d1                 ;max. 255!
		bhi     .overflow
	;-- Stack aufbauen ---------------------;
		pea     TAG_DONE.w
		pea     (buf_class,PC)
		pea     IDTAG_ClassStr
		pea     (buf_prod,PC)
		pea     IDTAG_ProdStr
		pea     (buf_manuf,PC)
		pea     IDTAG_ManufStr
		move.l  d1,-(sp)
		pea     IDTAG_ProdID
		move.l  d0,-(sp)
		pea     IDTAG_ManufID
		move.l  sp,a0
		idfy    IdExpansion
		move.l  d7,sp
	;-- Ausgeben ---------------------------;
		pea     (buf_class,PC)
		pea     (buf_prod,PC)
		pea     (buf_manuf,PC)
		move.l  sp,d2
		move.l  #MSG_LISTEXP_SPECBOARD,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     VPrintf
		move.l  d7,sp
	;-- Fertig -----------------------------;
		moveq   #0,d0
		rts
	;-- Fehler -----------------------------;
.overflow       move.l  #MSG_LISTEXP_OVERFLOW,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     PutStr
.error          moveq   #-1,d0
		rts
*<
*-------------------------------------------------------*
* Name:         HardList                                *
*                                                       *
* Funktion:     Hardware                                *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 6. Juni 1996, 18:49:53)           *
*                                                       *
HardList        move.l  sp,d7                   ;Stack merken
	;-- Erste Line -------------------------;
		sub.l   a0,a0                   ;A0 stets leer
		lea     (.idtab1,PC),a1
.putloop1       move.l  (a1)+,d0
		bmi     .loopdone1
		idfy    IdHardware
		move.l  d0,-(sp)
		bra     .putloop1
.loopdone1      move.l  SP,d2
		move.l  #MSG_LISTEXP_HARDWARE,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     VPrintf
		move.l  d7,sp                   ;Stack restaurieren
	;-- PowerPC Line -----------------------;
		moveq   #IDHW_POWERPC,d0
		sub.l   a0,a0
		idfy    IdHardwareNum
		tst.l   d0
		beq     .noppc
		sub.l   a0,a0                   ;A0 stets leer
		lea     (.idtab2,PC),a1
.putloop2       move.l  (a1)+,d0
		bmi     .loopdone2
		idfy    IdHardware
		move.l  d0,-(sp)
		bra     .putloop2
.loopdone2      move.l  SP,d2
		move.l  #MSG_LISTEXP_POWERPC,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     VPrintf
		move.l  d7,sp                   ;Stack restaurieren
	;-- Dritte Linie -----------------------;
.noppc          moveq   #IDHW_EMULATED,d0
		sub.l   a0,a0
		idfy    IdHardwareNum
		tst.l   d0
		beq     .noemul
		sub.l   a0,a0                   ;A0 stets leer
		lea     (.idtab3,PC),a1
.putloop3       move.l  (a1)+,d0
		bmi     .loopdone3
		idfy    IdHardware
		move.l  d0,-(sp)
		bra     .putloop3
.loopdone3      move.l  SP,d2
		move.l  #MSG_LISTEXP_EMULATED,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     VPrintf
		move.l  d7,sp                   ;Stack restaurieren
	;-- Vierte Line ------------------------;
.noemul         sub.l   a0,a0                   ;a0 stets leer
		lea     (.idtab4,PC),a1
.putloop4       move.l  (a1)+,d0
		bmi     .loopdone4
		idfy    IdHardware
		move.l  d0,-(sp)
		bra     .putloop4
.loopdone4      move.l  SP,d2
		move.l  #MSG_LISTEXP_HARDWARE2,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     VPrintf
		move.l  d7,sp                   ;Stack restaurieren
		rts
	;-- Tabelle ----------------------------;
.idtab4         dc.l    IDHW_RAM,IDHW_FASTRAM,IDHW_CHIPRAM
		dc.l    IDHW_VMMRAM,IDHW_VMMFASTRAM,IDHW_VMMCHIPRAM
		dc.l    IDHW_PLNRAM,IDHW_PLNFASTRAM,IDHW_PLNCHIPRAM
		dc.l    IDHW_SLOWRAM,IDHW_ROMSIZE,IDHW_RAMBANDWIDTH
		dc.l    IDHW_RAMCAS,IDHW_RAMACCESS,IDHW_RAMWIDTH
		dc.l    IDHW_ECLOCK,IDHW_VBLANKFREQ,IDHW_POWERFREQ
		dc.l    IDHW_TCPIP,IDHW_AUDIOSYS,IDHW_GFXSYS
		dc.l    IDHW_WBVER,IDHW_EXECVER,IDHW_SETPATCHVER
		dc.l    IDHW_BOINGBAG,IDHW_OSVER,IDHW_OSNR
		dc.l    IDHW_DENISEREV,IDHW_DENISE
		dc.l    IDHW_AGNUSMODE,IDHW_AGNUS
		dc.l    IDHW_VBR,IDHW_CHUNKYPLANAR,IDHW_GARY,IDHW_RAMSEY
		dc.l    IDHW_CHIPSET,-1
.idtab3         dc.l    IDHW_HOSTSPEED,IDHW_HOSTCPU,IDHW_HOSTMACHINE
		dc.l    IDHW_HOSTVERS,IDHW_HOSTOS,IDHW_XLVERSION,-1
.idtab2         dc.l    IDHW_PPCOS,IDHW_PPCCLOCK,IDHW_POWERPC,-1
.idtab1         dc.l    IDHW_MMU,IDHW_FPUCLOCK,IDHW_FPU
		dc.l    IDHW_CPUREV,IDHW_CPUCLOCK,IDHW_CPU,IDHW_SYSTEM,-1
*<
*-------------------------------------------------------*
* Name:         ExpList                                 *
*                                                       *
* Funktion:     Expansion                               *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 6. Juni 1996, 18:49:53)           *
*                                                       *
ExpList         move.l  SP,d7
		moveq   #1,d6                   ;Zähler auf 1
	;-- Titelzeile -------------------------;
		move.l  #MSG_LISTEXP_LISTTITLE,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     PutStr
	;-- Liste durchgehen -------------------;
.loop           pea     TAG_DONE.w
		pea     (buf_class,PC)
		pea     IDTAG_ClassStr
		pea     (buf_prod,PC)
		pea     IDTAG_ProdStr
		pea     (buf_manuf,PC)
		pea     IDTAG_ManufStr
		pea     (.expvar,PC)
		pea     IDTAG_Expansion
		move.l  sp,a0
		idfy    IdExpansion
		move.l  d7,SP
		tst.l   d0                      ;Okay?
		bne     .done
	;-- Ausgeben ---------------------------;
		move.l  (.expvar,PC),a4
		pea     (buf_class,PC)          ;Namen
		pea     (buf_prod,PC)
		pea     (buf_manuf,PC)
		move.l  (cd_BoardSize,a4),d0    ;Board-Größe
		moveq   #" ",d1                 ;kb
		cmp.l   #1024,d0                ;>1024
		blo     .sizeok
		lsr.l   #8,d0
		lsr.l   #2,d0
		moveq   #"K",d1
		cmp.l   #1024,d0                ;>1024K
		blo     .sizeok
		lsr.l   #8,d0
		lsr.l   #2,d0
		moveq   #"M",d1
		cmp.l   #1024,d0                ;>1024M
		blo     .sizeok
		lsr.l   #8,d0
		lsr.l   #2,d0
		moveq   #"G",d1
.sizeok         move.l  d1,-(sp)
		move.l  d0,-(sp)
		move.l  (cd_BoardAddr,a4),-(sp) ;Adresse
		moveq   #0,d0                   ;Produkt-ID
		move.b  (cd_Rom+er_Product,a4),d0
		move.l  d0,-(sp)
		moveq   #0,d0                   ;Manufacturer-ID
		move    (cd_Rom+er_Manufacturer,a4),d0
		move.l  d0,-(sp)
		move.l  d6,-(sp)
		addq.l  #1,d6
		move.l  sp,d2
		move.l  #MSG_LISTEXP_BOARDLINE,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     VPrintf
		bra     .loop
	;-- Fertig -----------------------------;
.done           move.l  d7,SP
		rts
	;-- Variablen --------------------------;
.expvar         dc.l    0
*<
*-------------------------------------------------------*
* Name:         CdityList                               *
*                                                       *
* Funktion:     Commodities                             *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 6. Juni 1996, 18:49:53)           *
*                                                       *
CdityList
	;-- CX öffnen --------------------------;
		lea     (cxname,PC),a1          ;CX öffnen
		moveq   #36,d0                  ;V36
		exec    OpenLibrary
		move.l  d0,cxbase
		beq     .nocx
	;-- List-Titel ausgeben ----------------;
		move.l  #MSG_LISTEXP_CXTITLE,d0
		bsr     GetLocString
		move.l  a0,d1
		dos     PutStr
	;-- BrokerList kopieren ----------------;
		sub.l   #LH_SIZE,sp             ;Liste im Stack freimachen
		move.l  sp,a0
		NEWLIST a0                      ;initialisieren
		cx      CopyBrokerList
	;-- Liste ausgeben ---------------------;
		move.l  (sp),a4                 ;^erste Node
.loop           tst.l   (a4)                    ;Ende?
		beq     .listdone
		move.l  sp,d7                   ;Stack merken
		pea     (bc_Title,a4)
		pea     (bc_Name,a4)
		move.l  #MSG_LISTEXP_CXLINE,d0
		bsr     GetLocString
		move.l  a0,d1
		move.l  sp,d2
		dos     VPrintf
		move.l  d7,sp                   ;Stackausgleich
		move.l  (a4),a4                 ;^Nächste Node
		bra     .loop
	;-- BrokerList freigeben ---------------;
.listdone       move.l  sp,a0
		cx      FreeBrokerList
		add.l   #LH_SIZE,sp             ;Stackausgleich
	;-- Libs schließen ---------------------;
		move.l  (cxbase,PC),a1
		exec    CloseLibrary
	;-- Fertig -----------------------------;
.nocx           rts
	;-- Variablen --------------------------;
cxbase          dc.l    0                       ;CX-Base
cxname          dc.b    "commodities.library",0
		even
*<

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
InitLocale      movem.l d0-d3/a0-a3,-(sp)
	;-- Versuche, Lib zu öffnen ------------;
		lea     (.localename,PC),a1     ;locale.library öffnen
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
.localename     dc.b    "locale.library",0      ;Locale-Name
.locname        dc.b    "identifytools.catalog",0 ;Katalog-Name
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
GetLocString    movem.l d0-d3/a1-a3,-(sp)
	;-- ^Default-String holen --------------;
		lea     CatCompBlock,a1         ;String-Tabelle
.check          move.l  (a1)+,d1                ;String holen
		bmi     .notfound
		cmp.l   d0,d1                   ;Richtige ID?
		beq     .strfound
		adda.w  (a1)+,a1                ;nächste ID
		bra     .check
.strfound       addq.l  #2,a1                   ;String holen
	;-- Ist die Library offen? -------------;
.insert         move.l  (localebase,PC),d1      ;Base da?
		beq     .nolocale
	;-- Library benutzen -------------------;
		move.l  (MyCatalog,PC),a0       ;^Catalog holen
		locale  GetCatalogStr           ;String holen
		move.l  d0,a0                   ;Ergebnis zurück
	;-- Ende -------------------------------;
.exit	movem.l (sp)+,d0-d3/a1-a3
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
version         dc.b    0,"$VER: ListExp V"        ;Versions-String
		VERSION
		dc.b    " ("
		DATE
		dc.b    ")",$d,$a,0
		even

	;-- Variablen --------------------------;
dosbase         dc.l    0                       ;^DOS-Library
identifybase    dc.l    0                       ;^Identify Library
localebase      dc.l    0                       ;^Local-Base
MyCatalog       dc.l    0                       ;^Catalog-Struktur
args            dc.l    0                       ;^Ergebnis von Parse

	;-- Argumente --------------------------;
		rsreset
arg_Full        rs.l    1                       ;Full (commodities)
arg_Manuf       rs.l    1                       ;^Manufacturer
arg_Prod        rs.l    1                       ;^Prod-ID
arg_Update      rs.l    1                       ;Update
arg_SIZEOF      rs.w    0

ArgList         ds.b    arg_SIZEOF              ;Parameter-Array
template        dc.b    "FULL/S,MID=MANUFID/K/N,PID=PRODID/K/N,U=UPDATE/S",0

email           dc.b    "rkoerber@gmx.de",0
versionstr      VERSION
		dc.b    0
msg_newline     dc.b    "\n",0

dosname         dc.b    "dos.library",0         ;DOS-Lib
identifyname    dc.b    "identify.library",0
		even

	;-- Puffer -----------------------------;
buf_class       ds.b    50
buf_prod        ds.b    50
buf_manuf       ds.b    50
		even

*---------------------------------------------------------------*
*       == ENDE DES SOURCES ==                                  *
*                                                               *
		END
