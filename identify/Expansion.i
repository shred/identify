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

*---------------------------------------------------------------*
*       Struktur: Manufacturer
*
		rsreset
manuf_ID        rs.w    1       ;Relativ zum Vorgänger!
manuf_Name      rs.w    1       ;Default-Name, relativ zu strbase
manuf_Next      rs.w    1       ;bzgl. Anfang der Struktur
manuf_SIZEOF    rs.w    0

*---------------------------------------------------------------*
*       Struktur: Board
*
		rsreset
board_ID        rs.b    1       ;EPC, Relativ zum Vorgänger
board_Type      rs.b    1       ;>0: Locale-ID =0: Fctn
board_Name      rs.w    1       ;Relativ zu strbase, >=0: Funktionscode, <0: Alt.Manuf-Name
board_SIZEOF    rs.w    0

		rsreset
altmf_Manuf     rs.w    1       ;Hersteller, Relativ zu Strbase
altmf_Name      rs.w    1       ;Name, Relativ zu Strbase
altmf_Class     rs.w    1       ;Produkt-Klasse
altmf_SIZEOF    rs.w    0

*---------------------------------------------------------------*
*       Struktur: GVP-Board
*
		rsreset
gvp_EPC         rs.b    1       ;EPC, Relativ zum Vorgänger
gvp_Class       rs.b    1       ;Locale-ID
gvp_Name        rs.w    1       ;Relativ zur strbase
gvp_SIZEOF      rs.w    0

*---------------------------------------------------------------*
*       Macros zum Erstellen der Tabelle
*
tabinit         MACRO
__GLBMANUF      SET     0       ;Zähler
__GLBBOARD      SET     0
__CURRMANUF     SET     0       ;momentaner Manufacturer
__FCODENR       SET     0       ;Funktionscode-Nummer
__ALTMFNR       SET     -1      ;Alt-Manuf-Nr.
		ENDM

manuf           MACRO   ;ID,Name
__GLBMANUF      SET     __GLBMANUF+1
__BCOUNTER      SET     manuf_SIZEOF
		dc.w    \1-__CURRMANUF,manuf\@-strbase,__BOARD_\1
__CURRMANUF     SET     \1
__CURRBOARD     SET     0
		SAVE
		SECTION strings,DATA
manuf\@         dc.b    \2,0
		IFGT    (*-manuf\@)-50       ;Name zu lang?
		  FAIL  "** Manufacturer-Name zu lang!!!"
		ENDC
		RESTORE
		ENDM

board           MACRO   ;Prod-ID,Name,Type-Code
__GLBBOARD      SET     __GLBBOARD+1
__BCOUNTER      SET     __BCOUNTER+board_SIZEOF
		dc.b    \1-__CURRBOARD
		dc.b    \3-MSG_EXP_UNKNOWN+1
		dc.w    board\@-strbase
__CURRBOARD     SET     \1
		SAVE
		SECTION strings,DATA
board\@         dc.b    \2,0
		IFGT    (*-board\@)-50       ;Name zu lang?
		  FAIL  "** Board-Name zu lang!!!"
		ENDC
		RESTORE
		ENDM

boardf          MACRO   ;Prod-ID,Funktion
__BCOUNTER      SET     __BCOUNTER+board_SIZEOF
		dc.b    \1-__CURRBOARD,0
		dc.w    __FCODENR
__FCODENR       SET     __FCODENR+4
__CURRBOARD     SET     \1
		SAVE
		SECTION function,CODE
		dc.l    \2
		RESTORE
		ENDM

boarda          MACRO   ;Prod-ID,Manuf-Name,Name,Type-Code
__GLBBOARD      SET     __GLBBOARD+1
__BCOUNTER      SET     __BCOUNTER+board_SIZEOF
		dc.b    \1-__CURRBOARD,0
		dc.w    __ALTMFNR
__CURRBOARD     SET     \1
__ALTMFNR       SET     __ALTMFNR-1
		SAVE
		SECTION strings,DATA
manuf\@         dc.b    \2,0
		IFGT    (*-manuf\@)-50       ;Name zu lang?
		  FAIL  "** Alt. Manuf-Name zu lang!!!"
		ENDC
board\@         dc.b    \3,0
		IFGT    (*-board\@)-50       ;Name zu lang?
		  FAIL  "** Alt. Board-Name zu lang!!!"
		ENDC
		SECTION altmf,CODE
		dc.w    manuf\@-strbase
		dc.w    board\@-strbase
		dc.w    \4-MSG_EXP_UNKNOWN
		RESTORE
		ENDM

defstr          MACRO   ;Label, Name, Type-Code
__GLBBOARD      SET     __GLBBOARD+1
str_\1          EQU     board\@-strbase
typ_\1          EQU     \3
		SAVE
		SECTION strings,DATA
board\@         dc.b    \2,0
		IFGT    (*-board\@)-50       ;Name zu lang?
		  FAIL  "** Board-Name (defstr) zu lang!!!"
		ENDC
		RESTORE
		ENDM

defstr2         MACRO   ;Label, Name
str_\1          EQU     board\@-strbase
		SAVE
		SECTION strings,DATA
board\@         dc.b    \2,0
		IFGT    (*-board\@)-50       ;Name zu lang?
		  FAIL  "** Board-Name (defstr) zu lang!!!"
		ENDC
		RESTORE
		ENDM

endmf           MACRO   ;Manuf-ID [,END]
		dc.b    -1,0
__BOARD_\1      EQU     __BCOUNTER+2
		IFNE    NARG-1
		dc.w    32767
		ENDC
		ENDM

gvpinit         MACRO
__CURREPC       SET     0
		ENDM

gvpepc          MACRO   ;EPC,Name,Type-Code
__GLBBOARD      SET     __GLBBOARD+1
__BCOUNTER      SET     __BCOUNTER+board_SIZEOF
		dc.b    \1-__CURREPC
		dc.b    \3-MSG_EXP_UNKNOWN+1
		dc.w    board\@-strbase
__CURREPC       SET     \1
		SAVE
		SECTION strings,DATA
board\@         dc.b    \2,0
		IFGT    (*-board\@)-50       ;Name zu lang?
		  FAIL  "** GVPEPC Board-Name zu lang!!!"
		ENDC
		RESTORE
		ENDM

gvpend          MACRO
		dc.b    -1,0
		ENDM

GVP_EPCMASK     EQU     $F8             ;EPC-Maske für GVP-Produkte

*---------------------------------------------------------------*
*       Includes-Ende
*
