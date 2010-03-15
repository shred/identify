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

ID_CLOCKFREQ    SET     -1
CATCOMP_NUMBERS SET     1

		MACHINE 68060
		FPU

		INCLUDE exec/execbase.i
		INCLUDE exec/memory.i
		INCLUDE devices/timer.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/utility.i
		INCLUDE lvo/timer.i
		INCLUDE PhxMacros.i

		INCLUDE libraries/identify.i

		INCLUDE Hardware.i
		INCLUDE Refs.i
		INCLUDE Locale.i

		SECTION text,CODE

		XDEF    GetClocks


CPULOOPS        EQU     5000                    ;Schleifendurchläufe (Prozessorkonstanten
						; sind darauf geeicht!!!)
FPULOOPS        EQU     100                     ;Schleifendurchläufe (Prozessorkonstanten
						; sind darauf geeicht!!!)

CACHEMASK       EQU     CACRF_EnableI           ;Maske für den Cache

*---------------------------------------------------------------*
*       == FUNKTIONEN ==                                        *
*                                                               *
*-------------------------------------------------------*
* Name:         GetClocks                               *
*                                                       *
* Funktion:     Zeigt den CPU und FPU-Takt              *
*                                                       *
* Parameter:    «- d0.l CPU-Takt MHz oder 0             *
*               «- d1.l FPU-Takt MHz oder 0             *
*               «- d2.l Relative CPU-Geschwindigkeit    *
* Register:     keine Änderungen                        *
*                                                       *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
		clrfo
gcl_EClock      fo.l    1       ;E-Clock-Basis
gcl_MsgPort     fo.l    1       ;^Timer-MsgPort
gcl_TimerReq    fo.l    1       ;^Timer-Request
gcl_TimerBase   fo.l    1       ;^Timer-Base
gcl_CPUClk      fo.l    1       ;CPU-Takt
gcl_FPUClk      fo.l    1       ;FPU_Takt
gcl_CPUType     fo.b    1       ;0:000 1:010 2:020 3:030 4:040 5:060
gcl_FPUType     fo.b    1       ;0:--- 1:881 2:882 3:040 4:060
gcl_SIZEOF      fo.w    0

GetClocks       pushm.l d2-d7/a0-a4
		link    a5,#gcl_SIZEOF
		clr.l   (gcl_CPUClk,a5)         ;init
		clr.l   (gcl_FPUClk,a5)
	;-- timer-device öffnen ----------------;
		exec    CreateMsgPort           ;Port erstellen
		move.l  d0,(gcl_MsgPort,a5)
		beq     .exit1
		move.l  d0,a0                   ;Reply-Port
		move.l  #IOTV_SIZE,d0           ;Größe
		exec    CreateIORequest
		move.l  d0,(gcl_TimerReq,a5)
		beq     .exit2
		lea     (.timername,PC),a0      ;Name
		move.l  #UNIT_MICROHZ,d0        ;Typ
		move.l  (gcl_TimerReq,a5),a1    ;IO-Request
		moveq   #0,d1                   ;Flags
		exec    OpenDevice              ;Device öffnen
		tst.l   d0
		bne     .exit3
		move.l  (gcl_TimerReq,a5),a0
		move.l  (IO_DEVICE,a0),(gcl_TimerBase,a5)
	;-- E-Takt ermitteln -------------------;
		args    #0,#0
		move.l  SP,a0
		move.l  (gcl_TimerBase,a5),a6
		jsr     (_TIMERReadEClock,a6)
		unargs
		move.l  d0,(gcl_EClock,a5)
	;-- Prozessortyp ermitteln -------------;
		move.l  4.w,a0
		move    (AttnFlags,a0),d0       ;Flags
		moveq   #5,d1                   ;060?
		btst    #AFB_68060,d0
		bne     .cpu_ok
		subq    #1,d1                   ;040?
		btst    #AFB_68040,d0
		bne     .cpu_ok
		subq    #1,d1                   ;030?
		btst    #AFB_68030,d0
		bne     .cpu_ok
		subq    #1,d1                   ;020?
		btst    #AFB_68020,d0
		bne     .cpu_ok
		subq    #1,d1                   ;010?
		btst    #AFB_68010,d0
		bne     .cpu_ok
		subq    #1,d1                   ;000!
.cpu_ok         move.b  d1,(gcl_CPUType,a5)
	;-- FPU_Typ ermitteln ------------------;
		moveq   #4,d1                   ;060
		btst    #AFB_FPU40,d0           ;060 oder 040?
		beq     .ext_fpu                ;nein: extern
		btst    #AFB_68060,d0           ;060?
		bne     .fpu_ok
		subq    #1,d1                   ;sonst 040!
		bra     .fpu_ok
.ext_fpu        moveq   #2,d1                   ;882
		btst    #AFB_68882,d0
		bne     .fpu_ok
		subq    #1,d1                   ;881
		btst    #AFB_68881,d0
		bne     .fpu_ok
		subq    #1,d1                   ;---
.fpu_ok         move.b  d1,(gcl_FPUType,a5)
	;-- CPU-Test ---------------------------;
		exec    Forbid                  ;kein MT, damit Caches an bleiben
		bsr     SetCache                ;Code&Data Cache ein, Branch aus
		move.l  d0,d1
		bsr     TestCPU                 ;Zeit berechnen
		move.l  d0,d3                   ;Ergebnis merken
		move.l  d1,d0                   ;Code, Data, Branch restaurieren
		bsr     RestoreCache
		exec    Permit
		move.l  d3,d0                   ;Messung lesen
		beq     .exit4                  ; war 0: Fehler! (FPU-Test dann sinnlos)
		move.l  (gcl_EClock,a5),d1      ;d1: EClock
		moveq   #0,d2                   ;d2: Prozessor-Konstante
		lea     (.cpuconst,PC),a0
		move.b  (gcl_CPUType,a5),d2
		move.b  (a0,d2.w),d2
		bsr     ComputeClk
		move.l  d0,(gcl_CPUClk,a5)
	;-- FPU-Test ---------------------------;
		tst.b   (gcl_FPUType,a5)        ;Gibts eine FPU?
		beq     .no_fpu
		exec    Forbid                  ;kein MT, damit Caches an bleiben
		bsr     SetCache                ;Code&Data Cache ein, Branch aus
		move.l  d0,d1
		bsr     TestFPU                 ;Zeit berechnen
		move.l  d0,d3                   ;Ergebnis merken
		move.l  d1,d0                   ;Code, Data, Branch restaurieren
		bsr     RestoreCache
		exec    Permit
		move.l  d3,d0
		beq     .no_fpu                 ;konnte nicht ermittelt werden
		move.l  (gcl_EClock,a5),d1      ;d1: EClock
		moveq   #0,d2                   ;d2: Prozessor-Konstante
		lea     (.fpuconst,PC),a0
		move.b  (gcl_FPUType,a5),d2
		move.b  (a0,d2.w),d2
		bsr     ComputeClk
		move.l  d0,(gcl_FPUClk,a5)
.no_fpu
	;-- Ende -------------------------------;
.exit4          move.l  (gcl_TimerReq,a5),a1
		exec    CloseDevice
.exit3          move.l  (gcl_TimerReq,a5),a0
		exec    DeleteIORequest
.exit2          move.l  (gcl_MsgPort,a5),a0
		exec    DeleteMsgPort
.exit1          move.l  (gcl_CPUClk,a5),d0
		move.l  (gcl_FPUClk,a5),d1
		unlk    a5
		popm.l  d2-d7/a0-a4
		rts
	;-- Konstanten -------------------------;

	; VERSION 3
.timername      dc.b    "timer.device",0
*<
.cpuconst       dc.b    11              ;68000: 11.11 1E6/((CPULOOPS*18)+12)
		dc.b    11              ;68010: 11.11 1E6/((CPULOOPS*18)+12)
		dc.b    25              ;68020: 24.99 1E6/((CPULOOPS* 8)+12)
		dc.b    25              ;68030: 24.99 1E6/((CPULOOPS* 8)+12)
		dc.b    67              ;68040: 66.66 1E6/((CPULOOPS* 3)+ 4)
		dc.b    50              ;68060: 49.99 1E6/((CPULOOPS* 4)+ 5)
.fpuconst       dc.b    "5"             ;-- Versionsnummer --
		dc.b    46              ;68881: 46.30 1E6/(FPULOOPS*216)
		dc.b    49              ;68882: 48.54 1E6/(FPULOOPS*206)
		dc.b    49              ;68040: 48.54 1E6/(FPULOOPS*206)
		dc.b    74              ;68060: 73.53 1E6/(FPULOOPS*136)
		even

*-------------------------------------------------------*
* Name:         SetCache                                *
*                                                       *
* Funktion:     Caches setzen                           *
*                                                       *
* Parameter:    -» a5.l ^Hauptpgm-Base                  *
*               «- d0.l Cache-Store                     *
* Register:     Scratch d1/a0-a1                        *
*                                                       *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
SetCache
	;-- 68000~68060 ------------------------;
		move.l  #CACHEMASK,d0           ;Code&Daten-Cache ein!
		move.l  d0,d1
		exec    CacheControl
	;-- 68060 Branch Cache? ----------------;
		cmp.b   #5,(gcl_CPUType,a5)     ;68060?
		bne     .no_060
		bclr    #23,d0                  ;Erst mal löschen
		push.l  a5
		lea     (.get_cacr,PC),a5
		exec    Supervisor
		pop.l   a5
.no_060         rts
	;-- Supervisor Code --------------------;
		cnop    0,4
.get_cacr       movec.l cacr,d1
		bclr    #23,d1                  ;EBC aus
		beq     .no_ebc                 ;alten Zustand merken
		bset    #23,d0
.no_ebc         movec.l d1,cacr
		nop
		rte
*<
*-------------------------------------------------------*
* Name:         RestoreCache                            *
*                                                       *
* Funktion:     Caches restaurieren                     *
*                                                       *
* Parameter:    -» a5.l ^Hauptpgm-Base                  *
*               -» d0.l Cache-Store                     *
* Register:     Scratch d1/a0-a1                        *
*                                                       *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
RestoreCache    cmp.b   #5,(gcl_CPUType,a5)     ;68060?
		bne     .no_060
		bclr    #23,d0                  ;Branch Cache ein?
		beq     .no_060
		push.l  a5
		lea     (.set_cacr,PC),a5
		exec    Supervisor
		pop.l   a5
	;-- 68000~68040 ------------------------;
.no_060         move.l  #CACHEMASK,d1
		exec    CacheControl
		rts
	;-- 68060 ------------------------------;
.set_cacr       movec.l cacr,d1
		or.l    #(1<<23)|(1<<22),d1
		movec.l d1,cacr
		nop
		rte
*<
*-------------------------------------------------------*
* Name:         ComputeClk                              *
*                                                       *
* Funktion:     Berechnet den Takt                      *
*                                                       *
* Parameter:    -» d0.l Messungswert                    *
*               -» d1.l E-Clock                         *
*               -» d2.l Prozessor-Konstante             *
*               «- d0.l Takt in MHz 0:Error             *
* Register:     keine Änderungen                        *
*                                                       *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
ComputeClk      pushm.l d1-d3/a0-a1
	       IFD      _MAKE_68020
		divu.l  d0,d1
		divu.l  d2,d1
		move.l  d1,d0
	       ELSE
		exg.l   d0,d1
		utils   UDivMod32
		move.l  d2,d1
		utils.q UDivMod32
		tst.l   d0
	       ENDC
		beq     .exit                   ;Null -> Raus!
		lea     (.limittab,PC),a0       ;Vernünftigen Takt ermitteln
		lea     (.quarztab,PC),a1       ;hier kommt der Takt her
		moveq   #0,d1
.limloop        move.b  (a0)+,d1
		beq     .exit                   ;>max: direkt ausgeben!
		cmp.l   d1,d0                   ;d0<=takt?
		ble     .found
		inc.l   a1
		bra     .limloop
.found          move.b  (a1),d0                 ;Dies ist der Takt
.exit           popm.l  d1-d3/a0-a1
		rts
.error          moveq   #0,d0
		bra     .exit
	;-- Takt-Tabelle -----------------------;
.limittab       dc.b       9,12,15,19,22,27,30,35,38,45,57,63,78,90,0  ;ab xx ausschließlich
.quarztab       dc.b    7,10,14,16,20,25,28,33,37,40,50,60,66,80    ;gilt dieser Takt

;                   9 13 19 22 28 40 57 63 78 90
;                7 10 16 20 25 33 50 60 66 80

		even
*<
*-------------------------------------------------------*
* Name:         TestCPU                                 *
*                                                       *
* Funktion:     Mißt das CPU-Timing                     *
*                                                       *
* Parameter:    «- d0.l Einheiten in E-Clocks, 0: error *
*               -» a5.l ^Hauptpgm-Base                  *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  InstCache ein, BranchCache aus!         *
*               Multitasking vorher abschalten!         *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
		clrfo
tcpu_prestart   fo.l    2       ;Pretest Start
tcpu_prestop    fo.l    2       ;Pretest Stop
tcpu_startclk   fo.l    2       ;Start-Zeit
tcpu_stopclk    fo.l    2       ;Stop-Zeit
tcpu_SIZEOF     fo.w    0

TestCPU         pushm.l d1-d3/a0-a3
		link    a4,#tcpu_SIZEOF
	;-- Messung ausführen ------------------;
		exec    Disable
		lea     (tcpu_prestart,a4),a0   ;Stoppuhr starten
		move.l  (gcl_TimerBase,a5),a6
		jsr     (_TIMERReadEClock,a6)
		lea     (tcpu_prestop,a4),a0    ;Stoppuhr stoppen
		jsr     (_TIMERReadEClock,a6)
		exec    Enable
	;-- Differenz berechnen ----------------;
		move.l  (tcpu_prestop+4,a4),d3  ;Zeitdifferenz berechnen
		sub.l   (tcpu_prestart+4,a4),d3
		move.l  (tcpu_prestop,a4),d1
		move.l  (tcpu_prestart,a4),d2
		subx.l  d2,d1
		tst.l   d1
		bne     .error
	;-- Messung ausführen ------------------;
		exec    Disable
		lea     (tcpu_startclk,a4),a0   ;Stoppuhr starten
		move.l  (gcl_TimerBase,a5),a6
		jsr     (_TIMERReadEClock,a6)
		move.l  #CPULOOPS,d0            ;Durchläufe
		cnop    0,4
.loop           subq.l  #1,d0
		bcc.b   .loop
		lea     (tcpu_stopclk,a4),a0    ;Stoppuhr stoppen
		jsr     (_TIMERReadEClock,a6)
		exec    Enable
	;-- Differenz berechnen ----------------;
		move.l  (tcpu_stopclk+4,a4),d0  ;Zeitdifferenz berechnen
		sub.l   (tcpu_startclk+4,a4),d0
		move.l  (tcpu_stopclk,a4),d1
		move.l  (tcpu_startclk,a4),d2
		subx.l  d2,d1
		tst.l   d1
		bne     .error
	;-- Zeit berechnen ---------------------;
		sub.l   d3,d0                   ;Carry: mit Schleife kürzer als ohne?!
		bcs     .error
		addq.l  #2,d0                   ;kleiner Ausgleich
	;-- Fertig -----------------------------;
.exit           unlk    a4
		popm.l  d1-d3/a0-a3
		rts
	;-- Fehler -----------------------------;
.error          moveq   #0,d0
		bra     .exit
*<
*-------------------------------------------------------*
* Name:         TestFPU                                 *
*                                                       *
* Funktion:     Mißt das FPU-Timing                     *
*                                                       *
* Parameter:    «- d0.l Einheiten in E-Clocks, 0: error *
*               -» a5.l ^Hauptpgm-Base                  *
* Register:     keine Änderungen                        *
*                                                       *
* Bemerkungen:  InstCache ein, BranchCache aus!         *
*               Multitasking vorher abschalten!         *
*>                                                      *
* Revision:     1.0 (13. Mai 1996, 15:49:48)            *
*                                                       *
		clrfo
tfpu_prestart   fo.l    2       ;Pretest Start
tfpu_prestop    fo.l    2       ;Pretest Stop
tfpu_startclk   fo.l    2       ;Start-Zeit
tfpu_stopclk    fo.l    2       ;Stop-Zeit
tfpu_SIZEOF     fo.w    0

TestFPU         pushm.l d1-d3/a0-a3
		link    a4,#tfpu_SIZEOF
	;-- Messung ausführen ------------------;
		exec    Disable
		lea     (tfpu_prestart,a4),a0   ;Stoppuhr starten
		move.l  (gcl_TimerBase,a5),a6
		jsr     (_TIMERReadEClock,a6)
		lea     (tfpu_prestop,a4),a0    ;Stoppuhr stoppen
		jsr     (_TIMERReadEClock,a6)
		exec    Enable
	;-- Differenz berechnen ----------------;
		move.l  (tfpu_prestop+4,a4),d3  ;Zeitdifferenz berechnen
		sub.l   (tfpu_prestart+4,a4),d3
		move.l  (tfpu_prestop,a4),d1
		move.l  (tfpu_prestart,a4),d2
		subx.l  d2,d1
		tst.l   d1
		bne     .error
	;-- Messung ausführen ------------------;
		exec    Disable
		fmove.w #1,fp1
		lea     (tfpu_startclk,a4),a0   ;Stoppuhr starten
		move.l  (gcl_TimerBase,a5),a6
		jsr     (_TIMERReadEClock,a6)
		move.l  #FPULOOPS,d0            ;Durchläufe
		cnop    0,4
.loop           fsqrt.x fp1
		fsqrt.x fp1
		subq.l  #1,d0
		bcc.b   .loop
		lea     (tfpu_stopclk,a4),a0    ;Stoppuhr stoppen
		jsr     (_TIMERReadEClock,a6)
		exec    Enable
	;-- Differenz berechnen ----------------;
		move.l  (tfpu_stopclk+4,a4),d0  ;Zeitdifferenz berechnen
		sub.l   (tfpu_startclk+4,a4),d0
		move.l  (tfpu_stopclk,a4),d1
		move.l  (tfpu_startclk,a4),d2
		subx.l  d2,d1
		tst.l   d1
		bne     .error
	;-- Zeit berechnen ---------------------;
		sub.l   d3,d0                   ;Carry: mit Schleife kürzer als ohne?!
		bcs     .error
	;-- Fertig -----------------------------;
.exit           unlk    a4
		popm.l  d1-d3/a0-a3
		rts
	;-- Fehler -----------------------------;
.error          moveq   #0,d0
		bra     .exit
*<

*---------------------------------------------------------------*
*       == ENDE ==                                              *
*                                                               *
		END OF SOURCE
