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
		INCLUDE lvo/exec.i                  ;LVOs
		INCLUDE lvo/dos.i
		INCLUDE lvo/identify.i

IDENTIFYVER     EQU     13

VERSION         MACRO
		  dc.b  "1.4"
		ENDM
DATE            MACRO
		  dc.b  "08.09.2001"
		ENDM

		SECTION text,CODE

*---------------------------------------------------------------*
*       == InstallIfy ==                                        *
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
Start   ;-- DOS-Lib öffnen ---------------------;
		lea     (dosname,PC),a1
		moveq   #36,d0
		exec    OpenLibrary
		move.l  d0,dosbase
		beq     .error1
	;-- Parameter einlesen -----------------;
		lea     (template,PC),a0        ;Parsen
		move.l  a0,d1
		lea     (ArgList,PC),a0
		move.l  a0,d2
		moveq   #0,d3
		dos     ReadArgs
		move.l  d0,args
		bne     .arg_ok
		bsr     help
		bra     .error2
	;-- Identify-Library öffnen ------------;
.arg_ok         lea     (identifyname,PC),a1    ;Lib öffnen
		moveq   #IDENTIFYVER,d0         ;Auch unten ändern
		exec    OpenLibrary
		move.l  d0,identifybase
		bne     .gotid
		lea     (msg_noidentify,PC),a0
		move.l  a0,d1
		pea     IDENTIFYVER.w
		move.l  SP,d2
		dos     VPrintf
		addq.l  #4,SP
		bra     .error3
	;-- Los geht's -------------------------;
.gotid          moveq   #0,d7
		move.l  (ArgList+arg_Update,PC),d0 ;Update?
		beq     .noupdate
		idfy    IdHardwareUpdate
		bra     .done
.noupdate       move.l  (ArgList+arg_Help,PC),d0  ;Help?
		beq     .nohelp
		bsr     help
		bra     .done
.nohelp         move.l  (ArgList+arg_Field,PC),d0 ;Fieldname eingegeben
		beq     .error4
		move.l  d0,a0
		lea     (str_table,PC),a1
		bsr     strtoidx
		tst.l   d0
		bpl     .field_ok
		lea     (msg_unknownfield,PC),a0
		move.l  a0,d1
		move.l  (ArgList+arg_Field,PC),-(SP)
		move.l  SP,d2
		dos     VPrintf
		addq.l  #4,SP
		bra     .error4
.field_ok       sub.l   a0,a0
		idfy    IdHardwareNum
		move.l  d0,d7
	;-- Fertig -----------------------------;
.done           move.l  (identifybase,PC),a1    ;Identify freigeben
		exec    CloseLibrary
		move.l  (args,PC),d1            ;Result freigeben
		dos     FreeArgs
		exec    CloseLibrary
		move.l  d7,d0                   ;Alles OK
.exit           rts
	;-- Fehler -----------------------------;
.error4         move.l  (identifybase,PC),a1    ;Identify freigeben
		exec    CloseLibrary
.error3         move.l  (args,PC),d1            ;Result freigeben
		dos     FreeArgs
.error2         move.l  (dosbase,PC),a1         ;DOS freigeben
		exec    CloseLibrary
.error1         moveq   #0,d0                   ;Schlug fehl
		bra.b   .exit

help            lea     (msg_help,PC),a0
		move.l  a0,d1
		dos     PutStr
		rts
*<

str_table       dc.b    "SYSTEM",0
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
		even

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

*---------------------------------------------------------------*
*       == VARIABLEN ==                                         *
*                                                               *
version         dc.b    0,"$VER: InstallIfy V"    ;Versions-String
		VERSION
		dc.b    " ("
		DATE
		dc.b    ")",$d,$a,0
		even

	;-- Variablen --------------------------;
dosbase         dc.l    0                       ;^DOS-Library
identifybase    dc.l    0                       ;^Identify Library
args            dc.l    0                       ;^Ergebnis von Parse

	;-- Argumente --------------------------;
		rsreset
arg_Field       rs.l    1                       ;Field
arg_Update      rs.l    1                       ;Update
arg_Help        rs.l    1                       ;Help
arg_SIZEOF      rs.w    0

ArgList         ds.b    arg_SIZEOF              ;Parameter-Array
template        dc.b    "FIELD,U=UPDATE/S,H=HELP/S",0

versionstr      VERSION
		dc.b    0

dosname         dc.b    "dos.library",0         ;DOS-Lib
identifyname    dc.b    "identify.library",0
msg_noidentify  dc.b    "** identify.library V%ld or higher required!\n",0
msg_unknownfield dc.b   "** unknown field name '%s'\n",0
msg_help        dc.b    "InstallIfy V"
		VERSION
		dc.b    " (C) 1999-2010 Richard Körber <rkoerber@gmx.de>\n\n"
		dc.b    "  FIELD        One of the IdHardwareNum fields, see AutoDocs.\n"
		dc.b    "               Example: \"CPU\", \"System\", \"mmu\".\n"
		dc.b    "  UPDATE       Update the information database.\n"
		dc.b    "  HELP         Show this page\n\n"
		dc.b    "The result is returned as DOS return code. See the INCLUDE file\n"
		dc.b    "for its meanings.\n",0
		even

*---------------------------------------------------------------*
*       == ENDE DES SOURCES ==                                  *
*                                                               *
		END
