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

		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/initializers.i
		INCLUDE exec/resident.i
		INCLUDE exec/execbase.i
		INCLUDE exec/memory.i
		INCLUDE libraries/configvars.i
		INCLUDE libraries/commodities.i
		INCLUDE libraries/commodities_private.i
		INCLUDE utility/tagitem.i
		INCLUDE rexx/rxslib.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/rexxsyslib.i
		INCLUDE lvo/identify.i
		INCLUDE lvo/commodities.i
		INCLUDE PhxMacros.i

		INCLUDE libraries/identify.i

		INCLUDE Base.i

		SECTION text,CODE

VERSION         EQU     1               ;<- Version
REVISION        EQU     12              ;<- Revision

SETRELEASE      MACRO
		dc.b    "11"            ;<- Kommando-Release
		ENDM

SETVER          MACRO                   ;<- Version String Macro
		dc.b    "1.12"
		ENDM

SETDATE         MACRO                   ;<- Date String Macro
		dc.b    "08.09.2001"
		ENDM


CXSLOTS         EQU     32              ;Anzahl der Commodity-Slots

*---------------------------------------------------------------*
*	ARexx support library					*
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
libname         dc.b    "rexxidentify.library",0
libidstring     dc.b    "rexxidentify.library "
		SETVER
		dc.b    " ("
		SETDATE
		dc.b    ")",13,10,0

	;-- Informationen für HexReader... -------------;

		dc.b    "rexxidentify.library V"
		SETVER
		dc.b    "  ARexx support for the identify.library  "
		dc.b    "  (C) 1997-2010 Richard Körber   "
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
		dc.l    Query                           ;-30
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
		lea     (.rexxsyslibname,PC),a1 ;rexxsyslib aufmachen
		moveq   #33,d0
		exec    OpenLibrary
		move.l  d0,rexxsyslibbase
		beq     .error1
		lea     (.expansionname,PC),a1  ;expansion aufmachen
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,expbase
		beq     .error2
		lea     (.cxname,PC),a1         ;commodity aufmachen
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,cxbase
		beq     .error3
		lea     (.identifyname,PC),a1   ;identify aufmachen
		moveq   #IDENTIFYVERSION,d0
		exec    OpenLibrary
		move.l  d0,identifybase
		beq     .error4
	;-- Expansion-Liste durchgehen ---------;
		sub.l   a0,a0                   ;Alle Boards durchgehen
		lea     expansions,a2           ;^Expansions
		moveq   #-1,d2                  ;Zähler
.exploop        moveq   #-1,d0
		moveq   #-1,d1
		expans  FindConfigDev
		addq    #1,d2
		move.l  d0,a0                   ;Für's nächste mal
		move.l  d0,(a2)+                ;Merken
		bne     .exploop
		move    d2,expnumbers           ;Anzahl merken
	;-- Fertig -----------------------------;
		move.l  a5,d0
.exit           movem.l (sp)+,d1-d7/a0-a6
		rts
	;-- Error ------------------------------;
.error4         move.l  (cxbase,PC),a1          ;commodity zumachen
		exec    CloseLibrary
.error3         move.l  (expbase,PC),a1         ;expansion zumachen
		exec    CloseLibrary
.error2         move.l  (rexxsyslibbase,PC),a1
		exec    CloseLibrary
.error1         moveq   #0,d0                   ;Keine Libbase -> Error
		bra     .exit
	;-- Strings ----------------------------;
.rexxsyslibname dc.b    "rexxsyslib.library",0
.expansionname  dc.b    "expansion.library",0
.cxname         dc.b    "commodities.library",0
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
		move.l  (cxbase,PC),a1          ;commodity zumachen
		exec    CloseLibrary
		move.l  (expbase,PC),a1         ;Expansion zumachen
		exec    CloseLibrary
		move.l  (rexxsyslibbase,PC),a1  ;Rexx zumachen
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
*-------------------------------------------------------*
* Name:         Query                                   *
*                                                       *
* Funktion:     ARexx-Anfrage                           *
*                                                       *
* Parameter:    -» A0.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
Query           movem.l d1-d7/a1-a6,-(SP)
		move.l  a0,a5                   ;RexxMsg merken
	;-- Kommando suchen --------------------;
		move.l  (rm_Args+0*4,a5),a0     ;Args[0] auslesen
		lea     (.commands,PC),a1       ;Command-Tabelle
		bsr     strtoidx                ;In Index wandeln
		tst.l   d0                      ;Gefunden?
		bmi     .err_program            ;Nein: program not found
	;-- Kommando ausführen -----------------;
		add.l   d0,d0
		add.l   d0,d0
		lea     (.jumptab,PC),a4
		move.l  (a4,d0.l),a4
		jsr     (a4)                    ;Funktion anspringen
	;-- Fertig -----------------------------;
.exit           movem.l (SP)+,d1-d7/a1-a6
		rts
	;-- Fehler -----------------------------;
.err_program    moveq   #1,d0                   ;program not found
		sub.l   a0,a0                   ;Kein Return-String
		bra     .exit

	;-- Funktionstabelle -------------------;
.jumptab        dc.l    ID_Release
		dc.l    ID_Boards
		dc.l    ID_Expansion
		dc.l    ID_Hardware
		dc.l    ID_Function
		dc.l    ID_Alert
		dc.l    ID_ExpName
		dc.l    ID_LockCX
		dc.l    ID_CountCX
		dc.l    ID_GetCX
		dc.l    ID_UnlockCX
		dc.l    ID_Update
	;-- Funktionsnamentabelle --------------;
.commands       dc.b    "ID_RELEASE",0
		dc.b    "ID_NUMBOARDS",0
		dc.b    "ID_EXPANSION",0
		dc.b    "ID_HARDWARE",0
		dc.b    "ID_FUNCTION",0
		dc.b    "ID_ALERT",0
		dc.b    "ID_EXPNAME",0
		dc.b    "ID_LOCKCX",0
		dc.b    "ID_COUNTCX",0
		dc.b    "ID_GETCX",0
		dc.b    "ID_UNLOCKCX",0
		dc.b    "ID_UPDATE",0
		dc.b    0       ;Endmarke
		even
*<

*-------------------------------------------------------*
* Name:         ID_Release                              *
*                                                       *
* Funktion:     Release der Library ermitteln           *
*                                                       *
* Parameter:    -» A5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
; SYNTAX: IDRelease()

ID_Release      lea     (.releasestr,PC),a0
		strln.b a0,d0
		subq.l  #1,d0
		rexxsys CreateArgstring
		move.l  d0,a0
		moveq   #0,d0
		rts
.releasestr     SETRELEASE
		dc.b    " "
		SETVER
		dc.b    "("
		SETDATE
		dc.b    ")",0
		even
*<
*-------------------------------------------------------*
* Name:         ID_Boards                               *
*                                                       *
* Funktion:     Anzahl der Expansion ermitteln          *
*                                                       *
* Parameter:    -» A5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
; SYNTAX: IDBoards()

		clrfo
idb_Buffer      fo.b    20              ;Buffer für String
idb_LENGTH      fo.w    0

ID_Boards       link    a4,#idb_LENGTH
		moveq   #0,d0                   ;Anzahl der Boards
		move    expnumbers,d0
		lea     (idb_Buffer,a4),a0      ;Zielpuffer
		bsr     numtostr
		rexxsys CreateArgstring
		move.l  d0,a0
		moveq   #0,d0
		unlk    a4
		rts
*<
*-------------------------------------------------------*
* Name:         ID_Expansion                            *
*                                                       *
* Funktion:     Expansion ermitteln                     *
*                                                       *
* Parameter:    -» A5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
; SYNTAX: IDExpansion(BoardNr,[MANUF|PROD|CLASS|ADDRESS|SIZE|VALID|SECONDARY|CLASSID|MANUFID|PRODID

		clrfo
ide_Buffer      fo.b    IDENTIFYBUFLEN          ;Buffer für String
ide_ConfigDev   fo.l    1                       ;^ConfigDev
ide_ClassID     fo.l    1                       ;ClassID
ide_LENGTH      fo.w    0

ID_Expansion    link    a4,#ide_LENGTH
	;-- Board-Nummer ermitteln -------------;
		move.l  (rm_Args+1*4,a5),d0     ;Args[1] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay
		tst.b   (a0)                    ;Ende?
		bne     .error
.numokay        moveq   #0,d1                   ;In Range?
		move    expnumbers,d1
		cmp.l   d1,d0
		bhi     .error                  ;Nein!
		add.l   d0,d0
		add.l   d0,d0
		lea     expansions,a0
		move.l  (a0,d0.l),(ide_ConfigDev,a4)
	;-- Welches Ergebnis ist erwünscht? ----;
		move.l  (rm_Args+2*4,a5),d0     ;Args[2] auslesen
		beq     .error
		move.l  d0,a0
		lea     (.results,PC),a1        ;Ergebnistabelle
		bsr     strtoidx
		tst.l   d0                      ;Drin?
		bmi     .error
		subq.l  #3,d0                   ;Was mit Identify?
		bcs     .identify
		subq.l  #1,d0
		bcs     .address
		subq.l  #1,d0
		bcs     .size
		subq.l  #1,d0
		bcs     .shutup
		subq.l  #1,d0
		bcs     .secondary
		subq.l  #1,d0
		bcs     .classid
		subq.l  #1,d0
		bcs     .manufid
		subq.l  #1,d0
		bcs     .prodid
		bra     .error                  ;Sollte nie auftreten
	;---- Adresse --------------------------;
.address        move.l  (ide_ConfigDev,a4),a0
		move.l  (cd_BoardAddr,a0),d0
		lea     (ide_Buffer,a4),a0
		bsr     hextostr
		bra     .result
	;---- Größe ----------------------------;
.size           move.l  (ide_ConfigDev,a4),a0
		move.l  (cd_BoardSize,a0),d0
		lea     (ide_Buffer,a4),a0
		lsr.l   #8,d0
		lsr.l   #2,d0                   ;Trick (Ergebnis in KB)
		bsr     numtostr
		bra     .result
	;---- Shutup ---------------------------;
.shutup         move.l  (ide_ConfigDev,a4),a0
		moveq   #0,d0
		move.b  (cd_Flags,a0),d0
		btst    #CDB_SHUTUP,d0
		sne     d0
		neg.b   d0
		lea     (ide_Buffer,a4),a0
		bsr     numtostr
		bra     .result
	;---- ClassID --------------------------;
.classid        move.l  SP,d7
		pea     TAG_DONE.w
		move.l  (ide_ConfigDev,a4),-(SP)
		pea     IDTAG_ConfigDev         ;IDTAG_ConfigDev,cdev
		pea     (ide_ClassID,a4)
		pea     IDTAG_ClassID
		move.l  SP,a0
		idfy    IdExpansion
		move.l  d7,SP
		lea     (ide_Buffer,a4),a0
		move.l  (ide_ClassID,a4),d0
		bsr     numtostr
		bra     .result
	;---- ManufID --------------------------;
.manufid        move.l  (ide_ConfigDev,a4),a0
		moveq   #0,d0
		move    (cd_Rom+er_Manufacturer,a5),d0
		lea     (ide_Buffer,a4),a0
		bsr     numtostr
		bra     .result
	;---- ProdID ---------------------------;
.prodid         move.l  (ide_ConfigDev,a4),a0
		moveq   #0,d0
		move.b  (cd_Rom+er_Product,a5),d0
		lea     (ide_Buffer,a4),a0
		bsr     numtostr
		bra     .result
	;---- Secondary ------------------------;
.secondary      move.l  SP,d7
		pea     TAG_DONE.w
		move.l  (ide_ConfigDev,a4),-(SP)
		pea     IDTAG_ConfigDev         ;IDTAG_ConfigDev,cdev
		pea     (ide_Buffer,a4)
		pea     IDTAG_ProdStr
		pea     -1.w
		pea     IDTAG_Secondary
		move.l  SP,a0
		idfy    IdExpansion
		move.l  d7,SP
		lea     (.txt_secondary,PC),a0  ;Sekundär?
		cmp.l   #IDERR_SECONDARY,d0
		beq     .result
		lea     (.txt_primary,PC),a0    ;Primär?
		tst.l   d0                      ;alles OK?
		beq     .result
		bra     .error
	;---- IDENTIFY-Ergebnis ----------------;
.identify       move.l  SP,d7
		pea     TAG_DONE.w              ;DONE
		move.l  (ide_ConfigDev,a4),-(SP)
		pea     IDTAG_ConfigDev         ;IDTAG_ConfigDev,cdev
		pea     (ide_Buffer,a4)
		add.l   #IDTAG_ClassStr+1,d0
		move.l  d0,-(SP)                ;~IDTAG_ClassStr,buff
		move.l  SP,a0
		idfy    IdExpansion
		move.l  d7,SP
		tst.l   d0                      ;alles OK?
		bne     .error
		lea     (ide_Buffer,a4),a0
	;-- Ergebnis aufbereiten ---------------;
.result         strln.b a0,d0
		subq.l  #1,d0
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit

	;-- Texte ------------------------------;
.txt_primary    dc.b    "Primary",0
.txt_secondary  dc.b    "Secondary",0
		even

	;-- Ergebnisse -------------------------;
.results        dc.b    "MANUF",0
		dc.b    "PROD",0
		dc.b    "CLASS",0
		dc.b    "ADDRESS",0
		dc.b    "SIZE",0
		dc.b    "SHUTUP",0
		dc.b    "SECONDARY",0
		dc.b    "CLASSID",0
		dc.b    "MANUFID",0
		dc.b    "PRODID",0
		dc.b    0
		even
*<
*-------------------------------------------------------*
* Name:         ID_ExpName                              *
*                                                       *
* Funktion:     Expansion ermitteln nach IDs            *
*                                                       *
* Parameter:    -» A5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
; SYNTAX: IDExpName(ManufID,BoardID,[MANUF|PROD|CLASS])

		clrfo
idn_Buffer      fo.b    IDENTIFYBUFLEN          ;Buffer für String
idn_ManufID     fo.l    1
idn_ProdID      fo.l    1
idn_LENGTH      fo.w    0

ID_ExpName      link    a4,#idn_LENGTH
	;-- Manuf-Nummer ermitteln -------------;
		move.l  (rm_Args+1*4,a5),d0     ;Args[1] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay
		tst.b   (a0)                    ;Ende?
		bne     .error
.numokay        cmp.l   #65535,d0               ;Manuf < 65536
		bhi     .error
		move.l  d0,(idn_ManufID,a4)
	;-- Board-Nummer ermitteln -------------;
		move.l  (rm_Args+2*4,a5),d0     ;Args[2] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay2
		tst.b   (a0)                    ;Ende?
		bne     .error
.numokay2       cmp.l   #255,d0                 ;Prod < 256
		bhi     .error
		move.l  d0,(idn_ProdID,a4)
	;-- Welches Ergebnis ist erwünscht? ----;
		move.l  (rm_Args+3*4,a5),d0     ;Args[3] auslesen
		beq     .error
		move.l  d0,a0
		lea     (.results,PC),a1        ;Ergebnistabelle
		bsr     strtoidx
		tst.l   d0                      ;Drin?
		bmi     .error
	;---- IDENTIFY-Ergebnis ----------------;
		move.l  SP,d7
		pea     TAG_DONE.w              ;DONE
		move.l  (idn_ProdID,a4),-(SP)
		pea     IDTAG_ProdID
		move.l  (idn_ManufID,a4),-(SP)
		pea     IDTAG_ManufID
		pea     (idn_Buffer,a4)
		add.l   #IDTAG_ManufStr,d0
		move.l  d0,-(SP)                ;~IDTAG_ClassStr,buff
		move.l  SP,a0
		idfy    IdExpansion
		move.l  d7,SP
		tst.l   d0                      ;alles OK?
		bne     .error
		lea     (idn_Buffer,a4),a0
	;-- Ergebnis aufbereiten ---------------;
.result         strln.b a0,d0
		subq.l  #1,d0
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit

	;-- Ergebnisse -------------------------;
.results        dc.b    "MANUF",0
		dc.b    "PROD",0
		dc.b    "CLASS",0
		dc.b    0
		even
*<
*-------------------------------------------------------*
* Name:         ID_Hardware                             *
*                                                       *
* Funktion:     Hardwarestring ermitteln                *
*                                                       *
* Parameter:    -» a5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
;SYNTAX: IDHARDWARE [SYSTEM|CPU|FPU|MMU|...],{EMPTYNA},{NOLOCALE}

		clrfo
idh_EmptyNA     fo.b    1                       ;-1: leerer String bei NA
idh_Nolocale    fo.b    1                       ;-1: no locale
idh_Buffer      fo.b    IDENTIFYBUFLEN          ;Buffer für String
idh_LENGTH      fo.w    0

ID_Hardware     link    a4,#idh_LENGTH
	;-- Welche Optionen sind erwünscht? ----;
		sf      (idh_EmptyNA,a4)
		sf      (idh_Nolocale,a4)
		move.l  (rm_Action,a5),d1       ;Action code
		lea     (rm_Args+2*4,a5),a3     ;Args[2] holen
.optloop        subq.b  #1,d1                   ;max. 12 Parameter
		beq     .nona
		move.l  (a3)+,d0                ;Arg auslesen
		beq     .optloop
		move.l  d0,a0
		lea     (.options,PC),a1        ;Ergebnistabelle
		bsr     strtoidx
		tst.l   d0                      ;Drin?
		bmi     .error
		subq.l  #1,d0                   ;EMPTYNA?
		bcs     .emptyna
		subq.l  #1,d0                   ;NOLOCALE?
		bcs     .nolocale
		bra     .optloop
.emptyna        st      (idh_EmptyNA,a4)
		bra     .optloop
.nolocale       st      (idh_Nolocale,a4)
		bra     .optloop
.nona
	;-- Welches Ergebnis ist erwünscht? ----;
		move.l  (rm_Args+1*4,a5),d0     ;Args[1] auslesen
		beq     .error
		move.l  d0,a0
		lea     (.results,PC),a1        ;Ergebnistabelle
		bsr     strtoidx
		tst.l   d0                      ;Drin?
		bmi     .error
	;-- Berechnen --------------------------;
		move.l  SP,a3
		pea     TAG_DONE.w
		tst.b   (idh_EmptyNA,a4)        ;EmptyNA
		beq     .tag_empty
		pea     TRUE.w
		pea     IDTAG_NULL4NA
.tag_empty
		tst.b   (idh_Nolocale,a4)       ;Locale
		beq     .tag_localize
		pea     FALSE.w
		pea     IDTAG_Localize
.tag_localize
		move.l  SP,a0
		idfy    IdHardware
		move.l  a3,SP
		move.l  d0,a0
		tst.l   d0                      ;NULL?
		bne     .non_null
		lea     (.nullstr,PC),a0
.non_null       strln.b a0,d0
		subq.l  #1,d0
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit

	;-- Ergebnistypen ----------------------;
.results        dc.b    "SYSTEM",0
		dc.b    "CPU",0
		dc.b    "FPU",0
		dc.b    "MMU",0
		dc.b    "OSVER",0
		dc.b    "EXECVER",0
		dc.b    "WBVER",0
		dc.b    "ROMSIZE",0
		dc.b    "CHIPSET",0
		dc.b    "GFXSYS",0
		dc.b    "CHIPRAM",0
		dc.b    "FASTRAM",0
		dc.b    "RAM",0
		dc.b    "SETPATCHVER",0
		dc.b    "AUDIOSYS",0
		dc.b    "OSNR",0
		dc.b    "VMMCHIPRAM",0
		dc.b    "VMMFASTRAM",0
		dc.b    "VMMRAM",0
		dc.b    "PLNCHIPRAM",0
		dc.b    "PLNFASTRAM",0
		dc.b    "PLNRAM",0
		dc.b    "VBR",0
		dc.b    "LASTALERT",0
		dc.b    "VBLANKFREQ",0
		dc.b    "POWERFREQ",0
		dc.b    "ECLOCK",0
		dc.b    "SLOWRAM",0
		dc.b    "GARY",0
		dc.b    "RAMSEY",0
		dc.b    "BATTCLOCK",0
		dc.b    "CHUNKYPLANAR",0
		dc.b    "POWERPC",0
		dc.b    "PPCCLOCK",0
		dc.b    "CPUREV",0
		dc.b    "CPUCLOCK",0
		dc.b    "FPUCLOCK",0
		dc.b    "RAMACCESS",0
		dc.b    "RAMWIDTH",0
		dc.b    "RAMCAS",0
		dc.b    "RAMBANDWIDTH",0
		dc.b    "TCPIP",0
		dc.b    "PPCOS",0
		dc.b    "AGNUS",0
		dc.b    "AGNUSMODE",0
		dc.b    "DENISE",0
		dc.b    "DENISEREV",0
		dc.b    "BOINGBAG",0
		dc.b    "EMULATED",0
		dc.b    "XLVERSION",0
		dc.b    "HOSTOS",0
		dc.b    "HOSTVERS",0
		dc.b    "HOSTMACHINE",0
		dc.b    "HOSTCPU",0
		dc.b    "HOSTSPEED",0
		dc.b    0
.options        dc.b    "EMPTYNA",0
		dc.b    "NOLOCALE",0
		dc.b    0
.nullstr        dc.b    0
		even
*<
*-------------------------------------------------------*
* Name:         ID_Function                             *
*                                                       *
* Funktion:     Funktionsnamen ermitteln                *
*                                                       *
* Parameter:    -» a5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
;SYNTAX: IDFUNCTION(LibName,Offset)

		clrfo
idf_Buffer      fo.b    IDENTIFYBUFLEN          ;Buffer für String
idf_LENGTH      fo.w    0

ID_Function     link    a4,#idf_LENGTH
	;-- Offset ermitteln -------------------;
		move.l  (rm_Args+2*4,a5),d0     ;Args[2] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay
		tst.b   (a0)                    ;Ende?
		bne     .error
	;-- Ergebnis berechnen -----------------;
.numokay        ;D0: Offset-Nummer
		move.l  (rm_Args+1*4,a5),d1     ;Args[1] auslesen
		beq     .error
		move.l  d1,a0                   ;Libraryname
		pea     TAG_DONE.w
		pea     (idf_Buffer,a4)
		pea     IDTAG_FuncNameStr
		move.l  SP,a1
		idfy    IdFunction
		add.l   #3*4,SP
		tst.l   d0
		bne     .error
		lea     (idf_Buffer,a4),a0
		strln.b a0,d0
		subq.l  #1,d0
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit
*<
*-------------------------------------------------------*
* Name:         ID_Alert                                *
*                                                       *
* Funktion:     Alerts ermitteln                        *
*                                                       *
* Parameter:    -» A5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
; SYNTAX: IDAlert(Code,[DEAD|SUBSYS|GENERAL|SPEC])

		clrfo
ida_Buffer      fo.b    IDENTIFYBUFLEN          ;Buffer für String
ida_LENGTH      fo.w    0

ID_Alert        link    a4,#ida_LENGTH
	;-- Code ermitteln ---------------------;
		move.l  (rm_Args+1*4,a5),d0     ;Args[1] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtohex
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay
		tst.b   (a0)                    ;Ende?
		bne     .error
.numokay        move.l  d0,d6                   ;Merken
	;-- Welches Ergebnis ist erwünscht? ----;
		move.l  (rm_Args+2*4,a5),d0     ;Args[2] auslesen
		beq     .error
		move.l  d0,a0
		lea     (.results,PC),a1        ;Ergebnistabelle
		bsr     strtoidx
		tst.l   d0                      ;Drin?
		bmi     .error
	;-- Ergebnis berechnen -----------------;
		move.l  SP,d7
		pea     TAG_DONE.w              ;DONE
		pea     (ide_Buffer,a4)
		add.l   #IDTAG_DeadStr,d0
		move.l  d0,-(SP)                ;~IDTAG_DeadStr,buff
		move.l  SP,a0
		move.l  d6,d0
		idfy    IdAlert
		move.l  d7,SP
		tst.l   d0                      ;alles OK?
		bne     .error
		lea     (ide_Buffer,a4),a0
	;-- Ergebnis aufbereiten ---------------;
.result         strln.b a0,d0
		subq.l  #1,d0
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit

	;-- Ergebnisse -------------------------;
.results        dc.b    "DEAD",0
		dc.b    "SUBSYS",0
		dc.b    "GENERAL",0
		dc.b    "SPEC",0
		dc.b    0
		even
*<
*-------------------------------------------------------*
* Name:         ID_LockCX                               *
*                                                       *
* Funktion:     Ein Commodity-Slot belegen              *
*                                                       *
* Parameter:    -» A5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
; SYNTAX: IDLockCX()

		clrfo
idlcx_Slot      fo.l    1                       ;Slot-Nummer
idlcx_Buffer    fo.b    20                      ;Buffer für String
idlcx_LENGTH    fo.w    0

ID_LockCX       link    a4,#idlcx_LENGTH
	;-- Slot suchen ------------------------;
		moveq   #0,d1                   ;Slot-Nr.
		moveq   #CXSLOTS-1,d0           ;Anzahl
		lea     cxslots,a0              ;^Slots
.find           tst.l   (a0)                    ;Leer?
		beq     .found
		add.l   #MLH_SIZE,a0            ;Nächste Liste
		inc.l   d1
		dbra    d0,.find
		bra     .error                  ;Kein Slot mehr frei!
.found          move.l  d1,(idlcx_Slot,a4)
		NEWLIST a0                      ;a0: Neue Liste erzeugen
		cx      CopyBrokerList          ;Brokerliste holen
	;-- Ergebnis aufbereiten ---------------;
		move.l  (idlcx_Slot,a4),d0
		lea     (idlcx_Buffer,a4),a0    ;Zielpuffer
		bsr     numtostr
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit
*<
*-------------------------------------------------------*
* Name:         ID_CountCX                              *
*                                                       *
* Funktion:     Commodities in der Liste zählen         *
*                                                       *
* Parameter:    -» a5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. August 1997, 15:08:40)         *
*                                                       *
;SYNTAX: IDCOUNTCX(Slot)

		clrfo
idccx_Buffer    fo.b    20                      ;Buffer für String
idccx_LENGTH    fo.w    0

ID_CountCX      link    a4,#idccx_LENGTH
	;-- Offset ermitteln -------------------;
		move.l  (rm_Args+1*4,a5),d0     ;Args[1] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay
		tst.b   (a0)                    ;Ende?
		bne     .error
	;-- Ergebnis berechnen -----------------;
.numokay        ;d0: Offset-Nummer
		cmp.l   #CXSLOTS,d0             ;Im Bereich?
		bhs     .error                  ; nee... Raus!
		mulu    #MLH_SIZE,d0            ;List-Header ermitteln
		lea     cxslots,a0              ;Slots in a0
		add.l   d0,a0                   ;+ Header
		tst.l   (a0)                    ;belegt?
		beq     .error                  ; nee... Raus!
		moveq   #-1,d0                  ;Count
.loop           move.l  (a0),a0                 ;erste Node
		addq.l  #1,d0                   ;eine mehr
		tst.l   (a0)                    ;Ende?
		bne     .loop
		lea     (idccx_Buffer,a4),a0    ;Zielpuffer
		bsr     numtostr
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit
*<
*-------------------------------------------------------*
* Name:         ID_GetCX                                *
*                                                       *
* Funktion:     Commodity-Eintrag lesen                 *
*                                                       *
* Parameter:    -» a5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. August 1997, 15:08:40)         *
*                                                       *
;SYNTAX: IDGETCX(Slot,Nr,[NAME|TITLE|DESC|GUI|ACTIVE])

		clrfo
idgcx_List      fo.l    1                       ;^Liste des Slots
idgcx_Buffer    fo.b    20                      ;Buffer für String
idgcx_LENGTH    fo.w    0

ID_GetCX        link    a4,#idgcx_LENGTH
	;-- Slot ermitteln ---------------------;
		move.l  (rm_Args+1*4,a5),d0     ;Args[1] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay
		tst.b   (a0)                    ;Ende?
		bne     .error
.numokay        ;d0: Slot
		cmp.l   #CXSLOTS,d0             ;Im Bereich?
		bhs     .error                  ; nee... Raus!
		mulu    #MLH_SIZE,d0            ;List-Header ermitteln
		lea     cxslots,a0              ;Slots in a0
		add.l   d0,a0                   ;+ Header
		tst.l   (a0)                    ;belegt?
		beq     .error                  ; nee... Raus!
		move.l  a0,(idgcx_List,a4)
	;-- Node ermitteln ---------------------;
		move.l  (rm_Args+2*4,a5),d0     ;Args[2] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay2
		tst.b   (a0)                    ;Ende?
		bne     .error
.numokay2       ;d0: Node
		move.l  (idgcx_List,a4),a0      ;Liste
.loop           move.l  (a0),a0                 ;erste/nächste Node
		tst.l   (a0)                    ;Liste zu ende?
		beq     .error                  ;  dann war's nichts
		dec.l   d0                      ;Eine Node weniger
		bcc     .loop                   ;  noch weitersuchen
		move.l  a0,a3                   ;Node merken
	;-- Welches Ergebnis ist erwünscht? ----;
		move.l  (rm_Args+3*4,a5),d0     ;Args[3] auslesen
		beq     .error
		move.l  d0,a0
		lea     (.results,PC),a1        ;Ergebnistabelle
		bsr     strtoidx
		dec.l   d0                      ;name?
		bcs     .name
		dec.l   d0                      ;title?
		bcs     .title
		dec.l   d0                      ;description?
		bcs     .desc
		dec.l   d0                      ;shown?
		bcs     .shown
		dec.l   d0                      ;active?
		bcs     .active
		bra     .error
	;-- Name -------------------------------;
.name           lea     (bc_Name,a3),a0
		bra     .result
	;-- Title ------------------------------;
.title          lea     (bc_Title,a3),a0
		bra     .result
	;-- Descr ------------------------------;
.desc           lea     (bc_Descr,a3),a0
		bra     .result
	;-- Shown ------------------------------;
.shown          move    (bc_Flags,a3),d0        ;Flags testen
		and     #COF_SHOW_HIDE,d0
		beq     .false
		bra     .true
	;-- Active -----------------------------;
.active         move    (bc_Flags,a3),d0        ;Flags testen
		and     #COF_ACTIVE,d0
		beq     .false
		bra     .true
	;-- TRUE -------------------------------;
.true           lea     (.truestr,PC),a0
		bra     .result
	;-- FALSE ------------------------------;
.false          lea     (.falsestr,PC),a0
	;-- Ergebnis ausgeben ------------------;
.result         strln.b a0,d0
		subq.l  #1,d0
		rexxsys CreateArgstring
		move.l  d0,a0                   ;Ergebnis hier
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit

	;-- Ergebnistypen ----------------------;
.results        dc.b    "NAME",0
		dc.b    "TITLE",0
		dc.b    "DESC",0
		dc.b    "GUI",0
		dc.b    "ACTIVE",0
		dc.b    0
.truestr        dc.b    "1",0
.falsestr       dc.b    "0",0
		even
*<
*-------------------------------------------------------*
* Name:         ID_UnlockCX                             *
*                                                       *
* Funktion:     Commodity-Slot freigeben                *
*                                                       *
* Parameter:    -» a5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (26. August 1997, 15:08:40)         *
*                                                       *
;SYNTAX: IDUNLOCKCX(Slot)

		clrfo
iducx_LENGTH    fo.w    0

ID_UnlockCX     link    a4,#iducx_LENGTH
	;-- Offset ermitteln -------------------;
		move.l  (rm_Args+1*4,a5),d0     ;Args[1] auslesen
		beq     .error
		move.l  d0,a0
		bsr     strtonum
		cmp.b   #" ",(a0)               ;ordentliches Ende?
		beq     .numokay
		tst.b   (a0)                    ;Ende?
		bne     .error
	;-- Ergebnis berechnen -----------------;
.numokay        ;d0: Offset-Nummer
		cmp.l   #CXSLOTS,d0             ;Im Bereich?
		bhs     .error                  ; nee... Raus!
		mulu    #MLH_SIZE,d0            ;List-Header ermitteln
		lea     cxslots,a0              ;Slots in a0
		add.l   d0,a0                   ;+ Header
		tst.l   (a0)                    ;belegt?
		beq     .error                  ; nee... Raus!
		move.l  a0,a3                   ;merken
		cx      FreeBrokerList          ;Freigeben
		clr.l   (a3)                    ;Zeiger löschen -> Slot frei
		sub.l   a0,a0                   ;Kein Ergebnisstring
		moveq   #0,d0                   ;alles OK
.exit           unlk    a4
		rts
	;-- Fehler trat auf --------------------;
.error          moveq   #12,d0                  ;Fehler
		sub.l   a0,a0
		bra     .exit
*<
*-------------------------------------------------------*
* Name:         ID_Update                               *
*                                                       *
* Funktion:     Identify updaten                        *
*                                                       *
* Parameter:    -» A5.l struct RexxMsg *                *
*               «- A0.l struct RexxArg *RESULT oder NUL *
*               «- D0.l RC                              *
* Register:     Scratch: alle                           *
*                                                       *
* Bemerkungen:                                          *
*>                                                      *
* Revision:     1.0 (23. April 1997, 10:40:55)          *
*                                                       *
; SYNTAX: IDUpdate()

ID_Update       idfy    IdHardwareUpdate
		sub.l   a0,a0
		moveq   #0,d0
		rts
*<

*---------------------------------------------------------------*
*       Hilfsfunktionen                                         *
*                                                               *
*>
*-------------------------------------------------------*
* strtoidx      Wandelt String in Index                 *
*       -» A0.l ^String (bis zum nächsten Space)        *
*       -» A1.l ^Tabelle                                *
*       «- D0.l Index in Tabelle oder -1:nicht drin     *
*       «- A0.l ^Zeichen hinter gefundenem String       *
*>                                                       *
strtoidx        movem.l d1-d2/a1-a2,-(SP)
	;-- Init -------------------------------;
		moveq   #-1,d0                  ;Index -1
		move.l  a0,a2                   ;String merken
	;-- Außen: Zeichenkette prüfen ---------;
.nexttry        addq.l  #1,d0                   ;war nichts, nächster
		tst.b   (a1)                    ;Ende?
		beq     .not_found
		move.l  a2,a0                   ;Nächster String
	;-- Innen: Zeichen prüfen --------------;
.cmploop        move.b  (a0)+,d2
		cmp.b   #'a',d2                 ;Upper()
		blo.b   .updone
		cmp.b   #'z',d2
		bhi.b   .updone
		sub.b   #$20,d2
.updone         move.b  (a1)+,d1
		beq     .test_found
		cmp.b   d2,d1                   ;Zeichen gleich?
		beq     .cmploop
	;-- Nächste Zeichenkette ---------------;
.skip           tst.b   (a1)+                   ;War schonmal nichts
		bne     .skip
		bra     .nexttry
	;-- Gefunden?! -------------------------;
.test_found     subq.l  #1,a0                   ;Auf das Zeichen setzen
		tst.b   d2                      ;Ende?
		beq     .done
		cmp.b   #' ',d2                 ;Space?
		beq     .done
		cmp.b   #'=',d2                 ;Gleich?
		beq     .done
		bra     .nexttry
	;-- String nicht gefunden --------------;
.not_found      moveq   #-1,d0
.done           movem.l (SP)+,d1-d2/a1-a2
		rts
*<
*-------------------------------------------------------*
* numtostr      Wandelt Nummer in String                *
*       -» D0.l Zahl                                    *
*       -» A0.l ^Puffer (20 Chars minimum)              *
*       «- A0.l ^Zahl im Puffer                         *
*       «- D0.l Länge der Zahl                          *
*>                                                       *
numtostr        movem.l d1-d2,-(SP)
		tst.l   d0                      ;Negativ?
		smi     d2                      ;merken
		bpl     .nosign
		neg.l   d0
.nosign         add.l   #20,a0
		clr.b   -(a0)                   ;Terminieren
		moveq   #0,d1                   ;Ziffern
.numloop        divu    #10,d0                  ;Berechnen
		swap    d0
		add.b   #'0',d0                 ;->ASCII
		move.b  d0,-(a0)                ;eintragen
		addq.l  #1,d1                   ;Eine Ziffer mehr
		clr     d0
		swap    d0
		bne     .numloop
		tst.b   d2                      ;Negativ?
		beq     .notneg
		move.b  #'-',-(a0)
		addq.l  #1,d1
.notneg         move.l  d1,d0
		movem.l (SP)+,d1-d2
		rts
*<
*-------------------------------------------------------*
* hextostr      Wandelt Hex-Nummer in String            *
*       -» D0.l Zahl                                    *
*       -» A0.l ^Puffer (20 Chars minimum)              *
*       «- A0.l ^Zahl im Puffer                         *
*       «- D0.l Länge der Zahl                          *
*>                                                       *
hextostr        movem.l a0/d1-d2,-(SP)
		lea     (.hextab,PC),a1
		moveq   #7,d1                   ;Counter (8 Stellen)
.loop           rol.l   #4,d0
		move    d0,d2
		and     #$F,d2
		move.b  (a1,d2.w),(a0)+
		dbra    d1,.loop
		clr.b   (a0)
		moveq   #8,d0                   ;Länge = 8
		movem.l (SP)+,a0/d1-d2
		rts
.hextab         dc.b    "0123456789ABCDEF"
		even
*<
*-------------------------------------------------------*
* strtonum      Wandelt String in Nummer                *
*       -» A0.l ^Puffer                                 *
*       «- A0.l ^Puffer hinter Zahl                     *
*       «- D0.l Zahl                                    *
*>                                                       *
strtonum        movem.l d1-d3,-(SP)
		moveq   #0,d0                   ;Hier wird addiert
.space          cmp.b   #' ',(a0)+              ;Spaces ignorieren
		beq     .space
		dec.l   a0
		cmp.b   #'-',(a0)               ;Negativ?
		seq     d2                      ;merken
		bne     .loop
		inc.l   a0                      ;nächste Ziffer
.loop           moveq   #0,d1
		move.b  (a0)+,d1                ;Ziffer holen
		sub.b   #'0',d1                 ;-'0'
		bcs     .convdone               ;das war's schon
		cmp.b   #9,d1                   ;>9
		bhi     .convdone
		add.l   d0,d0                   ;*2
		move.l  d0,d3                   ;merken
		add.l   d0,d0                   ;*8
		add.l   d0,d0
		add.l   d3,d0                   ;(x*8)+(x*2) = (x*10)
		add.l   d1,d0                   ;+Ziffer
		bra     .loop
.convdone       tst.b   d2                      ;Minus?
		beq     .nomin
		neg.l   d0
.nomin          dec.l   a0                      ;erstes illegales Zeichen
		movem.l (SP)+,d1-d3
		rts
*<
*-------------------------------------------------------*
* strtohex      Wandelt String in Hex-Nummer            *
*       -» A0.l ^Puffer                                 *
*       «- A0.l ^Puffer hinter Zahl                     *
*       «- D0.l Zahl                                    *
*>                                                       *
strtohex        movem.l d1-d2,-(SP)
		moveq   #7,d1                   ;es müssen 8 Ziffern sein!
		moveq   #0,d0                   ;Hier wird gerechnet
.convert        move.b  (a0)+,d2                ;Ziffer
		sub.b   #"0",d2                 ;-"0"
		bcs     .done
		cmp.b   #9,d2                   ;>9
		bls     .addit
		sub.b   #"A"-"9"-1,d2
		bcs     .done
		cmp.b   #$F,d2
		bls     .addit
		sub.b   #"a"-"A",d2
		bcs     .done
		cmp.b   #$F,d2
		bhi     .done
.addit          lsl.l   #4,d0
		or.b    d2,d0
		dbra    d1,.convert
		inc.l   a0
.done           dec.l   a0
		movem.l (SP)+,d1-d2
		rts
*<


*---------------------------------------------------------------*
*       Variablen                                               *
*                                                               *
identifybase    dc.l    0               ;identify-Base
expbase         dc.l    0               ;expansion-Base
rexxsyslibbase  dc.l    0               ;rexxsyslib-Base
cxbase          dc.l    0               ;commodity-Base
expnumbers      dc.w    0               ;Anzahl der Erweiterungen

		SECTION Bss,BSS
expansions      ds.l    32              ;Die Erweiterungen
cxslots         ds.b    CXSLOTS*MLH_SIZE  ;Slots für Commodities (struct MinList)


		SECTION text,CODE
		cnop    0,4
EndCode         ds.w    0               ;<-- ENDE

		END OF SOURCE
