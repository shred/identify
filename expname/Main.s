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

*
* expname.library replacement
*

		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/initializers.i
		INCLUDE exec/resident.i
		INCLUDE exec/execbase.i
		INCLUDE exec/memory.i
		INCLUDE utility/tagitem.i
		INCLUDE lvo/exec.i

		INCLUDE libraries/identify.i

		INCLUDE Base.i

		SECTION text,CODE

VERSION         EQU     02              ;<- Version
REVISION        EQU     100             ;<- Revision

SETVER          MACRO                   ;<- Version String Macro
		dc.b    "2.100"
		ENDM

SETDATE         MACRO                   ;<- Date String Macro
		dc.b    "26.2.97"
		ENDM

*---------------------------------------------------------------*
*       Library-Initalisierung                                  *
*                                                               *
*>
*-------------------------------------------------------*
* Start         Aufruf aus CLI vorbeugen                *
*                                                       *
Start           moveq   #0,d0
		rts

*-------------------------------------------------------*
* InitDDescrip  Library wird beschrieben                *
*                                                       *
InitDDescrip    dc.w    RTC_MATCHWORD
		dc.l    InitDDescrip
		dc.l    EndCode
		dc.b    RTF_AUTOINIT,VERSION,NT_LIBRARY,0
		dc.l    libname,libidstring,Init
libname         dc.b    "expname.library",0
libidstring     dc.b    "expname.library "
		SETVER
		dc.b    " ("
		SETDATE
		dc.b    ")",13,10,0

	;-- Informationen für HexReader... -------------;

		dc.b    "expname.library V"
		SETVER
		dc.b    "  Replaces the old expname.library "
		dc.b    "and uses the identify.library  "
		dc.b    "  (C) 1996-97 Richard Körber   "
		dc.b    "  e-mail: rkoerber@gmx.de   ",13,10,0
		even

*-------------------------------------------------------*
* Init          Die Init-Tabelle folgt                  *
*                                                       *
Init            dc.l    idb_SIZEOF,FuncTab,DataTab,InitFct

*-------------------------------------------------------*
* FuncTab       Die Funktionstabelle                    *
* !! Nur Ergänzen, NIEMALS tauschen !!                  *
*                                                       *
FuncTab         dc.l    LOpen,LClose,LExpunge,LNull     ;Standard
		dc.l    GetExpName                      ;-30
		dc.l    GetSysInfo                      ;-36
		dc.l    -1                              ;-- Ende --

*-------------------------------------------------------*
* DataTab       Initalisiert die Lib-Node               *
*                                                       *
DataTab         INITBYTE        LN_TYPE,NT_LIBRARY
		INITLONG        LN_NAME,libname
		INITBYTE        LIB_FLAGS,LIBF_SUMUSED|LIBF_CHANGED
		INITWORD        LIB_VERSION,VERSION
		INITWORD        LIB_REVISION,REVISION
		INITLONG        LIB_IDSTRING,libidstring
		dc.l    0

*-------------------------------------------------------*
* InitFct       Initalisierung vornehmen                *
*       -» D0.l ^LibBase                                *
*       -» A0.l ^SegList                                *
*       -» A6.l ^SysLibBase                             *
*       «- D0.l ^Libbase                                *
*                                                       *
InitFct         movem.l d1-d7/a0-a6,-(sp)
	;-- Vektoren merken --------------------;
		move.l  d0,a5                   ;LibBase->a5
		move.l  a6,(idb_SysLib,a5)      ;Exec merken
		move.l  a0,(idb_SegList,a5)     ;SegList merken
	;-- Eigene Inits -----------------------;
		lea     (.identifyname,PC),a1   ;identify aufmachen
		moveq   #1,d0
		exec    OpenLibrary
		move.l  d0,identifybase
		beq     .error1
	;-- Fertig -----------------------------;
		move.l  a5,d0
.exit           movem.l (sp)+,d1-d7/a0-a6
		rts
	;-- Error ------------------------------;
.error1         moveq   #0,d0                   ;Keine Libbase -> Error
		bra     .exit
	;-- Strings ----------------------------;
.identifyname   dc.b    "identify.library",0
		even

*-------------------------------------------------------*
* LOpen         Lib öffnen                              *
*       -» D0.l Version                                 *
*       -» A6.l ^LibBase                                *
*       «- D0.l ^LibBase, if successful                 *
*                                                       *
LOpen           addq    #1,(LIB_OPENCNT,a6)     ;Eine Lib mehr
		bclr    #IDLB_DELEXP,(idb_Flags+1,a6) ;Nicht schließen
		move.l  a6,d0
		rts

*-------------------------------------------------------*
* LClose        Lib schließen                           *
*       -» A6.l ^LibBase                                *
*       «- D0.l ^SegList oder 0                         *
*                                                       *
LClose          moveq   #0,d0
		subq    #1,(LIB_OPENCNT,a6)     ;Eine Lib weniger
		bne.b   .notlast
		btst    #IDLB_DELEXP,(idb_Flags+1,a6) ;Schließen?
		beq.b   .notlast
		bsr.b   LExpunge                ;Ja: Entfernen
.notlast        rts

*-------------------------------------------------------*
* LExpunge      Lib hinauswerfen                        *
*       -» A6.l ^LibBase                                *
*                                                       *
LExpunge        movem.l d2/a5-a6,-(sp)
	;-- Zustand prüfen ---------------------;
		move.l  a6,a5
		move.l  (idb_SysLib,a5),a6
		tst     (LIB_OPENCNT,a5)        ;Hat uns jemand geöffnet?
		beq.b   .expimmed
.abort          bset    #IDLB_DELEXP,(idb_Flags+1,a5)  ;Expunge vormerken
		moveq   #0,d0                   ;Noch kein Expunge vorg.
		bra     .exit
	;-- Lib wird geschlossen ---------------;
.expimmed       move.l  (idb_SegList,a5),d2     ;Segliste holen
		move.l  a5,a1                   ;Von Liste entfernen
		exec    Remove
	;-- Eigene Schließungen ----------------;
		move.l  (identifybase,PC),a1    ;Identify zumachen
		exec    CloseLibrary
	;-- Speicher freigeben -----------------;
		moveq   #0,d0
		move.l  a5,a1
		move    (LIB_NEGSIZE,a5),d0
		sub.l   d0,a1
		add     (LIB_POSSIZE,a5),d0
		exec    FreeMem
	;-- Fertig -----------------------------;
		move.l  d2,d0
.exit           movem.l (sp)+,d2/a5-a6
		rts

*-------------------------------------------------------*
* LNull         Nichts passiert                         *
*                                                       *
LNull           moveq   #0,d0
		rts

*<
*---------------------------------------------------------------*
*       Funktionen                                              *
*                                                               *
*>
*-------------------------------------------------------*
* Name:         GetExpName                              *
*                                                       *
* Funktion:     Holt den Namen einer Erweiterung   (V1) *
*                                                       *
* Parameter:    -» A0.l ^Space für Manufacturer Name    *
*               -» A1.l ^Space für Product Name         *
*               -» A2.l ^ConfigDev oder NULL            *
*               -» D0.w ManufacturerID                  *
*               -» D1.b ProductID                       *
*               «- D0.l NOT Success: True/False         *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.1 ( 4. April 1996, 11:17:58)          *
*                                                       *
GetExpName      movem.l d1-d3/a0-a6,-(sp)
		move.l  sp,a5
	;-- Platz für Class --------------------;
		sub.l   #50,sp
		move.l  sp,a3
	;-- Strings pushen ---------------------;
		pea     TAG_DONE.w
		move.l  a3,-(sp)
		pea     IDTAG_ClassStr
		move.l  a1,-(sp)
		pea     IDTAG_ProdStr
		move.l  a0,-(sp)
		pea     IDTAG_ManufStr
	;-- ConfigDev da? ----------------------;
		move.l  a2,d2                   ;Und?
		beq     .nocd
		move.l  a2,-(sp)
		pea     IDTAG_ConfigDev
		bra     .start
	;-- Type und ID da? --------------------;
.nocd           move.l  d0,-(sp)
		pea     IDTAG_ManufID
		move.l  d1,-(sp)
		pea     IDTAG_ProdID
	;-- Aufrufen ---------------------------;
.start          move.l  sp,a0
		move.l  (identifybase,PC),a6
		jsr     (-30,a6)
		not.l   d0
	;-- Zusammenfügen ----------------------;
		move.l  a1,d1                   ;Product-String?
		beq     .noprod
		moveq   #48,d1                  ;49 Zeichen max
.findstr        subq.l  #1,d1
		tst.b   (a1)+
		bne     .findstr
		move.b  #" ",(-1,a1)
.copystr        move.b  (a3)+,(a1)+
		dbeq    d1,.copystr
		clr.b   -(a1)
	;-- Fertig -----------------------------;
.noprod         move.l  a5,sp
		movem.l (sp)+,d1-d3/a0-a6
		rts
*<
*-------------------------------------------------------*
* Name:         GetSysInfo                              *
*                                                       *
* Funktion:     Holt Strings über System           (V2) *
*                                                       *
* Parameter:    -» A0.l ^Space für String (50 Chars)    *
*               -» D0.l String-Typ                      *
*               -» D1.l RESERVIERT: immer 0!            *
*               «- D0.l String oder NULL: nicht da      *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  · Unbekannte Typen -> FALSE             *
*               · DraCo-Kompatibel                      *
*>                                                      *
* Revision:     1.0 ( 8. April 1996, 13:36:48)          *
*                                                       *
GetSysInfo      movem.l d1-d7/a0-a6,-(sp)
		move.l  a0,a4                   ;^Ziel
		move.l  a0,d7
		sub.l   a0,a0                   ;keine Tags
		move.l  (identifybase,PC),a6
		jsr     (-36,a6)
		tst.l   d0                      ;nix?
		beq     .done
		move.l  d0,a0
		moveq   #48,d1
.copystr        move.b  (a0)+,(a4)+             ;kopieren
		dbeq    d1,.copystr
		clr.b   -(a4)
.done           move.l  d7,d0
		movem.l (sp)+,d1-d7/a0-a6
		rts
*<
*---------------------------------------------------------------*
*       Variablen                                               *
*                                                               *
identifybase    dc.l    0               ;identify-Base

		cnop    0,4
EndCode         ds.w    0               ;<-- ENDE

		END OF SOURCE
