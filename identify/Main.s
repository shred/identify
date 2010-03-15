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

ID_MAIN         SET     -1
CATCOMP_NUMBERS SET     1

		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/initializers.i
		INCLUDE exec/resident.i
		INCLUDE exec/execbase.i
		INCLUDE exec/tasks.i
		INCLUDE exec/memory.i
		INCLUDE dos/dos.i
		INCLUDE libraries/configregs.i
		INCLUDE libraries/configvars.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/dos.i

		INCLUDE Refs.i
		INCLUDE Base.i
		INCLUDE Locale.i

		INCLUDE identify.library_rev.i

		IFD     _MAKE_68020
		MACHINE 68020
		ENDC

		SECTION text,CODE

		XREF    EndCode

*---------------------------------------------------------------*
*       Library-Initalisierung                                  *
*                                                               *
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
libname         PRGNAME
		dc.b    0
libidstring     VSTRING

	;-- Informationen für HexReader... -------------;

		VERS
		IFD     _MAKE_68020
		 dc.b   " 68020"
		ENDC
		dc.b    "  (C) 1996-2010 Richard Körber  "
		dc.b    "  e-mail: rkoerber@gmx.de  ",13,10,0
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
		dc.l    IdExpansion                     ;-30
		dc.l    IdHardware                      ;-36
		dc.l    IdAlert                         ;-42
		dc.l    IdFunction                      ;-48
		dc.l    IdHardwareNum                   ;-54
		dc.l    IdHardwareUpdate                ;-60
		dc.l    IdFormatString                  ;-66
		dc.l    IdEstimateFormatSize            ;-72
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
		move.l  d0,identifybase         ;Base merken!
		move.l  a6,(idb_SysLib,a5)      ;Exec merken
		move.l  a6,execbase
		move.l  a0,(idb_SegList,a5)     ;SegList merken
	;-- Eigene Inits -----------------------;
		lea     (.utilsname,PC),a1      ;Utility library
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,utilsbase
		beq     .error1
		lea     (.dosname,PC),a1        ;DOS library
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,dosbase
		beq     .error1
		lea     (.expname,PC),a1        ;Expansion library
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,expbase
		beq     .error1
		lea     (.gfxname,PC),a1        ;Graphics library
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,gfxbase
		beq     .error1
		lea     database,a0             ;Database entpacken
		bsr     Unpack
		bsr     InitLocale              ;Locale strings
		bsr     InitExpansion           ;Expansion initialisieren
		bsr     InitHardware            ;Hardware initialisieren
		bsr     InitFunctions           ;Functions initialisieren
	;-- Fertig -----------------------------;
		move.l  a5,d0
.exit           movem.l (sp)+,d1-d7/a0-a6
		rts
	;-- Error ------------------------------;
.error1         moveq   #0,d0                   ;Keine Libbase -> Error
		bra     .exit
	;-- Strings ----------------------------;
.utilsname      dc.b    "utility.library",0
.expname        dc.b    "expansion.library",0
.dosname        dc.b    "dos.library",0
.gfxname        dc.b    "graphics.library",0
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
		bne     .notlast
		btst    #IDLB_DELEXP,(idb_Flags+1,a6) ;Schließen?
		beq     .notlast
		bsr     LExpunge                ;Ja: Entfernen
.notlast        rts

*-------------------------------------------------------*
* LExpunge      Lib hinauswerfen                        *
*       -» A6.l ^LibBase                                *
*                                                       *
LExpunge        movem.l d7/a5-a6,-(SP)
	;-- Zustand prüfen ---------------------;
		move.l  a6,a5
		move.l  (idb_SysLib,a5),a6
		tst     (LIB_OPENCNT,a5)        ;Hat uns jemand geöffnet?
		beq     .expimmed
.abort          bset    #IDLB_DELEXP,(idb_Flags+1,a5)  ;Expunge vormerken
		moveq   #0,d0                   ;Noch kein Expunge vorg.
		bra     .exit
	;-- Lib wird geschlossen ---------------;
.expimmed       move.l  (idb_SegList,a5),d7     ;Segliste holen
		move.l  a5,a1                   ;Von Liste entfernen
		exec    Remove
	;-- Eigene Schließungen ----------------;
		bsr     ExitFunctions           ;Functions freigeben
		bsr     ExitHardware            ;Hardware freigeben
		bsr     ExitExpansion           ;Expansion freigeben
		bsr     ExitLocale              ;Locale freigeben
		move.l  (gfxbase,PC),a1         ;Graphics freigeben
		exec    CloseLibrary
		move.l  (expbase,PC),a1         ;Expansion freigeben
		exec    CloseLibrary
		move.l  (utilsbase,PC),a1       ;Utitity freigeben
		exec    CloseLibrary
		move.l  (dosbase,PC),a1
		exec    CloseLibrary
	;-- Speicher freigeben -----------------;
		moveq   #0,d0
		move.l  a5,a1
		move    (LIB_NEGSIZE,a5),d0
		sub.l   d0,a1
		add     (LIB_POSSIZE,a5),d0
		exec    FreeMem
	;-- Fertig -----------------------------;
		move.l  d7,d0
.exit           movem.l (SP)+,d7/a5-a6
		rts

*-------------------------------------------------------*
* LNull         Nichts passiert                         *
*                                                       *
LNull           moveq   #0,d0
		rts

*---------------------------------------------------------------*
*       Variablen                                               *
*                                                               *
		XDEF    identifybase, utilsbase, dosbase, expbase, execbase, gfxbase
		XDEF    _SysBase

		even
identifybase    dc.l    0               ;^eigene Base ;)
dosbase         dc.l    0               ;^DOS-Base
utilsbase       dc.l    0               ;^Utility Base
execbase        dc.l    0               ;^Exec-Base
expbase         dc.l    0               ;^Expansion Base
gfxbase         dc.l    0               ;^Graphics Base
_SysBase        EQU     execbase
		even

		SECTION strings,DATA    ;; MUSS DIE ERSTE SEKTION SEIN!!!
database        ds.b    16              ; Wichtig: Platz für PowerPacker
		dc.b    "The database is (C) Richard Körber. Do NOT rip! Violators will be shot."
		ds.b    10
		even

		END OF SOURCE
