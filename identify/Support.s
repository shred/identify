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

ID_SUPPORT      SET     -1
CATCOMP_NUMBERS SET     1

		INCLUDE lvo/exec.i

		INCLUDE Refs.i
		INCLUDE Locale.i

		IFD     _MAKE_68020
		MACHINE 68020
		ENDC

		SECTION text,CODE

*---------------------------------------------------------------*
*       == FUNKTIONEN ==                                        *
*                                                               *
*-------------------------------------------------------*
* Name:         SPrintF                                 *
*                                                       *
* Funktion:     RawDoFmt                                *
*                                                       *
* Parameter:    -» A0.l ^Ziel String-Var                *
*               -» A1.l ^Quellstring                    *
*               -» A2.l ^Value-Stack                    *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 ( 8. April 1996, 13:40:39)          *
*                                                       *
		XDEF    SPrintF
SPrintF         movem.l d0-d3/a0-a3,-(sp)
		move.l  a0,a3           ;Parameter umstellen
		move.l  a1,a0
		move.l  a2,a1
		lea     (.proc,PC),a2
		exec    RawDoFmt
		movem.l (sp)+,d0-d3/a0-a3
		rts
	;-- Umsetz-Proc ------------------------;
.proc           move.b  d0,(a3)+                ;Char eintragen
		rts
*<
*-------------------------------------------------------*
* Name:         SPrintSize                              *
*                                                       *
* Funktion:     Größe drucken (mit KB, MB, GB)          *
*                                                       *
* Parameter:    -» A0.l ^Puffer                         *
*               -» D0.l Größe                           *
*               -» D1.b NewLoc mode                     *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 16:46:35)            *
*                                                       *
		XDEF    SPrintSize
SPrintSize      movem.l d0-d5/a0-a3,-(SP)
		sf      d4
		lea     (.sizetab,PC),a1        ;^Größentabelle
		lea     (.postcomma,PC),a2      ;^Nachkommastellentabelle
		moveq   #2,d5                   ;Einträge in der Größentabelle
.loop           cmp.l   #1000,d0                ;Größe <1000? (spart eine Ausgabestelle gegen 1024)
		blo     .print
		addq.l  #4,a1                   ;Nächste Größe
		move    d0,d2                   ;Runden nötig?
		and     #%1110000,d2
		cmp     #%1110000,d2
		seq     d4
		bne     .not_round
		add.l   #%0010000,d0            ;Aufrunden
.not_round      lsr.l   #7,d0                   ;Nachkommastellen ermitteln
		move    d0,d2
		and     #%111,d2
		lsr.l   #3,d0                   ;Vorkommastellen
		dbra    d5,.loop                ;Weiter geht's
.print          moveq   #0,d5                   ;Nachkomma-Char
		move.b  (a2,d2.w),d5
		move    d5,-(SP)
		move.l  d0,-(SP)                ;Vorkomma-Anteil
		move.l  a0,d3
		move.l  (a1),d0
		bsr     GetNewLocString
		move.l  a0,a1
		move.l  d3,a0
		tst.b   d4                      ;Rundungszeichen?
		beq     .no_sign
		move.b  #"~",(a0)+
.no_sign        move.l  SP,a2
		bsr     SPrintF
		add.l   #4+2,SP
		movem.l (SP)+,d0-d5/a0-a3
		rts
	;-- Strings ----------------------------;
.sizetab        dc.l    MSG_BYTE, MSG_KBYTE, MSG_MBYTE, MSG_GBYTE
.postcomma      dc.b    "01245689"
		even
*<
*-------------------------------------------------------*
* Name:         Unpack                                  *
*                                                       *
* Funktion:     Datenbank entpacken                     *
*                                                       *
* Parameter:    -» A0.l ^Gepackte Daten                 *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  · Gleichzeitig Zeiger auf Zielpuffer    *
*               · Original von Nico François            *
*               · Höchstoptimiert von Shred             *
*>                                                      *
* Revision:     1.0 (25. Februar 1997, 23:39:04)        *
*                                                       *
		XDEF    Unpack
Unpack          movem.l d0-d7/a0-a4,-(SP)
	;-- Zeiger vorbereiten -----------------;
		moveq   #1,d7                   ;     Häufig benutzte Konstante
		lea     (16,a0),a1              ;
		lea     (.efficiency,PC),a4     ;     Effizienz eintragen
		move.l  (4,a0),(a4)
		add.l   (a0),a0                 ;A0: Ende des Quellpuffers
		move.l  a1,a2                   ;A2: Anfang des Zielpuffers merken
		move.l  -(a0),d5                ;    Crunchinfo holen
		not.l   d5                      ;     (auch invertiert)
		moveq   #0,d1                   ;D1: Initialer Bitshift
		move.b  d5,d1
		lsr.l   #8,d5                   ;A1: Ende Zielpuffers
		add.l   d5,a1
		move.l  -(a0),d5                ;D5: Datafetch initalisieren
		lsr.l   d1,d5                   ;    und zurechtrücken
		moveq   #32,d6                  ;D6: RemainCnt (wieviel Bits übrig?)
		sub.b   d1,d6
		not.l   (a4)                    ;    Effizienz-Tabelle invertieren
	;-- ENTPACKEN --------------------------;
.command        move    d7,d0                   ;    Hole 1 Bit
		bsr     .Get_D0                 ;    Commandbit lesen
		tst     d1                      ;     Testen
		bne     .clone                  ;     1: clonen, sonst generieren
	;-- Byteweise generieren ---------------;
		moveq   #0,d2                   ;D2: Anzahl zu generierende Bytes
.addcnt         moveq   #2,d0                   ;    Zwei Bits holen
		bsr     .Get_D0
		add     d1,d2                   ;    auf Zähler aufaddieren
		cmp     #3,d1                   ;     wenn 3 (Maximum)
		beq     .addcnt                 ;     weitere Bits holen
.generate       moveq   #8,d0                   ;    Jetzt generieren!
		bsr     .Get_D0                 ;     Ein Byte holen
		move.b  d1,-(a1)                ;     und eintragen
		dbra    d2,.generate            ;     bis alle Bytes generiert sind
		cmp.l   a1,a2                   ;    Bereits am Ende?
		bcc     .done                   ;     ja: fertig
	;-- Clonen -----------------------------;
.clone          moveq   #2,d0                   ;    2 Bit lesen
		bsr     .Get_D0                 ;D1: Tabellenindex
		moveq   #0,d0
		move.b  (a4,d1.w),d0            ;D0: Breite des Clone-Quellenoffsets
		move    d1,d2                   ;D2: Anzahl der Clone-Bytes
		add     d7,d2                   ;    +1
		cmp     #4,d2                   ;    Wenn Index nicht 4 (Maximum)
		bne     .doclone                ;     dann Clonen (Bitbreite = Index+1)
	;---- Sonderfall Index = 3 -------------;
		move    d0,d4                   ;    "Long Distance Clone"
		move    d7,d0                   ;    1 Bit
		bsr     .Get_D0                 ;    Entscheidungs-Bit lesen
		tst     d1
		bne     .usetab                 ;     1: Tabellen-Wert übernehmen
		moveq   #7,d4                   ;     0: Breite konstant 7 Bit
.usetab         move    d4,d0                   ;    Offsetbreite holen
		bsr     .Get_D0                 ;    Offset lesen
		move    d1,d3                   ;    in D3 merken
.addclone       moveq   #3,d0                   ;    3 Bit für Anzahl lesen
		bsr     .Get_D0
		add     d1,d2                   ;D2: Anzahl der Clone-Bytes erhöhen
		cmp     #7,d1                   ;    Wenn 7 (maximum)
		beq     .addclone               ;     nochmal lesen
		lea     (1,a1,d3.w),a3          ;A3: Startadresse der Clone-Quelle
		bra     .copy                   ;    und kopieren
	;---- Normalfall: direkt clonen --------;
.doclone        bsr     .Get_D0                 ;    Offset lesen (Bitbreite in D0)
		lea     (1,a1,d1.w),a3          ;A3: Startadresse der Clone-Quelle
.copy           move.b  -(a3),-(a1)             ;    Gleichartige Sequenz übernehmen
		dbra    d2,.copy                ;     bis alle Bytes kopiert
		cmp.l   a1,a2                   ;Ende?
		bcs     .command                ; Nein: Neues Kommando holen
	;-- Fertig -----------------------------;
.done           movem.l (SP)+,d0-d7/a0-a4
		rts

	;== Bit-Shifter ========================;
	; > D0.w Anzahl zu lesender Bits
	; < D1.l Ausgelesene Sequenz
.Get_D0         moveq   #0,d1                   ;Holt D0 Bits D1
		sub     d7,d0
.bitloop        lsr.l   d7,d5                   ;Shiften
		roxl.l  d7,d1
		sub.b   d7,d6                   ;Neues Langwort nötig?
		bne     .nonewlw
		moveq   #32,d6                  ;RemainCnt = 32
		move.l  -(a0),d5                ;Neues Langwort holen
.nonewlw        dbra    d0,.bitloop
		rts                             ;Ergebnis in D1.l

	;== EFFIZIENZ-TABELLE ==================;
.efficiency     dc.l    0                       ;Effizienz-Tabelle
*<

*---------------------------------------------------------------*
*       == ENDE ==                                              *
*                                                               *
		END OF SOURCE
