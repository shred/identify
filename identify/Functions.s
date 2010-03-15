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

ID_FUNCTIONS    SET     -1
CATCOMP_NUMBERS SET     1

		INCLUDE exec/memory.i
		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i
		INCLUDE exec/interrupts.i
		INCLUDE dos/dos.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/dos.i
		INCLUDE lvo/utility.i
		INCLUDE phxmacros.i

		INCLUDE libraries/identify.i

		INCLUDE Functions.i
		INCLUDE Refs.i
		INCLUDE Locale.i

		IFD     _MAKE_68020
		MACHINE 68020
		ENDC

		SECTION text,CODE

*---------------------------------------------------------------*
* strbase definieren                                            *
*>                                                              *
	;-- Wichtig! MUSS hier stehen, damit die Datensektion
	;   an der richtigen Stelle angelegt wird, und die
	;   Strings durchgehend positive Referenzen bekommen
		SAVE
		SECTION strings,DATA
strbase         ds.w    0                       ;String-Base
		RESTORE
*<

*---------------------------------------------------------------*
*       == FUNKTIONEN ==                                        *
*                                                               *
*-------------------------------------------------------*
* Name:         InitFunctions                           *
*                                                       *
* Funktion:     Initialisieren des Teils                *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (21. August 1996, 15:33:48)         *
*                                                       *
		XDEF    InitFunctions
InitFunctions   movem.l d0-d1/a0-a1,-(sp)
		lea     (liblist,PC),a0
		NEWLIST a0
	;-- MemHandler einbauen ---------------;
		move.l  (execbase,PC),a6
		cmp     #39,(LIB_VERSION,a6)
		blo     .nomh
		lea     (memint,PC),a1
		exec.q  AddMemHandler
	;-- Fertig ----------------------------;
.nomh           movem.l (SP)+,d0-d1/a0-a1
		rts
*<
*-------------------------------------------------------*
* Name:         ExitFunctions                           *
*                                                       *
* Funktion:     Functions beenden                       *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (21. August 1996, 15:35:17)         *
*                                                       *
		XDEF    ExitFunctions
ExitFunctions   movem.l d0-d7/a0-a6,-(SP)
		move.l  (execbase,PC),a6
		cmp     #39,(LIB_VERSION,a6)
		blo     .nomh
		lea     (memint,PC),a1
		exec.q  RemMemHandler
.nomh           bsr     FreeList
		movem.l (SP)+,d0-d7/a0-a6
		rts
*<
*-------------------------------------------------------*
* Name:         IdFunction                              *
*                                                       *
* Funktion:     Identifiziert eine OS-Funktion          *
*                                                       *
* Parameter:    -» A0.l ^Library-Name                   *
*               -» D0.l Offset                          *
*               -» A1.l ^Tags                           *
*               «- D0.l Error-Code                      *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (21. August 1996, 15:25:30)         *
*                                                       *
		clrfo
fn_LibName      fo.l    1       ;^Name der Library
fn_Offset       fo.l    1       ;Offset
fn_FuncNameStr  fo.l    1       ;^Name der Funktion
fn_StrLength    fo.w    1       ;Stringlänge -1 (für dbra)
fn_SIZEOF       fo.w    0

		XDEF    IdFunction
IdFunction      movem.l d1-d7/a0-a3/a5-a6,-(sp)
		link    a4,#fn_SIZEOF
		move.l  a0,(fn_LibName,a4)
		tst.l   d0                      ;Negativer Offset?
		bmi     .isneg
		neg.l   d0
.isneg          move.l  d0,(fn_Offset,a4)
		move.l  a1,a3                   ;^Tags merken
	;-- Strings zusammensuchen -------------;
		move.l  a3,a0                   ;^Stringadresse
		move.l  #IDTAG_FuncNameStr,d0
		moveq   #0,d1
		utils   GetTagData
		move.l  d0,(fn_FuncNameStr,a4)
		beq     .done
		move.l  a3,a0                   ;Stringlänge
		move.l  #IDTAG_StrLength,d0
		moveq   #50,d1
		utils   GetTagData
		subq    #1,d0
		bcs     .err_nolength
		move    d0,(fn_StrLength,a4)
	;-- Liste durchsuchen ------------------;
		move.l  (fn_LibName,a4),a0      ;Name
		bsr     FindTable               ; Tabelle dazu suchen
		tst.l   d0                      ;Fehler?
		bne     .exit                   ; Ja: raus
	;-- Offset suchen ----------------------;
		move.l  (fn_Offset,a4),d0       ;^Offset
		move.l  (fnch_FList,a0),a0      ;^erste Node
.findloop       tst.l   (a0)                    ;Ende?
		beq     .err_notfound
		cmp.l   (func_Offset,a0),d0     ;Richtiger Offset
		beq     .found
		move.l  (a0),a0                 ;Nächste node
		bra     .findloop
	;-- Name kopieren ----------------------;
.found          move.l  (LN_NAME,a0),a0         ;^Name
		move.l  (fn_FuncNameStr,a4),a1
		move    (fn_StrLength,a4),d0
.copylen        move.b  (a0)+,(a1)+
		dbeq    d0,.copylen
	;-- Fertig -----------------------------;
.done           moveq   #0,d0                   ;Alles OK
.exit           unlk    a4                      ;Fertig
		movem.l (sp)+,d1-d7/a0-a3/a5-a6
		rts
	;-- Fehler -----------------------------;
.err_notfound   moveq   #IDERR_OFFSET,d0        ;Offset nicht gefunden!
		bra     .exit
.err_nolength   moveq   #IDERR_NOLENGTH,d0      ;Länge = 0???
		bra     .exit
*<


*-------------------------------------------------------*
* Name:         FindTable                               *
*                                                       *
* Funktion:     Findet eine Funktionstabelle            *
*                                                       *
* Parameter:    -» A0.l ^Name                           *
*               «- D0.l Fehlercode                      *
*               «- A0.l ^fnch-Struktur                  *
* Register:     A4 wird gerettet                        *
*                                                       *
* Bemerkungen:  · Notfalls wird die Tabelle erzeugt     *
*>                                                      *
* Revision:     1.0 (21. August 1996, 15:40:21)         *
*                                                       *
		clrfo
ft_LibName      fo.l    1       ;^Name der Library
ft_NewNode      fo.l    1       ;^Neue Funktions-Node
ft_SIZEOF       fo.w    0

FindTable       link    a4,#ft_SIZEOF           ;Stack vorbereiten
		move.l  a0,(ft_LibName,a4)      ;Name merken
	;-- Existiert bereits? -----------------;
		move.l  a0,a1                   ;^Name
		lea     (liblist,PC),a0         ;^Liste
		exec    FindName                ;Suchen
		tst.l   d0                      ;gefunden?
		bne     .found
	;-- Node erzeugen ----------------------;
		move.l  (ft_LibName,a4),a2      ;^String
		strln.b a2,d0                   ;Länge berechnen
		add.l   #fnch_SIZEOF,d0         ;+Größe der Struktur
		move.l  #MEMF_PUBLIC|MEMF_CLEAR,d1
		exec    AllocVec
		move.l  d0,(ft_NewNode,a4)      ;bekommen?
		beq     .err_nomem
		move.l  d0,a1                   ;A1: ^Node
		lea     (fnch_FList,a1),a0      ;Funktionsliste initialisieren
		NEWLIST a0
		lea     (fnch_SIZEOF,a1),a0     ;^String-Start
		move.l  a0,(LN_NAME,a1)         ;Name eintragen
		copy.b  (a2)+,(a0)+             ;Name kopieren
		move.l  (ft_LibName,a4),a0      ;^Name in A0
		lea     (fnch_FList,a1),a1      ;Funktionsliste in A1
		bsr     FillNode                ;^Liste in A1
		bne     .err_fill               ;Fehler -> Raus
	;-- Einhängen --------------------------;
		move.l  (ft_NewNode,a4),a1      ;Neue Node
		lea     (liblist,PC),a0         ;^Liste
		exec    AddTail
		move.l  (ft_NewNode,a4),d0      ;Neue Node
	;-- Fertig -----------------------------;
.found          move.l  d0,a0                   ;^Node
		moveq   #0,d0                   ;Alles OK
.exit           unlk    a4
		rts
	;-- Fehler -----------------------------;
.err_fill       move.l  d0,d3                   ;Fehler beim Füllen
		move.l  (ft_NewNode,a4),a1      ;Node freigeben
		exec    FreeVec
		move.l  d3,d0                   ;Code merken
		bra     .exit
.err_nomem      moveq   #IDERR_NOMEM,d0         ;Kein Speicher
		bra     .exit
*<
*-------------------------------------------------------*
* Name:         FillNode                                *
*                                                       *
* Funktion:     Liste mit Funktionen füllen             *
*                                                       *
* Parameter:    -» A0.l ^Name der Library               *
*               -» A1.l ^Listen-Header                  *
*               «- D0.l Fehlercode        +CCR          *
* Register:     Üblich                                  *
*                                                       *
* Bemerkungen:  · Liste ist im Fehlerfall leer          *
*>                                                      *
* Revision:     1.0 (21. August 1996, 16:02:05)         *
*                                                       *
MAXLINELEN      EQU     256     ;Maximale Zeilenlänge

		clrfo
fln_FileName    fo.l    1       ;^Name der FD-Datei
fln_FileHandle  fo.l    1       ;^FileHandle
fln_ListHeader  fo.l    1       ;^Neue Funktions-Node
fln_CurrOffset  fo.l    1       ;Momentaner Offset
fln_LibName     fo.l    1       ;^LibName
fln_LineBuffer  fo.b    MAXLINELEN  ;Zeilenpuffer
fln_SIZEOF      fo.w    0

FillNode        movem.l d2-d7/a2-a3/a5,-(sp)
		link    a4,#fln_SIZEOF          ;Stack vorbereiten
		move.l  a0,(fln_LibName,a4)
		move.l  a1,(fln_ListHeader,a4)  ;Listenheader merken
		move.l  #-6,(fln_CurrOffset,a4) ;Offset = -6
	;-- Dateiname erzeugen -----------------;
		move.l  a0,a2                   ;^String merken
		strln.b a0,d0                   ;Länge des Strings
		moveq   #50,d1
		add.l   d1,d0                   ;Reserve zum Atmen
		move.l  #MEMF_PUBLIC,d1
		exec    AllocVec
		move.l  d0,(fln_FileName,a4)    ;bekommen?
		beq     .err_nomem
		moveq   #0,d7                   ;Suffix-Zähler
.nameloop       move.l  (fln_FileName,a4),a0
		move    d7,d0
		lea     (.str_fd,PC),a1         ;"FD:"
		subq    #2,d0
		bcs     .pathcopy
		lea     (.str_inc,PC),a1        ;"INCLUDE:fd/"
		subq    #2,d0
		bcs     .pathcopy
		; to be continued
		bra     .err_nofile             ;Passende Datei gibt es nicht
.pathcopy       copy.b  (a1)+,(a0)+
		subq.l  #1,a0                   ;Ohne Termination
		move.l  (fln_LibName,a4),a1
.copyloop       move.b  (a1)+,d0                ;Zeichen vom Namen
		beq     .copydone               ;  Termination: das war's
		cmp.b   #".",d0                 ;bis zum '.'
		beq     .copydone               ;  das war's auch
		move.b  d0,(a0)+                ;sonst einfügen
		bra     .copyloop
.copydone       lea     (.str_libfd,PC),a1
		btst    #0,d7
		beq     .suf_ok
		add.w   #4,a1                   ;nur ".fd" anhängen
.suf_ok         copy.b  (a1)+,(a0)+             ;"_lib.fd" anhängen
		move.l  (fln_FileName,a4),d1    ;Exisitert die Datei?
		move.l  #ACCESS_READ,d2
		dos     Lock
		move.l  d0,d1                   ;gelocked?
		bne     .file_ok
		addq    #1,d7                   ;Nächster Modus
		bra     .nameloop
.file_ok        dos     UnLock
	;-- Datei zum Lesen öffnen -------------;
		move.l  (fln_FileName,a4),d1    ;Dateiname
		move.l  #MODE_OLDFILE,d2        ;zum lesen
		dos     Open                    ;öffnen
		move.l  d0,(fln_FileHandle,a4)  ;Handle merken
		beq     .err_dos
	;-- Lesen ------------------------------;
.lineloop       move.l  (fln_FileHandle,a4),d1  ;FH
		lea     (fln_LineBuffer,a4),a0  ;Zeilenpuffer
		move.l  a0,d2
		move.l  #MAXLINELEN-2,d3        ;max. Länge -2 (Bug in V36/V37)
		dos     FGets                   ;Zeilenweise lesen
		tst.l   d0                      ;EOF?
		beq     .checkeof
		lea     (fln_LineBuffer,a4),a0  ;Zeile holen
		move.b  (a0),d0                 ;erstes Zeichen
		cmp.b   #"#",d0                 ;Escape Char?
		beq     .is_cmd
		cmp.b   #"*",d0                 ;Comment?
		beq     .lineloop               ;  dann nächste Zeile
		cmp.b   #32,d0                  ;irgendein Steuerzeichen?
		bls     .lineloop               ;  dann nächste Zeile
	;---- Funktionsname: Ende suchen -------;
.findloop       move.b  (a0)+,d0                ;Zeichen holen
		cmp.b   #"(",d0                 ;'('?
		beq     .foundend
		cmp.b   #32,d0                  ;Steuerzeichen inkl. Space?
		bhi     .findloop
.foundend       clr.b   -(a0)                   ;Terminieren
	;---- Node erzeugen --------------------;
		lea     (fln_LineBuffer,a4),a2  ;^Zeilenpuffer
		strln.b a2,d0                   ;Länge der Zeile
		tst.l   d0                      ;Null?
		beq     .lineloop               ;   Zeile war leer
		add.l   #func_SIZEOF,d0         ;+Größe der Struktur
		move.l  #MEMF_PUBLIC|MEMF_CLEAR,d1
		exec    AllocVec                ;belegen
		tst.l   d0                      ;Bekommen?
		beq     .err_nomem2             ;nein: Speicher freigeben
		move.l  d0,a1                   ;Hier zusammenbauen
		move.l  (fln_CurrOffset,a4),(func_Offset,a1)  ;Offset eintragen
		lea     (func_SIZEOF,a1),a0     ;^String-Puffer
		move.l  a0,(LN_NAME,a1)         ;^Name eintragen
		copy.b  (a2)+,(a0)+             ;Name kopieren
		move.l  (fln_ListHeader,a4),a0  ;^Liste
		exec    AddTail                 ;Anhängen
	;---- Offset erniedrigen ---------------;
		subq.l  #6,(fln_CurrOffset,a4)  ;Offset erniedrigen
		bra     .lineloop               ;nächste Zeile
	;-- Dateiende erreicht!? ---------------;
.checkeof       dos     IoErr                   ;IOErr lesen
		tst.l   d0                      ;Fehler
		bne     .err_dos2               ; sonst: Fertig!
	;-- Aufräumen --------------------------;
.iseof          move.l  (fln_FileHandle,a4),d1  ;Datei schließen
		dos     Close
		move.l  (fln_FileName,a4),a1    ;Dateiname freigeben
		exec    FreeVec
	;-- Fertig -----------------------------;
		moveq   #0,d0                   ;Alles OK
.exit           unlk    a4                      ;A4,SP restaurieren
		movem.l (sp)+,d2-d7/a2-a3/a5
		tst.l   d0                      ;+CCR
		rts
	;-- Fehler -----------------------------;
.err_nomem2     move.l  (fln_ListHeader,a4),a3  ;^Liste
.err_freeloop   move.l  (a3),a1                 ;Erste Node!
		tst.l   (a1)                    ;Leer?
		beq     .err_freedone
		move.l  a1,d5
		exec    Remove
		move.l  d5,a1
		exec    FreeVec
		bra     .err_freeloop
.err_freedone   moveq   #IDERR_NOMEM,d0         ;Kein Speicher
.err_dos2       move.l  d0,d7
		move.l  (fln_FileHandle,a4),d1  ;Datei schließen
		dos     Close
		bra     .err_free2
.err_dos        dos     IoErr                   ;IOerr lesen
		move.l  d0,d7
.err_free2      move.l  (fln_FileName,a4),a1    ;Dateiname freigeben
		exec    FreeVec
		move.l  d7,d0                   ;Error zurück
		bra     .exit
.err_nofile     moveq   #IDERR_NOFD,d7          ;Keine FD-Datei
		bra     .err_free2
.err_nomem      moveq   #IDERR_NOMEM,d0         ;Kein Speicher
		bra     .exit

	;-- Kommandobearbeitung ----------------;
.is_cmd         moveq   #$20,d1
		lea     (1,a0),a1               ;erstes # überspringen
		move.b  (a1)+,d0
		cmp.b   #"#",d0                 ;Nächstes auch ein # ?
		bne     .findloop               ;nein: kein Kommando!
		move.b  (a1)+,d0                ;Nächstes Zeichen
		or.b    d1,d0                   ;->downcase
		cmp.b   #"e",d0                 ;_e_nd?
		beq     .is_end
		cmp.b   #"b",d0                 ;_b_ias?
		beq     .is_bias
		bra     .lineloop               ;unbekanntes Kommando!
	;---- ##bias ? -------------------------;
.is_bias        move.b  (a1)+,d0                ;Nächstes Zeichen
		or.b    d1,d0                   ;->downcase
		cmp.b   #"i",d0                 ;b_i_as?
		bne     .lineloop
		move.b  (a1)+,d0                ;Nächstes Zeichen
		or.b    d1,d0                   ;->downcase
		cmp.b   #"a",d0                 ;bi_a_s?
		bne     .lineloop
		move.b  (a1)+,d0                ;Nächstes Zeichen
		or.b    d1,d0                   ;->downcase
		cmp.b   #"s",d0                 ;bia_s_?
		bne     .lineloop
		move.l  a1,d1                   ;^Nummer
		clr.l   -(sp)                   ;Platz für Long schaffen!
		move.l  sp,d2                   ;Hierhin das Long
		dos     StrToLong               ;Nummer wandeln
		move.l  (sp)+,d0
		bmi     .set_new_off            ;ist bereits negativ
		neg.l   d0
.set_new_off    move.l  d0,(fln_CurrOffset,a4)  ;Ist neuer Offset
		bra     .lineloop               ;Nächste Zeile
	;---- ##end ? --------------------------;
.is_end         move.b  (a1)+,d0                ;Nächstes Zeichen
		or.b    d1,d0                   ;->downcase
		cmp.b   #"n",d0                 ;e_n_d?
		bne     .lineloop
		move.b  (a1)+,d0                ;Nächstes Zeichen
		or.b    d1,d0                   ;->downcase
		cmp.b   #"d",d0                 ;en_d_?
		bne     .lineloop
		bra     .iseof                  ;JA: Parsen beenden!

	;-- Stringkonstanten -------------------;
.str_libfd      dc.b    "_lib.fd",0
.str_fd         dc.b    "FD:",0
.str_inc        dc.b    "INCLUDE:FD/",0
		even
*<

*-------------------------------------------------------*
* Name:         FreeList                                *
*                                                       *
* Funktion:     Gibt die komplette Liste frei           *
*                                                       *
* Parameter:                                            *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (21. August 1996, 16:54:51)         *
*                                                       *
FreeList        movem.l d0-d3/d7/a0-a4,-(sp)
	;-- Liste durchgehen -------------------;
		move.l  (liblist,PC),a4         ;^erste Node
.loop1          tst.l   (a4)                    ;Ende?
		beq     .done
	;-- Offsetliste durchgehen -------------;
		move.l  (fnch_FList,a4),a3      ;^erste subnode
.loop2          tst.l   (a3)                    ;Ende?
		beq     .done2
		move.l  a3,a1
		move.l  (a3),a3                 ;nächste Node
		move.l  a1,d7
		exec    Remove                  ;diese Freigeben
		move.l  d7,a1
		exec    FreeVec
		bra     .loop2
	;-- Nächste Library-Node ---------------;
.done2          move.l  a4,a1
		move.l  (a4),a4                 ;nächste Node
		move.l  a1,d7
		exec    Remove                  ;diese Freigeben
		move.l  d7,a1
		exec    FreeVec
		bra     .loop1
	;-- Fertig -----------------------------;
.done           movem.l (sp)+,d0-d3/d7/a0-a4
		rts
*<
*-------------------------------------------------------*
* Name:         LMHFreeList                             *
*                                                       *
* Funktion:     LowMemory-Handler-Aufruf                *
*                                                       *
* Parameter:    -» a0.l ^MemHandlerData                 *
*               -» a1.l ^is_Data                        *
*               «- d0.l MemHandler-Result               *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (30. Juli 1997, 14:02:26)           *
*                                                       *
LMHFreeList     bsr     FreeList                ;Freigeben
		moveq   #MEM_ALL_DONE,d0        ;sonst nichts mehr zu machen...
		rts
*<

*---------------------------------------------------------------*
*       == VARIABLEN ==                                         *
*                                                               *
		cnop    0,4
liblist         ds.b    MLH_SIZE                ;Liste aller Libraries
memint          dc.l    0,0                     ;Interrupt-Struktur
		dc.b    NT_INTERRUPT,1          ;  pri vor RAMLIB
		dc.l    .name,0,LMHFreeList     ;  Liste freigeben
.name           dc.b    "Identify MemHandler",0
		even

*---------------------------------------------------------------*
*       == ENDE ==                                              *
*                                                               *
		END OF SOURCE
