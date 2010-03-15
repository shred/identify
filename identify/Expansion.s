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

ID_EXPANSION    SET     -1
CATCOMP_NUMBERS SET     1

_NOFAKES        SET     1                       ; No fakes any more since 11.1

		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/initializers.i
		INCLUDE exec/resident.i
		INCLUDE exec/execbase.i
		INCLUDE exec/tasks.i
		INCLUDE exec/memory.i
		INCLUDE libraries/configregs.i
		INCLUDE libraries/configvars.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/utility.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/dos.i

		INCLUDE libraries/identify.i

		INCLUDE Refs.i
		INCLUDE Expansion.i
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

		SECTION function,CODE
fcttab          ds.w    0                       ;Funktions-Base

		SECTION altmf,CODE
mftab           ds.w    0                       ;Alt-MF-Base
		RESTORE
*<

*---------------------------------------------------------------*
*       == FUNKTIONEN ==                                        *
*                                                               *
*-------------------------------------------------------*
* Name:         InitExpansion                           *
*                                                       *
* Funktion:     Expansion initialisieren                *
*                                                       *
* Parameter:    keine                                   *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     2.0 (13. Mai 1996, 00:55:32)            *
*                                                       *
		XDEF    InitExpansion
InitExpansion   movem.l d0-d1/a0,-(SP)
		move.l  (execbase,PC),a0
		moveq   #"6",d0                 ;Startzeichen
		move    (AttnFlags,a0),d1
		btst    #AFB_68060,d1
		bne     .done
		subq    #2,d0
		btst    #AFB_68040,d1
		bne     .done
		subq    #1,d0
		btst    #AFB_68030,d1
		bne     .done
		subq    #1,d0
		btst    #AFB_68020,d1
		bne     .done
		subq    #1,d0
		btst    #AFB_68010,d1
		bne     .done
		subq    #1,d0
.done           move.b  d0,cpuchar
		movem.l (SP)+,d0-d1/a0
		rts
*<
*-------------------------------------------------------*
* Name:         ExitExpansion                           *
*                                                       *
* Funktion:     Expansion beenden                       *
*                                                       *
* Parameter:    keine                                   *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     2.0 (13. Mai 1996, 00:55:32)            *
*                                                       *
		XDEF    ExitExpansion
ExitExpansion   rts
*<

*-------------------------------------------------------*
* Name:         IdExpansion                             *
*                                                       *
* Funktion:     Holt den Namen einer Erweiterung   (V1) *
*                                                       *
* Parameter:    -» A0.l ^Tags                           *
*               «- D0.l Error-Code                      *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  · Der Produktname wird über den Namen   *
*                 der Treiber-Node "erraten", wenn er   *
*                 nicht bekannt ist.                    *
*>                                                      *
* Revision:     2.0 (13. Mai 1996, 00:55:32)            *
*                                                       *
		clrfo
exp_TagItem     fo.l    1       ;^^TagItem für NextTagItem()
exp_ConfigDev   fo.l    1       ;^ConfigDev-Struktur
exp_CDevPtr     fo.l    1       ;^^ConfigDev-Struktur (für Durchlauf)
exp_ManufID     fo.w    1       ;Manufacturer ID
exp_ProdID      fo.w    1       ;Product ID
exp_ManufStr    fo.l    1       ;^Manuf-String
exp_ProdStr     fo.l    1       ;^Prod-String
exp_ClassStr    fo.l    1       ;^Class-String
exp_ClassID     fo.l    1       ;^Class-ID-Puffer
exp_ReturnCode  fo.l    1       ;Return-Code
exp_Secondary   fo.b    1       ;Secondary warnings
exp_GotID       fo.b    1       ;Eine gültige ID zum Suchen vorhanden?
exp_Localize    fo.b    1       ;Localisieren
exp_Pad         fo.b    1       ;PAD
exp_StrLength   fo.w    1       ;(schon -1 für DBRA)
exp_Buffer      fo.b    10      ;Temporärer Puffer
exp_SIZEOF      fo.w    0

		XDEF    IdExpansion
IdExpansion     movem.l d1-d7/a0-a3/a5-a6,-(sp)
		link    a4,#exp_SIZEOF
		moveq   #((exp_ConfigDev-exp_StrLength)/2)-1,d0
		lea     (exp_ConfigDev,a4),a1
.clear          clr     -(a1)
		dbra    d0,.clear
		move.l  a0,(exp_TagItem,a4)     ;^TagListe
		move    #49,(exp_StrLength,a4)
		st      (exp_Localize,a4)
	;-- Parameter suchen -------------------;
.tagloop        lea     (exp_TagItem,a4),a0
		utils   NextTagItem
		tst.l   d0                      ;kein Tag mehr?
		beq     .tagdone
		move.l  d0,a0                   ;^Tag holen
		move.l  (a0)+,d0                ;Tag-Code
		move.l  (a0),d1                 ;Tag-Datum
		sub.l   #IDTAG_ConfigDev,d0     ;IDTAG_ConfigDev ?
		beq     .configdev
		subq.l  #1,d0                   ;IDTAG_ManufID ?
		beq     .manufid
		subq.l  #1,d0                   ;IDTAG_ProdID ?
		beq     .prodid
		subq.l  #1,d0                   ;IDTAG_StrLength ?
		beq     .strlength
		subq.l  #1,d0                   ;IDTAG_ManufStr ?
		beq     .manufstr
		subq.l  #1,d0                   ;IDTAG_ProdStr ?
		beq     .prodstr
		subq.l  #1,d0                   ;IDTAG_ClassStr ?
		beq     .classstr
		subq.l  #6,d0                   ;IDTAG_Expansion ?
		beq     .expansion
		subq.l  #1,d0                   ;IDTAG_Secondary ?
		beq     .secondary
		subq.l  #1,d0                   ;IDTAG_ClassID ?
		beq     .classid
		subq.l  #1,d0                   ;IDTAG_Localize ?
		beq     .localized
		bra     .tagloop                ;unbekanntes Tag
	;-- Tags setzen ------------------------;
.configdev      move.l  d1,a5                   ;-------------------------
		move.l  d1,(exp_ConfigDev,a4)
		beq     .tagloop
		move    (cd_Rom+er_Manufacturer,a5),(exp_ManufID,a4) ;Manuf.
		move.b  (cd_Rom+er_Product,a5),(exp_ProdID+1,a4)     ;Product
		st      (exp_GotID,a4)
		bra     .tagloop
.manufid        move    d1,(exp_ManufID,a4)     ;-------------------------
		st      (exp_GotID,a4)
		bra     .tagloop
.prodid         move.b  d1,(exp_ProdID+1,a4)    ;-------------------------
		bra     .tagloop                ; absichtlich kein st (..)
.strlength      subq    #1,d1                   ;-------------------------
		bcs     .err_nolength
		move    d1,(exp_StrLength,a4)
		bra     .tagloop
.manufstr       move.l  d1,(exp_ManufStr,a4)    ;-------------------------
		bra     .tagloop
.prodstr        move.l  d1,(exp_ProdStr,a4)     ;-------------------------
		bra     .tagloop
.classstr       move.l  d1,(exp_ClassStr,a4)    ;-------------------------
		bra     .tagloop
.expansion      tst.l   d1                      ;-------------------------
		beq     .tagloop
		move.l  d1,a2
		move.l  (a2),a0
		moveq   #-1,d0
		moveq   #-1,d1
		expans  FindConfigDev
		move.l  d0,a5
		move.l  d0,(exp_ConfigDev,a4)
		move.l  d0,(a2)
		beq     .err_done
		move    (cd_Rom+er_Manufacturer,a5),(exp_ManufID,a4) ;Manuf.
		move.b  (cd_Rom+er_Product,a5),(exp_ProdID+1,a4)     ;Product
		st      (exp_GotID,a4)
		bra     .tagloop
.secondary      tst.l   d1                      ;-------------------------
		sne     (exp_Secondary,a4)
		bra     .tagloop
.classid        move.l  d1,(exp_ClassID,a4)     ;-------------------------
		bra     .tagloop
.localized      tst.l   d1                      ;-------------------------
		sne     (exp_Localize,a4)
		bra     .tagloop
	;-- Suche vorbereiten ------------------;
.tagdone        tst.b   (exp_GotID,a4)          ;haben wir was zum suchen?
		beq     .err_badid
	;-- Suchen -----------------------------;
		move.l  a5,a0                   ;Los geht die Suche
		move    (exp_ManufID,a4),d0
		move    (exp_ProdID,a4),d1
		bsr     GetBoard
	;-- Manuf-ID unbekannt? ----------------;
		tst.l   (exp_ManufStr,a4)       ;Interessiert überhaupt?
		beq     .manufdone
		move.l  a0,d1                   ;null?
		bne     .manufok
		moveq   #0,d1
		move    (exp_ManufID,a4),d1     ;Wandeln
		bsr     .to_num
	;-- Kopieren ---------------------------;
.manufok        move.l  (exp_ManufStr,a4),a2    ;Hier geht's rein
		move    (exp_StrLength,a4),d1   ;kopieren
.manufcopy      move.b  (a0)+,(a2)+
		dbeq    d1,.manufcopy
		clr.b   -(a2)
	;-- Prod-ID unbekannt? -----------------;
.manufdone      tst.l   (exp_ProdStr,a4)        ;Interessiert überhaupt?
		beq     .proddone
		move.l  a1,d1                   ;existiert ein Name?
		bne     .prodok
	;---- Produkt über Node ermitteln ------;
		bsr     NameFromNode            ;Name ermittelbar?
		beq     .prodconv               ;  nein: Nummer konvertieren
		move.l  d0,a1                   ;^String
		move.l  (exp_ProdStr,a4),a2     ;Hier geht's rein
		move    (exp_StrLength,a4),d1   ;kopieren
.proddotcopy    move.b  (a1)+,d0                ;bis zum Punkt
		cmp.b   #".",d0
		bne     .nodot
		moveq   #0,d0                   ;dann terminieren
.nodot          move.b  d0,(a2)+
		dbeq    d1,.prodcopy
		clr.b   -(a2)
		move.l  #MSG_EXP_GUESS,d0       ; nur geraten
		bra     .proddone
	;---- Produkt beziffern ----------------;
.prodconv       moveq   #0,d1
		move    (exp_ProdID,a4),d1      ;Wandeln
		bsr     .to_num
		move.l  a0,a1
		move.l  #MSG_EXP_UNKNOWN,d0     ; ist nicht bekannt
	;-- Kopieren ---------------------------;
.prodok         move.l  (exp_ProdStr,a4),a2     ;Hier geht's rein
		move    (exp_StrLength,a4),d1   ;kopieren
		move.b  (a1),d2                 ;Spezial-String?
		cmp.b   #"¡",d2                 ;Secondary?
		bne     .no2nd
		tst.b   (exp_Secondary,a4)      ;Warnen vor Secondary?
		beq     .no2ndwarn
		moveq   #IDERR_SECONDARY,d2
		move.l  d2,(exp_ReturnCode,a4)
.no2ndwarn      addq.l  #1,a1                   ;Überspringen
		move.b  (a1),d2
.no2nd          cmp.b   #"§",d2
		beq     .cpu_special
.prodcopy       move.b  (a1)+,(a2)+             ;Sonst Turbo-Copy
		dbeq    d1,.prodcopy
.prod_reentry   clr.b   -(a2)                   ;<- von cpu_special!!
	;-- Class wandeln ----------------------;
.proddone       move.l  (exp_ClassID,a4),d1     ;Class ID gewünscht?
		beq     .noclassid
		move.l  d1,a2
		move.l  d0,d1
		sub.l   #MSG_EXP_UNKNOWN,d1
		move.l  d1,(a2)                 ;dort Class-ID eintragen
.noclassid      move.l  (exp_ClassStr,a4),d1    ;Hier geht's rein
		beq     .classdone              ; interessierte nicht
		move.l  d1,a2
		move.b  (exp_Localize,a4),d1    ;Localize
		bsr     GetNewLocString         ;String ermitteln
		move    (exp_StrLength,a4),d1   ;kopieren
.classcopy      move.b  (a0)+,(a2)+
		dbeq    d1,.classcopy
		clr.b   -(a2)
	;-- to be continued... -----------------;
.classdone
	;-- Fertig -----------------------------;
.done           move.l  (exp_ReturnCode,a4),d0  ;Alles OK
.exit           unlk    a4                      ;Fertig
		movem.l (sp)+,d1-d7/a0-a3/a5-a6
		rts
	;-- Fehler -----------------------------;
.err_nolength   moveq   #IDERR_NOLENGTH,d0      ;Länge = 0???
		bra     .exit
.err_badid      moveq   #IDERR_BADID,d0         ;falsche/fehlende ID
		bra     .exit
.err_done       moveq   #IDERR_DONE,d0          ;Fertig
		bra     .exit

	;-- Spezielle CPU-Copy-Routine ---------;
.cpu_special    move.l  d0,-(SP)
		addq.l  #1,a1                   ;Sonderzeichen skippen
		move.l  (exp_ConfigDev,a4),d2
.speccopy       move.b  (a1)+,d0
		cmp.b   #"§",d0                 ;Escape-Zeichen für Prozessor?
		bne     .specnocpu
		move.b  (a1)+,d0                ;Prozessor-Zeichen holen
		tst.l   d2                      ;keine ConfigDev?
		beq     .specnocpu              ;dann das Default-Zeichen ausgeben
		move.b  (cpuchar,PC),d0
.specnocpu      move.b  d0,(a2)+
		dbeq    d1,.speccopy
		move.l  (SP)+,d0
		bra     .prod_reentry

	;== .to_num : Wandeln in Nummer ========;
.to_num         lea     (exp_Buffer+10,a4),a0   ;Puffer-Start
		clr.b   -(a0)                   ;Terminator
.divloop        divu    #10,d1                  ;eins weniger
		swap    d1
		add.b   #"0",d1
		move.b  d1,-(a0)
		clr     d1
		swap    d1
		bne     .divloop
		move.b  #"#",-(a0)
		rts
*<

*-------------------------------------------------------*
* Name:         GetBoard                                *
*                                                       *
* Funktion:     Board-Namen ermitteln                   *
*                                                       *
* Parameter:    -» A0.l ^ConfigDev oder NULL            *
*               -» D0.w Manuf-ID                        *
*               -» D1.b Board-ID                        *
*               «- A0.l ^Manufacturer-Name oder NULL    *
*               «- A1.l ^Board-Name oder NULL           *
*               «- D0.l Board-Klassen-ID                *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  ManufID und BoardID müssen gültig sein! *
*>                                                      *
* Revision:     1.0 (29. April 1996, 23:13:52)          *
*                                                       *
GetBoard        movem.l d1-d4/a2-a5,-(SP)
		and     #$00ff,d1               ;D1: Board ID
		lea     strbase,a4              ;A4: String-Base
		move.l  a0,a5                   ;A5: ConfigDev
		sub.l   a0,a0                   ;A0: Manuf-Name
		sub.l   a1,a1                   ;A1: Board-Name
	;-- Manufacturer suchen ----------------;
		lea     manuf_tab,a3            ;Start
.loopmanuf      sub     (manuf_ID,a3),d0        ;Richtige ID
		beq     .foundmanuf
		bcs     .exit                   ; nicht gefunden
		adda.w  (manuf_Next,a3),a3      ;Nächste Node
		bra     .loopmanuf
.foundmanuf     move.l  a4,a0
		adda.w  (manuf_Name,a3),a0      ;Name erzeugen
	;-- Board suchen -----------------------;
		move    (manuf_Next,a3),d4      ;Anzahl der Boards
		subq    #manuf_SIZEOF,d4
		addq.l  #manuf_SIZEOF,a3        ;^erste Board-Strukt
		move.b  d1,d2
.loopboard      subq    #board_SIZEOF,d4        ;Ende erreicht?
		bcs     .exit
		sub.b   (board_ID,a3),d2        ;Richtige ID?
		beq     .foundboard
		addq.l  #board_SIZEOF,a3        ;nächstes Board
		bra     .loopboard
.foundboard     move    (board_Name,a3),d2      ;Namen holen
		moveq   #0,d0
		move.b  (board_Type,a3),d0      ;Typ holen
		beq     .callfct
		move.l  a4,a1
		add.w   d2,a1                   ;Name erzeugen
		add.l   #MSG_EXP_UNKNOWN-1,d0
	;-- Fertig -----------------------------;
.exit           movem.l (SP)+,d1-d4/a2-a5
		rts
	;-- Funktion aufrufen ------------------;
.callfct        tst     d2                      ;Alternativer Manufacturer?
		bmi     .altmf
	;---- Funktion starten -----------------;
		lea     fcttab,a2
		move.l  (a2,d2.w),a2
		jsr     (a2)                    ;Board bestimmen
		bra     .exit
	;---- Alternativer Manufacturer --------;
.altmf          lea     mftab,a2                ;alt. MF
		not     d2
		mulu    #altmf_SIZEOF,d2
		adda.w  d2,a2
		move.l  a4,a0
		adda.w  (a2)+,a0
		move.l  a4,a1
		adda.w  (a2)+,a1
		moveq   #0,d0
		move    (a2),d0
		add.l   #MSG_EXP_UNKNOWN,d0
		bra     .exit

*<
*-------------------------------------------------------*
* Name:         NameFromNode                            *
*                                                       *
* Funktion:     Liest den Namen aus der Handler-Node    *
*                                                       *
* Parameter:    -» A5.l ^ConfigDev oder NULL            *
*               «- D0.l ^Name oder NULL           +CCR  *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 11:05:15)            *
*                                                       *
NameFromNode    movem.l d1-d3/d6/a0-a3,-(SP)
		move.l  a5,d0                   ;Überhaupt eine ConfigDev?
		beq     .bad
		move.l  (cd_Driver,a5),d3       ;^Treiber-Node
		beq     .bad                    ; nein -> Nr. übersetzen
		btst    #0,d3                   ;gerade Adresse?
		bne     .bad                    ; nein -> raus hier!
		move.l  d3,a1                   ;Prüfen, ob im RAM
		exec    TypeOfMem
		tst.l   d0
		beq     .bad                    ; nein -> raus hier!
		move.l  d3,a0                   ;^Node
		move.l  (LN_NAME,a0),d3         ;^Name holen
		beq     .bad                    ; Kein Treiber-Name da
		move.l  d3,a1
		exec    TypeOfMem               ;Richtiger Typ?
		tst.l   d0
		beq     .bad
		move.l  d3,d0                   ;Alles kar
.exit           movem.l (SP)+,d1-d3/d6/a0-a3    ;+CCR
		rts
.bad            moveq   #0,d0
		bra     .exit
*<


*---------------------------------------------------------------*
*       == EXPANSION-TABELLE ==                                 *
*                                                               *
		SECTION tables,DATA

manuf_tab       tabinit

		manuf   00001,"Mikronik"
		board     170,"Infinity Tower"          ,MSG_EXP_RAM
		endmf   00001

		manuf   00211,"Pacific Peripherals"     ;Profex
		board     000,"SE 2000 A500"            ,MSG_EXP_HD
		board     010,"HD Controller"           ,MSG_EXP_SCSIHD
		endmf   00211

		manuf   00221,"Kupke"
		board     000,"Golem RAM Box 2MB"       ,MSG_EXP_RAM    ;A500/A100 2MB RAM exp.
		board     042,"SE 2000"                 ,MSG_EXP_RAM
		endmf   00221

		manuf   00256,"Memphis"                 ;Jochheim Computer Tuning
		board     000,"Stormbringer"            ,MSG_EXP_TURBO
		board     002,"2-8MB RAM (2MB)"         ,MSG_EXP_RAM    ;SysInfo
		board     004,"2-8MB RAM (4MB)"         ,MSG_EXP_RAM    ;SysInfo
		board     019,"Warp Engine"             ,MSG_EXP_TURBOSCSIHD  ;linux
		endmf   00256

		manuf   00512,"3-State Computertechnik"
		board     002,"Megamix 2000"            ,MSG_EXP_RAM    ;512KB-8MB
		endmf   00512

		manuf   00513,"Commodore Braunschweig"
		board     001,"A2088 XT / A2286 AT"     ,MSG_EXP_BRIDGE
		board     002,"A2286 AT"                ,MSG_EXP_BRIDGE
		board     084,"A4091"                   ,MSG_EXP_SCSIHD
		board     103,"A2386 SX"                ,MSG_EXP_BRIDGE
		endmf   00513

		manuf   00514,"Commodore West Chester"
		board     001,"A2090 / A2090-A"         ,MSG_EXP_SCSIHD
		board     002,"A590 / A2091"            ,MSG_EXP_SCSIHD
		board     003,"A590 / A2091"            ,MSG_EXP_SCSIHD  ; A590
		board     004,"A2090-B"                 ,MSG_EXP_SCSIHD   ;AutoBoot card
		board     009,"A2060"                   ,MSG_EXP_ARCNET
		board     010,"A2052 / A2058 / A590 / A2091" ,MSG_EXP_RAM
		board     032,"A560"                    ,MSG_EXP_RAM
		board     069,"A2232 (prototype)"       ,MSG_EXP_MULTIIO
		board     070,"A2232"                   ,MSG_EXP_MULTIIO
		board     080,"A2620 68020"             ,MSG_EXP_TURBOANDRAM
		board     081,"A2630 68030"             ,MSG_EXP_TURBOANDRAM
		board     084,"A4091"                   ,MSG_EXP_SCSIHD
		board     090,"A2065"                   ,MSG_EXP_ETHERNET
		board     096,"Romulator"               ,MSG_EXP_UNKNOWN
		board     097,"A3000 Test Fixture"      ,MSG_EXP_MISC
		board     103,"A2386 SX"                ,MSG_EXP_BRIDGE
		board     106,"CD³²"                    ,MSG_EXP_SCSIHD
		board     112,"A2065"                   ,MSG_EXP_ETHERNET
		endmf   00514

		manuf   00515,"Commodore West Chester"
		board     003,"A2090-A Combitec/MacroSystem",MSG_EXP_HD
		endmf   00515

		manuf   00756,"Progressive Periph.&Systems"
		board     002,"EXP8000"                 ,MSG_EXP_RAM
		endmf   00756

		manuf   00767,"Kolff Computer Supplies"
		board     000,"KCS Power PC"            ,MSG_EXP_BRIDGE
		endmf   00767

		manuf   01004,"Cardco Ltd."
		board     004,"Kronos 2000"             ,MSG_EXP_SCSIHD
		board     012,"A1000/A2000"             ,MSG_EXP_SCSIHD
		board     014,"Escort"                  ,MSG_EXP_SCSIHD
		board     245,"A2410 HiRes"             ,MSG_EXP_GFX
		endmf   01004

		manuf   01005,"A-Squared"
		board     001,"Live! 2000"              ,MSG_EXP_VIDEO
		endmf   01005

		manuf   01006,"Comspec Communications"
		board     001,"AX2000"                  ,MSG_EXP_RAM
		endmf   01006

		manuf   01009,"Anakin Research"
		board     001,"Easyl"                   ,MSG_EXP_TABLET
		endmf   01009

		manuf   01010,"Microbotics"
		board     000,"StarBoard II"            ,MSG_EXP_RAM    ; MB1230 XA Accelerator ???
		board     002,"StarBoard II M.F.M."     ,MSG_EXP_HD     ;StarDrive ?
		board     003,"8-Up! (PIC A)"           ,MSG_EXP_RAM
		board     004,"8-Up! (PIC B)"           ,MSG_EXP_RAM
		board     018,"Modem 19"                ,MSG_EXP_MODEM
		board     032,"Delta Card"              ,MSG_EXP_RAM
		board     064,"8-Star!"                 ,MSG_EXP_RAM
		board     065,"8-Star!"                 ,MSG_EXP_MISC
		board     068,"VXL RAM*32"              ,MSG_EXP_RAM
		board     069,"VXL 68030/6888x"         ,MSG_EXP_TURBO
		board     096,"Delta Card"              ,MSG_EXP_MISC
		board     129,"MBX 1200 / 1200z"        ,MSG_EXP_RAM
		board     136,"VXL Turbo"               ,MSG_EXP_TURBO
		board     150,"Hardframe 2000"          ,MSG_EXP_SCSIHD
		board     158,"Hardframe 2000"          ,MSG_EXP_SCSIHD
		board     193,"MBX 1200 / 1200z"        ,MSG_EXP_MISC
		endmf   01010

		manuf   01012,"Access Associates"
		board     000,"Allegra"                 ,MSG_EXP_RAM    ; ID richtig?
		board     001,"Allegra"                 ,MSG_EXP_RAM
		endmf   01012

		manuf   01014,"Expansion Technologies"
		endmf   01014

		manuf   01023,"ASDG"
		board     001,"2MB"                     ,MSG_EXP_RAM
		board     002,"?"                       ,MSG_EXP_RAM
		board     254,"LanRover"                ,MSG_EXP_ETHERNET
		board     255,"GPIB / IEEE-488 / Twin-X (dual)" ,MSG_EXP_SERIAL
		endmf   01023

		manuf   01028,"Imtronics"
		board     057,"Hurricane 2800 (68030)"  ,MSG_EXP_TURBO
		board     087,"Hurricane 2800 (68030)"  ,MSG_EXP_TURBO
		endmf   01028

		manuf   01030,"Commodore, University of Lowell"
		board     000,"A2410 HiRes Framebuffer" ,MSG_EXP_GFX
		endmf   01030

		manuf   01053,"Ameristar"
		board     001,"A2065"                   ,MSG_EXP_ETHERNET
		board     009,"A2060 / A560"            ,MSG_EXP_ARCNET
		board     010,"A4066"                   ,MSG_EXP_ETHERNET
		board     020,"1600-GX"                 ,MSG_EXP_GFX
		endmf   01053

		manuf   01056,"Supra"
		board     001,"SupraDrive 4x4"          ,MSG_EXP_SCSIHD
		board     002,"1000 1MB"                ,MSG_EXP_RAM
		board     003,"2000 DMA"                ,MSG_EXP_SCSIHD
		board     005,"500"                     ,MSG_EXP_RAMSCSIHD
		board     008,"500 (Autoboot)"          ,MSG_EXP_SCSIHD
		board     009,"500XP / 2000"            ,MSG_EXP_RAM    ;2MB
		board     010,"SupraRAM 2000"           ,MSG_EXP_RAM    ;2MB-8MB
		board     011,"2400zi"                  ,MSG_EXP_MODEM
		board     012,"500XP / SupraDrive WordSync" ,MSG_EXP_SCSIHD
		board     013,"SupraDrive ByteSync"     ,MSG_EXP_SCSIHD
		board     016,"2400zi+"                 ,MSG_EXP_MODEM
		endmf   01056

		manuf   01058,"Computer Systems Ass."
		board     017,"Magnum 040"              ,MSG_EXP_TURBOANDRAM
		board     021,"12 Gauge 030/882"        ,MSG_EXP_TURBOANDRAM
		endmf   01058

		manuf   01081,"Marc Michael Groth"
		endmf   01081

		manuf   01227,"???"
		board     002,"???"                     ,MSG_EXP_UNKNOWN
		endmf   01227

		manuf   01282,"M-Tech"
		board     003,"AT500"                   ,MSG_EXP_RAM
		endmf   01282

		manuf   01761,"GVP"
		board     008,"Impact Series I"         ,MSG_EXP_RAMSCSIHD ; A2000 2MB RAM Board
		endmf   01761

		manuf   01803,"UAE"
		board     001,"emulated"                ,MSG_EXP_RAM
		board     002,"emulated"                ,MSG_EXP_HD
		board     003,"emulated"                ,MSG_EXP_RAM
		board     096,"emulated"                ,MSG_EXP_GFX
		endmf   01803

		manuf   02010,"ByteBox"
		board     000,"A500"                    ,MSG_EXP_UNKNOWN
		endmf   02010

		manuf   02011,"Prototype ID"
		boarda    000,"Prototype","General Prototype" ,MSG_EXP_MISC
		boardf    001,f_uae_001
		boardf    002,f_uae_002
		boarda    003,"UAE","emulated"          ,MSG_EXP_RAM
		boarda    096,"UAE","emulated"          ,MSG_EXP_GFX
		boarda    224,"Vector","Connection"     ,MSG_EXP_MULTIIO
		boarda    225,"Vector","Connection"     ,MSG_EXP_MULTIIO
		boarda    226,"Vector","Connection"     ,MSG_EXP_MULTIIO
		boarda    227,"Vector","Connection"     ,MSG_EXP_MULTIIO
		endmf   02011

		manuf   02012,"DKB / Power Computing"
		board     001,"BattDisk"                ,MSG_EXP_MISC   ;RAM-Disk
		board     009,"SecureKey"               ,MSG_EXP_ACCESS
		board     014,"DKM 3128"                ,MSG_EXP_RAM
		board     015,"Rapid Fire"              ,MSG_EXP_SCSIHD
		board     016,"DKM 1202"                ,MSG_EXP_RAMFPU
		board     018,"Cobra/Viper II 68EC030"  ,MSG_EXP_TURBO
		boardf    023,f_dkb_023
		board     255,"WildFire 060"            ,MSG_EXP_TURBO
		endmf   02012

		manuf   02017,"GVP"
		board     001,"Impact Series I (4K)"    ,MSG_EXP_SCSIHD
		board     002,"Impact Series I (16K/2)" ,MSG_EXP_SCSIHD
		board     003,"Impact Series I (16K/3)" ,MSG_EXP_SCSIHD     ; Rev 3.5
		board     008,"Impact 3001"             ,MSG_EXP_TURBOIDE   ; Rev 3, 68030
		board     009,"¡Impact 3001"            ,MSG_EXP_RAM        ; TurboIDE? 1-16MB 32bit
		board     010,"Impact Series II"        ,MSG_EXP_RAM        ; 2-8MB
		boardf    011,f_gvp_011
		board     013,"Impact 3001"             ,MSG_EXP_TURBOIDE   ; GForce 040 with SCSI ; GVP A2000 68030 Turbo Board
		board     022,"§G-Force '0§40"          ,MSG_EXP_TURBOSCSIHD  ; ID 32 ???? ; TekMagic A2000'060 Combo (TURBO/RAM)
		board     032,"Impact Vision 24"        ,MSG_EXP_GFX
		board     254,"A1230 030/882"           ,MSG_EXP_TURBO
		board     255,"§G-Force '0§40 I/O"      ,MSG_EXP_MULTIIO
		endmf   02017

		manuf   02021,"Synergy"                 ; California Access
		board     001,"Malibu"                  ,MSG_EXP_SCSIHD
		endmf   02021

		manuf   02022,"Xetec"
		board     001,"FastCard"                ,MSG_EXP_SCSIHD ;FastTrak
		board     002,"FastCard"                ,MSG_EXP_RAM
		board     003,"FastCard plus"           ,MSG_EXP_HD
		endmf   02022

		manuf   02026,"Progressive Periph.&Systems"
		board     000,"Mercury"                 ,MSG_EXP_TURBO
		board     001,"A3000 68040"             ,MSG_EXP_TURBO
		board     002,"?"                       ,MSG_EXP_RAM
		board     068,"Rambrandt"               ,MSG_EXP_GFX
		board     105,"A2000 68040"             ,MSG_EXP_TURBOANDRAM
		board     120,"ProRAM 3000"             ,MSG_EXP_RAM
		board     150,"Zeus 040"                ,MSG_EXP_TURBOSCSIHD
		board     187,"A500 68040"              ,MSG_EXP_TURBO
		board     254,"Pixel64"                 ,MSG_EXP_GFX
		board     255,"Pixel64"                 ,MSG_EXP_GFXRAM
		endmf   02026

		manuf   02028,"Xebec"
		endmf   02028

		manuf   02030,"Palomax"
		board     000,"MAX-125"                 ,MSG_EXP_MISC   ;AUTOBOOT
		endmf   02030

		manuf   02034,"Spirit Technology"
		board     001,"Insider IN1000"          ,MSG_EXP_RAM    ;1.5MB
		board     002,"Insider IN500"           ,MSG_EXP_RAM    ;1.5MB
		board     003,"SIN500"                  ,MSG_EXP_RAM    ;2MB
		board     004,"HDAST506"                ,MSG_EXP_HD
		board     005,"AX-S IBM"                ,MSG_EXP_MULTIIO  ;Hardware I/O board?!
		board     006,"OctaByte X-RAM"          ,MSG_EXP_RAM    ;8MB RAM
		board     008,"Inmate Multifunction"    ,MSG_EXP_SCSIHD ;Multifunktional (SCSI/FPP/Mem)
		endmf   02034

		manuf   02035,"Spirit Technology"
		endmf   02035

		manuf   02046,"AlfaData"
		board     003,"ALF 3"                   ,MSG_EXP_SCSIHD
		endmf   02046

		manuf   02049,"BSC"             ;(Elaborate Bytes)
		board     001,"ALF 2 MFM"               ,MSG_EXP_HD
		board     002,"ALF 2"                   ,MSG_EXP_SCSIHD
		board     003,"ALF 3"                   ,MSG_EXP_SCSIHD
		board     005,"Oktagon 2008"            ,MSG_EXP_SCSIHD
		board     006,"Tandem"                  ,MSG_EXP_SCSIHD
		board     008,"Memory-Master"           ,MSG_EXP_RAM
		endmf   02049

		manuf   02050,"Cardco Ltd."     ;MicroDyn (C'Ltd Successor)
		board     004,"Kronos 2000"             ,MSG_EXP_SCSIHD
		board     012,"A1000"                   ,MSG_EXP_SCSIHD
		endmf   02050

		manuf   02052,"Jochheim"
		board     001,"2/8 MB"                  ,MSG_EXP_RAM
		endmf   02052

		manuf   02055,"Checkpoint Technologies"
		board     000,"Serial Solution (dual)"  ,MSG_EXP_SERIAL
		endmf   02055

		manuf   02064,"Edotronik"
		board     001,"IEEE-488 Controller"     ,MSG_EXP_MISC
		board     002,"8032 development adapter",MSG_EXP_MISC
		board     003,"High Speed"              ,MSG_EXP_SERIAL
		board     004,"24 Bit Realtime Digitizer",MSG_EXP_VIDEO
		board     005,"32 Bit Parallel I/O"     ,MSG_EXP_MISC
		board     006,"PIC Prototype"           ,MSG_EXP_MISC
		board     007,"16 Channel ADC"          ,MSG_EXP_MISC
		board     008,"VME-Bus controller"      ,MSG_EXP_INTERFACE
		board     009,"DSP96000 Realtime Data Acquisition",MSG_EXP_MISC
		endmf   02064

		manuf   02065,"California Access"       ;synergy
		board     001,"Malibu"                  ,MSG_EXP_SCSIHD
		endmf   02065

		manuf   02067,"NES Inc."
		board     000,"Expansion RAM"           ,MSG_EXP_RAM
		endmf   02067

		manuf   02071,"ICD"
		board     001,"AdSCSI 2000"             ,MSG_EXP_SCSIHD ;Advantage SCSI
		board     003,"AdIDE"                   ,MSG_EXP_IDEHD
		board     004,"AdRAM 2080"              ,MSG_EXP_RAM
		board     035,"Trifecta"                ,MSG_EXP_HD
		board     255,"?"                       ,MSG_EXP_IDEHD
		endmf   02071

		manuf   02073,"Kupke"
		board     001,"Omti"                    ,MSG_EXP_MFMHD  ;Golem
		board     002,"SCSI-II"                 ,MSG_EXP_SCSIHD ;Golem
		board     003,"Golem Box"               ,MSG_EXP_RAM    ;a2x00 2-8MB
		board     004,"030/882 (synchronous)"   ,MSG_EXP_TURBO
		board     005,"030/882 (asynchronous)"  ,MSG_EXP_TURBO
		endmf   02073

		manuf   02076,"Alfa Data"
		board     024,"AlfaRAM"                 ,MSG_EXP_RAM
		endmf   02076

		manuf   02077,"GVP"
		board     009,"A2000-RAM8/2"            ,MSG_EXP_MISC
		board     010,"GVP Series II"           ,MSG_EXP_RAM
		endmf   02077

		manuf   02078,"Interworks Network"
		endmf   02078

		manuf   02080,"Hardital Synthesis"
		board     020,"TQM 68030+68882"         ,MSG_EXP_TURBO
		endmf   02080

		manuf   02088,"Applied Engineering"
		board     016,"DL2000"                  ,MSG_EXP_MODEM
		board     224,"RAM Works"               ,MSG_EXP_RAM
		endmf   02088

		manuf   02092,"BSC"             ;Elaborate Bytes
		boarda    002,"AlfaData","ALF 2"        ,MSG_EXP_SCSIHD
		boarda    003,"AlfaData","ALF 3"        ,MSG_EXP_SCSIHD
	       IFND     _NOFAKES
		board     004,"Oktagon 508"             ,MSG_EXP_SCSIHD
	       ENDC
		boardf    005,f_bsc_005
		board     006,"Tandem AT-2008/508"      ,MSG_EXP_IDEHD
		boarda    007,"AlfaData","Alpha RAM 1200",MSG_EXP_RAM
		board     008,"Memory Master"           ,MSG_EXP_RAM
		board     016,"Multiface II"            ,MSG_EXP_MULTIIO
		board     017,"Multiface"               ,MSG_EXP_MULTIIO
		board     018,"Multiface III"           ,MSG_EXP_MULTIIO
		board     024,"Tandem AT-2008 CD"       ,MSG_EXP_IDEHD
		board     032,"Framebuffer"             ,MSG_EXP_GFX
		board     033,"¡Graffiti"               ,MSG_EXP_GFXRAM
		board     034,"Graffiti"                ,MSG_EXP_GFX
		board     064,"ISDN MasterCard"         ,MSG_EXP_ISDN
		board     065,"ISDN MasterCard II"      ,MSG_EXP_ISDN
		endmf   02092

	       IFND     _NOFAKES
		manuf   02096,"Quadlite Computers Ltd."
		board     011,"Tentacle"                ,MSG_EXP_MULTIIO        ;seit V6.1
		board     013,"NetMaster"               ,MSG_EXP_ETHERNET
		endmf   02096
	       ENDC

		manuf   02099,"VillageTronic"
		board     137,"Ariadne"                 ,MSG_EXP_ETHERNET
		endmf   02099

		manuf   02101,"Phoenix"
		board     033,"ST506 Autoboot"          ,MSG_EXP_MFMHD
		board     034,"SCSI Autoboot"           ,MSG_EXP_SCSIHD
		board     064,"DMX"                     ,MSG_EXP_MISC
		board     190,"Memory Board"            ,MSG_EXP_RAM
		endmf   02101

		manuf   02102,"Advanced Storage Solutions"
		board     001,"Nexus"                   ,MSG_EXP_SCSIHD
		board     008,"Nexus"                   ,MSG_EXP_RAM
		endmf   02102

		manuf   02104,"Impulse"
		board     000,"FireCracker 24 NTSC"     ,MSG_EXP_GFX
		board     001,"FireCracker 24 PAL"      ,MSG_EXP_GFX
		endmf   02104

		manuf   02112,"Interactive Video Systems"  ;IVS (Pacific Peripherals)
		board     002,"GrandSlam PIC 2"         ,MSG_EXP_SCSIHD
		board     004,"GrandSlam PIC 1"         ,MSG_EXP_SCSIHD
		board     016,"OverDrive"               ,MSG_EXP_SCSIHD
		board     048,"TrumpCard Classic"       ,MSG_EXP_SCSIHD
		board     052,"TrumpCard Pro / Grand Slam" ,MSG_EXP_SCSIHD
		board     064,"Meta-4"                  ,MSG_EXP_RAM
		board     191,"Wavetools"               ,MSG_EXP_AUDIO
		board     242,"Vector"                  ,MSG_EXP_SCSIHD
		board     243,"Vector 030/882"          ,MSG_EXP_TURBOANDRAM
		board     244,"Vector"                  ,MSG_EXP_SCSIHD
		endmf   02112

		manuf   02113,"Vector"
		board     227,"Connection"              ,MSG_EXP_MULTIIO
		endmf   02113

		manuf   02114,"Pacific Digital"
		board     002,"Symposium"               ,MSG_EXP_MISC
		endmf   02114

		manuf   02116,"Pacific Digital"
		board     002,"PC-Access"               ,MSG_EXP_MISC
		endmf   02116

		manuf   02117,"XPert ProDev"
		board     001,"¡Visiona"                ,MSG_EXP_GFXRAM
		board     002,"Visiona"                 ,MSG_EXP_GFX
		board     003,"¡Merlin"                 ,MSG_EXP_GFXRAM
		board     004,"Merlin"                  ,MSG_EXP_GFX
		board     201,"Merlin"                  ,MSG_EXP_GFX
		endmf   02117

		manuf   02121,"Hydra Systems"
		board     001,"Amiganet"                ,MSG_EXP_ETHERNET
		endmf   02121

		manuf   02126,"VOB Computersysteme"
		board     001,"Access X"                ,MSG_EXP_HD
		endmf   02126

		manuf   02127,"Sunrize Industries"
		board     001,"AD1012"                  ,MSG_EXP_AUDIO
		board     002,"AD516"                   ,MSG_EXP_AUDIO
		board     003,"DD512"                   ,MSG_EXP_AUDIO
		endmf   02127

		manuf   02128,"Triceratops"
		board     001,"Multiport"               ,MSG_EXP_MULTIIO
		endmf   02128

		manuf   02129,"Applied Magic Inc."
		board     001,"DMI Resolver (TI34010)"  ,MSG_EXP_GFX
		board     002,"Vivid-24"                ,MSG_EXP_GFX
		board     006,"Digital Broadcaster"     ,MSG_EXP_VIDEO
		board     009,"Digital Broadcaster"     ,MSG_EXP_VIDEO
		endmf   02129

		manuf   02142,"GFX-Base"
		board     000,"GDA-1 VRAM"              ,MSG_EXP_GFX
		board     001,"GDA-1"                   ,MSG_EXP_GFX
		endmf   02142

		manuf   02144,"RocTec"
		board     001,"RH 800C"                 ,MSG_EXP_HD
		board     002,"RH 800C"                 ,MSG_EXP_RAM
		endmf   02144

		manuf   02145,"Ingenieurbüro Helfrich" ;(Omega Datentechnik ?)
		board     032,"Rainbow II"              ,MSG_EXP_GFX    ;linux
		board     033,"Rainbow III"             ,MSG_EXP_GFX
		boarda    128,"Kato","Melody MPEG"      ,MSG_EXP_AUDIO
		endmf   02145

		manuf   02146,"Atlantis"
		endmf   02146

		manuf   02148,"Protar"
		endmf   02148

		manuf   02149,"ACS"
		endmf   02149

		manuf   02150,"Software Results Enterpr."   ;(D.Salomon)
		board     001,"Golden Gate 2 Bus+"      ,MSG_EXP_BRIDGE       ;Reine IDE-Busbridge?
		endmf   02150

		manuf   02154,"DJW Micro Systems"
		board     001,"Horizon"                 ,MSG_EXP_GFX
		board     002,"BlackBox"                ,MSG_EXP_GFX
		board     003,"Voyager"                 ,MSG_EXP_GFX
		endmf   02154

		manuf   02157,"Masoboshi"
		boarda    000,"DCE","Viper 520 CD"      ,MSG_EXP_TURBO
		board     003,"MasterCard SC201"        ,MSG_EXP_RAM
		board     004,"MasterCard MC702"        ,MSG_EXP_SCSIIDE
		board     007,"MVD 819"                 ,MSG_EXP_UNKNOWN
		endmf   02157

		manuf   02159,"Mainhattan Data"
		board     001,"A-Team"                  ,MSG_EXP_IDEHD
		endmf   02159

		manuf   02161,"Blue Ribbon"
		board     002,"One Stop Music Shop"     ,MSG_EXP_AUDIO
		endmf   02161

	       IFND     _NOFAKES
		manuf   02163,"DelaComp"
		board     001,"Expansion 2000"          ,MSG_EXP_RAM
		endmf   02163
	       ENDC

		manuf   02167,"VillageTronic"
		board     001,"¡Domino"                 ,MSG_EXP_GFXRAM
		board     002,"Domino"                  ,MSG_EXP_GFX
		board     003,"Domino 16M Prototype"    ,MSG_EXP_GFX    ;linux (vorher ID=002 ???)
		board     011,"¡Picasso II / II+"       ,MSG_EXP_GFXRAM
		board     012,"Picasso II / II+"        ,MSG_EXP_GFX
		board     013,"Picasso II (Segmented Mode)" ,MSG_EXP_GFX
	       IFND     _NOFAKES                ;seit V6.1
		board     020,"¡Picasso IV Z2"          ,MSG_EXP_GFXRAM
	       ENDC
		board     021,"¡Picasso IV Z2"          ,MSG_EXP_GFXRAM
		board     022,"¡Picasso IV Z2"          ,MSG_EXP_GFXRAM
		board     023,"Picasso IV Z2"           ,MSG_EXP_GFX
		board     024,"Picasso IV Z3"           ,MSG_EXP_GFX
		board     201,"Ariadne"                 ,MSG_EXP_ETHERNET
		board     202,"Ariadne II"              ,MSG_EXP_ETHERNET
		endmf   02167

		manuf   02171,"Utilities Unlimited"
		board     021,"Emplant Deluxe"          ,MSG_EXP_MACEMU
		board     032,"Emplant Deluxe"          ,MSG_EXP_MACEMU
		endmf   02171

		manuf   02176,"Amitrix"
		board     001,"?"                       ,MSG_EXP_MULTIIO
		board     002,"CD-RAM (CDTV)"           ,MSG_EXP_RAM
		endmf   02176

		manuf   02181,"ArMax"
		board     000,"oMniBus"                 ,MSG_EXP_GFX
		endmf   02181

		manuf   02189,"ZEUS"
		board     001,"ConneXion"               ,MSG_EXP_ETHERNET
		endmf   02189

		manuf   02191,"NewTek"
		board     000,"VideoToaster"            ,MSG_EXP_VIDEO
		endmf   02191

		manuf   02192,"M-Tech (Germany)"
		board     001,"AT500"                   ,MSG_EXP_IDEHD
		board     003,"68030"                   ,MSG_EXP_TURBO
		board     005,"A1204"                   ,MSG_EXP_RAMFPU
		board     006,"68020i"                  ,MSG_EXP_TURBO
		board     032,"A1200 T68030/42 RTC"     ,MSG_EXP_TURBORAM
		board     033,"Viper MK V / E-Matrix 530" ,MSG_EXP_SCSIHD   ;E-Matrix: IDEHD  TURBORAM?
		board     034,"8 MB"                    ,MSG_EXP_RAM
		board     036,"Viper MK V / E-Matrix 530" ,MSG_EXP_SCSIHD   ;E-Matrix: IDE/SCSI
		endmf   02192

		manuf   02193,"GVP"
		board     001,"EGS 28/24 Spectrum"      ,MSG_EXP_GFX
		board     002,"EGS 28/24 Spectrum"      ,MSG_EXP_GFXRAM
		endmf   02193

		manuf   02194,"ACT"
		board     001,"Apollo A1200"            ,MSG_EXP_RAMFPU
		endmf   02194

		manuf   02195,"Ingenieurbüro Helfrich"
		board     005,"Piccolo"                 ,MSG_EXP_GFXRAM
		board     006,"Piccolo"                 ,MSG_EXP_GFX
		board     007,"Peggy Plus MPEG"         ,MSG_EXP_VIDEO
		board     008,"VideoCruncher"           ,MSG_EXP_VIDEO
		board     010,"Piccolo SD-64"           ,MSG_EXP_GFXRAM
		board     011,"Piccolo SD-64"           ,MSG_EXP_GFX
		endmf   02195

		manuf   02202,"Silicon Studio Ltd."
		board     000,"20bit / 4 channel"       ,MSG_EXP_AUDIO
		board     001,"Digital Multitrack"      ,MSG_EXP_AUDIO
		endmf   02202

		manuf   02203,"MacroSystem USA"
		board     019,"Warp Engine 40xx"        ,MSG_EXP_TURBOSCSIHD
		endmf   02203

		manuf   02206,"Elbox"                   ; Michal Letowski
		; Alle offiziell von Elbox bestätigt!
		board     001,"Elbox 500/2MB"                           , MSG_EXP_RAM
		board     003,"Elbox CDTV/2MB"                          , MSG_EXP_RAM
		board     004,"Elbox CDTV/8MB"                          , MSG_EXP_RAM
		board     006,"Elbox 1200/4MB"                          , MSG_EXP_RAM
		board     007,"Elbox 1200/0-8"                          , MSG_EXP_RAM
		board     008,"FastATA 1200"                            , MSG_EXP_IDEHD
		board     009,"Elbox 1230"                              , MSG_EXP_TURBO
		board     011,"E/Box 1200 Tower"                        , MSG_EXP_MISC
		board     014,"Amiga 1200 E/Box"                        , MSG_EXP_MISC
		board     015,"ScanDoubler/Flickerfixer"                , MSG_EXP_MISC
		board     016,"FastATA 1200 Lite"                       , MSG_EXP_IDEHD
		board     017,"Buffered Interface 4xEIDE'99"            , MSG_EXP_IDEHD
		board     018,"FastATA 1200"                            , MSG_EXP_IDEHD
		board     019,"FastATA 1200 MKII Gold"                  , MSG_EXP_IDEHD
		board     020,"E/Box 4000 + Zorro III/II busboard"      , MSG_EXP_MISC
		board     024,"FastATA 1200 MKII"                       , MSG_EXP_IDEHD
		board     025,"FastATA 4000"                            , MSG_EXP_IDEHD
		board     026,"Zorro IV busboard"                       , MSG_EXP_MISC
		board     028,"Mroocheck PC Mouse Interface"            , MSG_EXP_MISC
		board     029,"FastATA 4000 MKII"                       , MSG_EXP_IDEHD
		board     030,"FastATA Zorro IV"                        , MSG_EXP_IDEHD
		board     031,"Mediator PCI/Zorro IV busboard"          , MSG_EXP_MISC
		board     032,"Mediator PCI 1200 busboard"              , MSG_EXP_MISC
		board     033,"Mediator PCI 4000 Zorro III bridge"      , MSG_EXP_MISC
		board     159,"Mediator PCI Zorro IV memory window"     , MSG_EXP_MISC
		board     160,"Mediator PCI 1200 memory window"         , MSG_EXP_MISC
		endmf   02206

		manuf   02372,"AmigaXL"                         ;direkt von H&P
		board     001,"emulated"                ,MSG_EXP_RAM
		board     002,"emulated"                ,MSG_EXP_HD
		board     003,"emulated"                ,MSG_EXP_RAM
		board     096,"emulated"                ,MSG_EXP_GFX
		endmf   02372

		manuf   02560,"Harms"
		board     016,"030 plus"                ,MSG_EXP_TURBO
		board     019,"Turbo-Jet 1230xi"        ,MSG_EXP_TURBO
		board     208,"3500 Prof. 030/882"      ,MSG_EXP_TURBOANDRAM  ;2-16MB
		endmf   02560

		manuf   02640,"Micronik"
		board     010,"RCA 120"                 ,MSG_EXP_RAM
		endmf   02640

		;manuf   03084,"Team 4"
		;board     012,"Kasmin"                  ,MSG_EXP_GFX    ;sicher ein Fake
		;endmf   03084

		manuf   03855,"Micronik"                ;Mehr kommt wohl noch?!
		board     001,"Infinitiv Z3"            ,MSG_EXP_SCSIHD
		endmf   03855

		manuf   04096,"MegaMicro"
		board     003,"SCRAM 500"               ,MSG_EXP_SCSIHD
		board     004,"SCRAM 500"               ,MSG_EXP_RAM
		endmf   04096

		manuf   04110,"DigiFeX"
		board     010,"Interact"                ,MSG_EXP_ETHERNET
		endmf   04110

		manuf   04136,"Imtronics"       ;(Ronin)
		board     057,"Hurricane 2800 030/882"  ,MSG_EXP_TURBOANDRAM
		board     064,"Kronos II"               ,MSG_EXP_SCSIHD
		board     087,"Hurricane 2800 030/882"  ,MSG_EXP_TURBOANDRAM
		endmf   04136

		manuf   04149,"ProTAR"
		board     051,"?"                       ,MSG_EXP_SCSIHD
		board     052,"?"                       ,MSG_EXP_RAM
		endmf   04149

		manuf   04626,"Individual Computers"
		board     000,"Buddha Flash"            ,MSG_EXP_IDEHD
		board     005,"ISDN Surfer"             ,MSG_EXP_ISDN
		board     023,"X-Surf"                  ,MSG_EXP_ETHERNET
		board     042,"CatWeasel"               ,MSG_EXP_FLOPPY
		endmf   04626

		manuf   04680,"Kupke/Golem"
		board     001,"OMTI HD 3000"            ,MSG_EXP_MFMHD
		endmf   04680

		manuf   04711,"RBM Digitaltechnik"                              ; inoffiziell !!
		board     001,"IOBlix"                  ,MSG_EXP_MULTIIO
		board     002,"IOBlix 1200S"            ,MSG_EXP_SERIAL
		board     003,"IOBlix 1200P"            ,MSG_EXP_PARALLEL
		endmf   04711

		manuf   05000,"ITH"
		board     001,"ISDN-Master II"          ,MSG_EXP_ISDN
		endmf   05000

		manuf   05001,"VMC"
		board     001,"ISDN Blaster Z2"         ,MSG_EXP_ISDN
		board     002,"HyperCOM 4"              ,MSG_EXP_MULTIIO
		board     003,"HyperCOM 3"              ,MSG_EXP_MULTIIO
		board     006,"HyperCOM 4Z+"            ,MSG_EXP_MULTIIO
		board     007,"HyperCOM 3+"             ,MSG_EXP_MULTIIO
		boarda    015,"Michael Böhmer", "ICY"   ,MSG_EXP_INTERFACE
		endmf   05001

	       IFND     _NOFAKES                ;Seit V5.1
		manuf   05132,"UAS Interface Ltd."
		board     001,"Miracle"                 ,MSG_EXP_MULTIIO
		board     002,"Magic"                   ,MSG_EXP_GFX
		board     130,"Magic (Prototype)"       ,MSG_EXP_GFX
		endmf   05132
	       ENDC

		manuf   05500,"Information"
		board     100,"ISDN Engine I"           ,MSG_EXP_ISDN
		endmf   05500

;                manuf   05768,"Bio-Con"
;                board     137,"BC-1208MA"               ,MSG_EXP_UNKNOWN
;                endmf   05768

		manuf   06148,"HK-Computer"
		board     000,"Vector"                  ,MSG_EXP_RAM
		endmf   06148

		manuf   08215,"Vortex"
		board     003,"Athlet"                  ,MSG_EXP_IDEHD
		board     007,"Golden Gate 80386SX"     ,MSG_EXP_BRIDGE
		board     008,"Golden Gate 80386SX"     ,MSG_EXP_RAM
		board     009,"Golden Gate 80486"       ,MSG_EXP_BRIDGE
		endmf   08215

		manuf   08244,"Spirit"
		board     003,"InBoard"                 ,MSG_EXP_MISC
		endmf   08244

		manuf   08290,"Expansion Systems"
		board     001,"DataFlyer"               ,MSG_EXP_SCSIHD
		board     002,"¡DataFlyer"              ,MSG_EXP_RAM
		endmf   08290

		manuf   08448,"ReadySoft"
		board     001,"AMax II/IV"              ,MSG_EXP_MACEMU
		endmf   08448

		manuf   08512,"Phase 5"
		board     001,"Blizzard 1-8MB"          ,MSG_EXP_RAM
		board     002,"Blizzard"                ,MSG_EXP_TURBO
		board     006,"Blizzard 1220-IV"        ,MSG_EXP_TURBO
		board     010,"FastLane Z3"             ,MSG_EXP_RAM
		boardf    011,f_phase5_011
		boardf    012,f_phase5_012
		board     013,"§Blizzard 12§30"         ,MSG_EXP_TURBO  ; Blizzard 1230-I -II -III
		boardf    017,f_phase5_017
		boardf    024,f_phase5_024
		board     025,"§CyberStorm '0§60 MK-II" ,MSG_EXP_FLASHROM
		board     034,"CyberVision 64"          ,MSG_EXP_GFX
		board     050,"CyberVision 3D Prototype",MSG_EXP_GFX
		board     067,"CyberVision 3D"          ,MSG_EXP_GFX
		board     068,"CyberVision PPC"         ,MSG_EXP_GFX
		boardf    100,f_phase5_100
		board     110,"Blizzard PPC"            ,MSG_EXP_TURBOSCSIHD
		endmf   08512

		manuf   08553,"DPS"
		board     001,"Personal Animation Recorder",MSG_EXP_VIDEO
		endmf   08553

		manuf   08704,"ACT"
		boardf    000,f_act_000
		boarda    001,"Sang/C'T","Transputer Link",MSG_EXP_INTERFACE
		endmf   08704

		manuf   08738,"ACT"
		board     034,"AT-Apollo"               ,MSG_EXP_UNKNOWN
		boardf    035,f_apollo_035
		endmf   08738

		manuf   09512,"Tower Technologies"
		board     000,"ZetaCom Z2 Prototype"    ,MSG_EXP_MULTIIO
		board     001,"ZetaCom Z2"              ,MSG_EXP_MULTIIO
		endmf   09512

		manuf   09999,"QuikPak"
		board     022,"A40§60T 680§60"          ,MSG_EXP_TURBO
		endmf   09999

		manuf   10676,"Electronic Design"
		board     001,"Frame Machine"           ,MSG_EXP_VIDEO
		board     136,"ZIP"                     ,MSG_EXP_RAM
		endmf   10676

		manuf   14501,"Petsoff LP"
		board     000,"Delfina DSP"             ,MSG_EXP_DSP
		board     001,"Delfina DSP Lite"        ,MSG_EXP_DSP
		board     002,"Delfina DSP Plus"        ,MSG_EXP_DSP
		endmf   14501

		manuf   16375,"Uwe Gerlach"
		board     212,"RAM/ROM"                 ,MSG_EXP_MISC
		endmf   16375

		manuf   16707,"Atéo Concepts"
		board     252,"AtéoBus (IO)"            ,MSG_EXP_BUSBRIDGE
		board     253,"¡AtéoBus (Memory)"       ,MSG_EXP_BUSBRIDGE
		board     254,"Pixel64"                 ,MSG_EXP_GFX
		board     255,"¡Pixel64"                ,MSG_EXP_GFXRAM
		endmf   16707

		manuf   16945,"A.C.T."                          ;Albrecht Computer Technik
		board     001,"Prelude"                 ,MSG_EXP_AUDIO
		endmf   16945

		manuf   17440,"HK Computer"                     ; Vector ??
		board     000,"Vector"                  ,MSG_EXP_RAM
		boarda    001,"Elsat","E1204"           ,MSG_EXP_TURBOANDRAM
		endmf   17440

		manuf   18260,"MacroSystem Germany"
		board     003,"Maestro"                 ,MSG_EXP_AUDIO
		board     004,"VLab"                    ,MSG_EXP_VIDEO
		board     005,"MaestroPro"              ,MSG_EXP_AUDIO
		board     006,"Retina"                  ,MSG_EXP_GFX
		board     008,"MultiEvolution"          ,MSG_EXP_SCSIHD
		board     012,"Toccata"                 ,MSG_EXP_AUDIO
	       IFND     _NOFAKES                ;Seit V5.1
		board     013,"ToccataPro"              ,MSG_EXP_AUDIO
	       ENDC
		board     016,"Retina Z3"               ,MSG_EXP_GFX
		board     018,"VLab-Motion"             ,MSG_EXP_VIDEO
		board     019,"DraCo Altais"            ,MSG_EXP_GFX
		board     023,"DraCo Motion"            ,MSG_EXP_VIDEO
		board     253,"Falcon '040"             ,MSG_EXP_TURBO
		endmf   18260

		manuf   19796,"Markt & Technik"
		board     042,"RAM/ROM"                 ,MSG_EXP_MISC
		endmf   19796

		manuf   22359,"Markt & Technik"
		board     137,"Videotext decoder"       ,MSG_EXP_MISC
		endmf   22359

		manuf   26470,"Combitec"
		board     018,"?"                       ,MSG_EXP_RAM    ;MID=26464 ?
		board     130,"?"                       ,MSG_EXP_RAM
		endmf   26470

	;ACHTUNG: es muß mindestens ein Manufacturer mit ID > 32767 existieren
		manuf   32768,"SKI Peripherals"
		board     008,"M.A.S.T. Fireball"       ,MSG_EXP_SCSIHD
		board     128,"SCSI / Dual Serial"      ,MSG_EXP_MISC
		endmf   32768

		manuf   43437,"Reis-Ware"
		board     017,"Scan King"               ,MSG_EXP_SCANIF
		endmf   43437

		manuf   43521,"Cameron"
		board     016,"Personal"                ,MSG_EXP_SCANIF ;Personal a4 / 1 Bit Handscanner
		endmf   43521

		manuf   43537,"Reis-Ware"
		board     017,"Handyscanner"            ,MSG_EXP_SCANIF
		endmf   43537

		manuf   46504,"Phoenix"
		board     033,"ST506 Autoboot"          ,MSG_EXP_MFMHD
		board     034,"SCSI Autoboot"           ,MSG_EXP_SCSIHD
		board     064,"DMX"                     ,MSG_EXP_MISC
		board     190,"Memory"                  ,MSG_EXP_RAM
		endmf   46504

		manuf   49160,"Combitec"
		board     042,"?"                       ,MSG_EXP_HD
		board     043,"SRAM Card"               ,MSG_EXP_RAM
		endmf   49160

		manuf   63524,"Inverted Prototype ID"
		endmf   63524

		manuf   63525,"2-complement Prototype ID"
		endmf   63525,END

		SAVE
		SECTION strings,DATA
		IFGT    (*-strbase)-32767       ;Kein Offset-Überlauf?
		  FAIL  "** ID_Expansions.s: Namenstabelle zu lang!!!"
		ENDC
		RESTORE

		SECTION text,CODE

*-------------------------------------------------------*
* Name:         f_gvp_011                               *
*                                                       *
* Funktion:     GVP (02017) ID 011                      *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
gvpepclist      gvpinit
		gvpepc  $20,"G-Force '040"              ,MSG_EXP_TURBO
		gvpepc  $30,"G-Force '040"              ,MSG_EXP_TURBOSCSIHD
		gvpepc  $40,"A1291"                     ,MSG_EXP_SCSIHD
		gvpepc  $60,"Combo '030 R4"             ,MSG_EXP_TURBO
		gvpepc  $70,"Combo '030 R4"             ,MSG_EXP_TURBOSCSIHD
		gvpepc  $78,"Phone Pak"                 ,MSG_EXP_UNKNOWN
	       IFND     _NOFAKES
		gvpepc  $80,"IO-Extender"               ,MSG_EXP_MULTIIO
	       ENDC
		gvpepc  $98,"IO-Extender"               ,MSG_EXP_MULTIIO
		gvpepc  $a0,"G-Force '030"              ,MSG_EXP_TURBO
		gvpepc  $b0,"G-Force '030"              ,MSG_EXP_TURBOSCSIHD
		gvpepc  $c0,"A530"                      ,MSG_EXP_TURBO
		gvpepc  $d0,"A530"                      ,MSG_EXP_TURBOSCSIHD
		gvpepc  $e0,"Combo '030 R3"             ,MSG_EXP_TURBO
		gvpepc  $f0,"Combo '030 R3"             ,MSG_EXP_TURBOSCSIHD
gvpepcfix       gvpepc  $f8,"Impact Series II"          ,MSG_EXP_SCSIHD
		gvpend
*>
f_gvp_011       move.l  a5,d0                   ;A5 vorhanden?
		beq     .fix
	;-- Welcher Typ? -----------------------;
		move.l  (cd_BoardAddr,a5),a1    ;^Config Area berechnen
		add.l   #$8000,a1
		move.b  (1,a1),d0
		and     #GVP_EPCMASK,d0         ;Maske
	;-- GVP-EPC-Liste durchsuchen ----------;
		lea     (gvpepclist,PC),a2      ;EPC-Liste
.loop           sub.b   (a2)+,d0                ;Code holen
		beq     .found
		bcs     .fix
		addq.l  #gvp_SIZEOF-1,a2        ;Nächstes Board
		bra     .loop
	;-- GVP-EPC-Eintrag gefunden -----------;
.found          moveq   #0,d0
		move.b  (a2)+,d0                ;Type-ID
		add.l   #MSG_EXP_UNKNOWN-1,d0
		move    (a2),d1
		lea     (a4,d1.w),a1            ;String
		rts                             ;Fertig
	;-- Fixen Eintrag ----------------------;
.fix            lea     (gvpepcfix+1,PC),a2
		bra     .found
*<
*-------------------------------------------------------*
* Name:         f_phase5_011                            *
*                                                       *
* Funktion:     Phase 5 (08512) ID 011                  *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  blizz1230ii, "§Blizzard 1230-II" , MSG_EXP_TURBO
		defstr  fastlane,    "FastLane Z3"      , MSG_EXP_SCSIHD
		defstr  cyberscsi,   "CyberSCSI"        , MSG_EXP_SCSIHD
		defstr  cyber040,    "§CyberStorm 0§40"   , MSG_EXP_TURBO
*>
f_phase5_011    move.l  a5,d0                   ;A5 vorhanden?
		beq     .fastlane
	;-- Welcher Typ? -----------------------;
		move.l  (cd_BoardAddr,a5),a1    ;Welcher Typ?
		move.b  (cd_Rom+er_Type,a5),d1
		and.b   #ERT_TYPEMASK,d1
		cmp.b   #ERT_ZORROIII,d1
		beq     .fastlanecyber
	;-- Cyberstorm 040? --------------------;
		move.l  (execbase,PC),a1
		move    (AttnFlags,a1),d1
		btst    #AFB_68040,d1           ;040er vorhanden?
		bne     .cyber040               ; dann wirds ein 040er MK-I sein
	;-- Blizzard 1230 ----------------------;
		lea     (str_blizz1230ii,a4),a1 ;Blizzard
		move.l  #typ_blizz1230ii,d0     ;Turbo
		bra     .done
	;-- CyberStorm 040 ---------------------;
.cyber040       lea     (str_cyber040,a4),a1    ;Cyber
		move.l  #typ_cyber040,d0        ;Turbo
		bra     .done
	;-- Fastlane oder CyberSCSI ------------;
.fastlanecyber  bsr     NameFromNode            ;Handler-Node ermitteln
		beq     .cyberscsi
		move.l  d0,a1
		cmp.b   #"z",(a1)+
		bne     .cyberscsi
		cmp.b   #"3",(a1)
		bne     .cyberscsi
	;-- Fastlane ---------------------------;
.fastlane       lea     (str_fastlane,a4),a1    ;Fastlane
		move.l  #typ_fastlane,d0
		bra     .done
	;-- CyberSCSI --------------------------;
.cyberscsi      lea     (str_cyberscsi,a4),a1   ;CyberSCSI
		move.l  #typ_cyberscsi,d0       ;SCSI-HD
	;-- Fertig -----------------------------;
.done           rts
*<
*-------------------------------------------------------*
* Name:         f_phase5_012                            *
*                                                       *
* Funktion:     Phase 5 (08512) ID 012                  *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  blizz1220,   "Blizzard 1220"    , MSG_EXP_TURBO
		defstr  cybfastscsi, "CyberStorm"       , MSG_EXP_SCSIHD
*>
f_phase5_012    move.l  a5,d0                   ;A5 vorhanden?
		beq     .blizz1220
	;-- Welcher Typ? -----------------------;
		move.l  (execbase,PC),a1
		move    (AttnFlags,a1),d1
		btst    #AFB_68020,d1           ;020er vorhanden?
		beq     .cyberstorm
		btst    #AFB_68030,d1           ;keine 68030+ vorhanden?
		bne     .cyberstorm
	;-- Blizzard 1230-IV -------------------;
.blizz1220      lea     (str_blizz1220,a4),a1   ;Blizzard
		move.l  #typ_blizz1220,d0       ;Turbo
		bra     .done
	;-- CyberStorm SCSI --------------------;
.cyberstorm     lea     (str_cybfastscsi,a4),a1 ;CyberFastSCSI
		move.l  #typ_cybfastscsi,d0
	;-- Fertig -----------------------------;
.done           rts
*<
*-------------------------------------------------------*
* Name:         f_phase5_017                            *
*                                                       *
* Funktion:     Phase 5 (08512) ID 017                  *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  blizz1230iv, "Blizzard 1230-IV"   , MSG_EXP_TURBO
		defstr  blizz1240,   "Blizzard 1240T/ERC" , MSG_EXP_TURBO
		defstr  blizz1260,   "Blizzard 1260"      , MSG_EXP_TURBO
*>
f_phase5_017    move.l  a5,d0                   ;A5 vorhanden?
		beq     .bliz060
	;-- Welcher Typ? -----------------------;
		move.l  (execbase,PC),a1
		move    (AttnFlags,a1),d1
		btst    #AFB_68060,d1           ;060er vorhanden?
		bne     .bliz060                ; dann wirds ein 060er sein
		btst    #AFB_68040,d1           ;040er vorhanden?
		bne     .bliz040
	;-- Blizzard 1230-IV -------------------;
		lea     (str_blizz1230iv,a4),a1 ;Blizzard
		move.l  #typ_blizz1230iv,d0     ;Turbo
		bra     .done
	;-- Blizzard 1240 ----------------------;
.bliz040        lea     (str_blizz1240,a4),a1   ;1240
		move.l  #typ_blizz1240,d0
		bra     .done
	;-- Blizzard 1260 ----------------------;
.bliz060        lea     (str_blizz1260,a4),a1   ;1260
		move.l  #typ_blizz1260,d0
	;-- Fertig -----------------------------;
.done           rts
*<
*-------------------------------------------------------*
* Name:         f_phase5_024                            *
*                                                       *
* Funktion:     Phase 5 (08512) ID 024                  *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  blizz2060,   "Blizzard 2060"    , MSG_EXP_TURBOANDRAM
		defstr  blizz2040,   "Blizzard 2040ERC" , MSG_EXP_TURBOANDRAM
*>
f_phase5_024    move.l  a5,d0                   ;A5 vorhanden?
		beq     .bliz060
	;-- Welcher Typ? -----------------------;
		move.l  (execbase,PC),a1
		move    (AttnFlags,a1),d1
		btst    #AFB_68060,d1           ;060er vorhanden?
		bne     .bliz060                ; dann wirds ein 060er sein
	;-- Blizzard 2040 ----------------------;
		lea     (str_blizz2040,a4),a1   ;Blizzard 040
		move.l  #typ_blizz2040,d0       ;Turbo
		bra     .done
	;-- Blizzard 2060 ----------------------;
.bliz060        lea     (str_blizz2060,a4),a1   ;2060
		move.l  #typ_blizz2060,d0
	;-- Fertig -----------------------------;
.done           rts
*<
*-------------------------------------------------------*
* Name:         f_apollo_035                            *
*                                                       *
* Funktion:     Apollo (08738) ID 035                   *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  app1230,     "Apollo 1230"      , MSG_EXP_TURBO
		defstr  app2030,     "Apollo 2030"      , MSG_EXP_TURBO
		defstr  app1240,     "Apollo 1240"      , MSG_EXP_TURBO
		defstr  app1260,     "Apollo 1260"      , MSG_EXP_TURBO
		defstr  app4040,     "Apollo 4040"      , MSG_EXP_TURBO
		defstr  app4060,     "Apollo 4060"      , MSG_EXP_TURBO
*>
f_apollo_035    move.l  a5,d0                   ;A5 vorhanden?
		beq     .app1230
	;-- Welcher Typ? -----------------------;
		move.l  (execbase,PC),a1
		move    (AttnFlags,a1),d1
		btst    #AFB_68060,d1           ;060er vorhanden?
		bne     .app1260
		btst    #AFB_68040,d1           ;040er vorhanden?
		bne     .app1240                ; dann wirds ein 1240er sein
		move    $dff07c,d1              ;ID-Register lesen
		cmp.b   #$f8,d1
		beq     .app1230                ; AGA -> Apollo 1230
	;-- Apollo 1240 ------------------------;
.app1240        bsr     .test1200
		beq     .is_app1240
		lea     (str_app4040,a4),a1     ;Blizzard
		move.l  #typ_app4040,d0         ;Turbo
		bra     .done
.is_app1240     lea     (str_app1240,a4),a1     ;Blizzard
		move.l  #typ_app1240,d0         ;Turbo
		bra     .done
	;-- Apollo 1260 ------------------------;
.app1260        bsr     .test1200
		beq     .is_app1260
		lea     (str_app4060,a4),a1     ;Blizzard
		move.l  #typ_app4060,d0         ;Turbo
		bra     .done
.is_app1260     lea     (str_app1260,a4),a1     ;Blizzard
		move.l  #typ_app1260,d0         ;Turbo
		bra     .done
	;-- Apollo 2030 ------------------------;
.app2030        lea     (str_app2030,a4),a1     ;Blizzard
		move.l  #typ_app2030,d0         ;Turbo
		bra     .done
	;-- Apollo 1230 ------------------------;
.app1230        lea     (str_app1230,a4),a1     ;Blizzard
		move.l  #typ_app1230,d0         ;Turbo
	;-- Fertig -----------------------------;
.done           rts

	;== Testet auf A1200 ===================;
.test1200       movem.l d1/a0-a1,-(SP)
		moveq   #IDHW_SYSTEM,d0
		sub.l   a0,a0
		bsr     IdHardwareNum
		cmp.l   #IDSYS_AMIGA1200,d0
		movem.l (SP)+,d1/a0-a1
		rts
*<
*-------------------------------------------------------*
* Name:         f_dkb_023                               *
*                                                       *
* Funktion:     DKB (02012) ID 023                      *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  dkb060turbo, "WildFire 060"     , MSG_EXP_TURBO
		defstr  dkb060kick , "WildFire 060"     , MSG_EXP_KICKSTART
*>
f_dkb_023       move.l  a5,d0                   ;A5 vorhanden?
		beq     .dkbturbo
	;-- Welcher Typ? -----------------------;
		cmp.l   #512*1024,(cd_BoardSize,a5)
		bne     .dkbturbo
	;-- DKB kickstart ----------------------;
.dkbkick        lea     (str_dkb060kick,a4),a1  ;060er Kickstart
		move.l  #typ_dkb060kick,d0
		bra     .done
	;-- DKB turbo --------------------------;
.dkbturbo       lea     (str_dkb060turbo,a4),a1 ;060er Turbo
		move.l  #typ_dkb060turbo,d0
	;-- Fertig -----------------------------;
.done           rts
*<
*-------------------------------------------------------*
* Name:         f_phase5_100                            *
*                                                       *
* Funktion:     Phase 5 (08512) ID 100                  *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  cyberppc,    "CyberStorm PPC"   ,MSG_EXP_TURBOSCSIHD
		defstr  cybermk3,    "§CyberStorm '0§60 MK-III" ,MSG_EXP_TURBOSCSIHD
*>
f_phase5_100    move.l  a0,-(SP)
		moveq   #IDHW_POWERPC,d0
		sub.l   a0,a0
		bsr     IdHardwareNum
		cmp.l   #IDPPC_NONE,d0
		beq     .mk3
	;-- CyberPPC ---------------------------;
		lea     (str_cyberppc,a4),a1
		move.l  #typ_cyberppc,d0
		bra     .done
	;-- CyberMKIII -------------------------;
.mk3            lea     (str_cybermk3,a4),a1
		move.l  #typ_cybermk3,d0
	;-- Fertig -----------------------------;
.done           move.l  (SP)+,a0
		rts
*<
*-------------------------------------------------------*
* Name:         f_uae_001                               *
*                                                       *
* Funktion:     UAE (02011) ID 001                      *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  uae001, "emulated"     , MSG_EXP_RAM
		defstr2 uae001mf, "UAE"
		defstr  hacker, "?"            , MSG_EXP_SCSIHD
		defstr2 hackermf, "Hacker Inc."
*>
f_uae_001       move.l  a5,d0                   ;a5 vorhanden?
		beq     .hacker
	;-- Welcher Typ? -----------------------;
		bsr     tst_uae
		bne     .hacker
	;-- UAE Emulated -----------------------;
		lea     (str_uae001mf,a4),a0
		lea     (str_uae001,a4),a1
		move.l  #typ_uae001,d0
		bra     .done
	;-- DKB turbo --------------------------;
.hacker         lea     (str_hackermf,a4),a0
		lea     (str_hacker,a4),a1
		move.l  #typ_hacker,d0
	;-- Fertig -----------------------------;
.done           rts
*<
*-------------------------------------------------------*
* Name:         f_act_000                               *
*                                                       *
* Funktion:     UAE (08704) ID 000                      *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  act620, "Apollo A620 68020"     ,MSG_EXP_TURBO
		defstr  sx32,   "SX32 Mk2"              ,MSG_EXP_TURBO
*>
f_act_000       move.l  a5,d0                   ;a5 vorhanden?
		beq     .hacker
	;-- Welcher Typ? -----------------------;
		move.l  a0,a2
		lea     (.cduiname,PC),a1       ;cdui.library
		moveq   #0,d0
		exec    OpenLibrary
		move.l  a2,a0
		tst.l   d0
		beq     .hacker
		move.l  d0,a1
		exec.q  CloseLibrary
		move.l  a2,a0
	;-- SX32 -------------------------------;
		lea     (str_sx32,a4),a1
		move.l  #typ_sx32,d0
		bra     .done
	;-- ACT turbo --------------------------;
.hacker         lea     (str_act620,a4),a1
		move.l  #typ_act620,d0
	;-- Fertig -----------------------------;
.done           rts
.cduiname       dc.b    "cdui.library",0        ;cdui.library (CD32)
		even
*<
*-------------------------------------------------------*
* Name:         f_uae_002                               *
*                                                       *
* Funktion:     UAE (02011) ID 002                      *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  uae002, "emulated"     , MSG_EXP_HD
		defstr2 uae002mf, "UAE"
		defstr  rmf,    "QuickNet QN2000" , MSG_EXP_ETHERNET
		defstr2 rmfmf,  "Resource Management Force"
*>
f_uae_002       move.l  a5,d0                   ;a5 vorhanden?
		beq     .rmf
	;-- Welcher Typ? -----------------------;
		bsr     tst_uae
		bne     .rmf
	;-- UAE Emulated -----------------------;
		lea     (str_uae002mf,a4),a0
		lea     (str_uae002,a4),a1
		move.l  #typ_uae002,d0
		bra     .done
	;-- RMF --------------------------------;
.rmf            lea     (str_rmfmf,a4),a0
		lea     (str_rmf,a4),a1
		move.l  #typ_rmf,d0
	;-- Fertig -----------------------------;
.done           rts
*<

*-------------------------------------------------------*
* Name:         f_bsc_005                               *
*                                                       *
* Funktion:     UAE (02092) ID 005                      *
*                                                       *
* Parameter:    -» a5.l ^ConfigDev oder NULL (!)        *
*               -» a4.l ^strbase                        *
*               -» a3.l ^aktuelle Board-Struktur        *
*               -» a0.l ^Hersteller-Name                *
*               «- d0.l Class-ID                        *
*               «- a1.l ^Board-Name                     *
*               «- a0.l ^Hersteller-Name                *
* Register:     A0,D4-D6 sind TABU!!!                   *
*                                                       *
		defstr  okt2008, "Oktagon 2008"         ,MSG_EXP_SCSIHD
		defstr  okt4008, "Oktagon 4008"         ,MSG_EXP_SCSIHD
*>
f_bsc_005       move.l  a5,d0                   ;a5 vorhanden?
		beq     .o2008
	;-- Welcher Typ? -----------------------;
		move    $dff07c,d1              ;LISAID
		and     #$000F,d1               ; nur die Typ-Bits maskieren
		cmp     #$0008,d1               ;Lisa?
		beq     .o4008
	;-- Oktagon 2008 -----------------------;
.o2008          lea     (str_okt2008,a4),a1
		move.l  #typ_okt2008,d0
		bra     .done
	;-- Oktagon 4008 -----------------------;
.o4008          lea     (str_okt4008,a4),a1
		move.l  #typ_okt4008,d0
	;-- Fertig -----------------------------;
.done           rts
*<



*---------------------------------------------------------------*
*       == HILFSROUTINEN ==                                     *
*                                                               *
tst_uae         movem.l a0-a1,-(SP)
		moveq   #IDHW_SYSTEM,d0
		sub.l   a0,a0
		bsr     IdHardwareNum
		cmp.l   #IDSYS_UAE,d0
		movem.l (SP)+,a0-a1
		rts

*---------------------------------------------------------------*
*       == VARIABLEN ==                                         *
*                                                               *
cpuchar         dc.b    "0"             ;CPU-Zeichen (680x0)
		even

*---------------------------------------------------------------*
*       == ENDE ==                                              *
*                                                               *
		ECHO    "##"
		ECHO    "## Hersteller = ",__GLBMANUF
		ECHO    "## Boards     = ",__GLBBOARD
		ECHO    "##"
		END OF SOURCE
