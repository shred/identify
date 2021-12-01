*
* identify.library
*
* Copyright (C) 2021 Richard "Shred" Koerber
*	http://identify.shredzone.org
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Lesser General Public License as published
* by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*

		INCLUDE exec/execbase.i
		INCLUDE exec/memory.i
		INCLUDE devices/timer.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/utility.i
		INCLUDE lvo/timer.i

		INCLUDE libraries/identify.i

		INCLUDE ID_Hardware.i
		INCLUDE ID_Locale.i

		MACHINE 68060
		FPU

		SECTION text,CODE

**
* Number of loops in the CPU/FPU clock frequency meter. Do not change!
*
CPULOOPS	EQU	5000
FPULOOPS	EQU	500

CACHEMASK	EQU	CACRF_EnableI


**
* Return the CPU and FPU clock frequency.
*
*	<- D0.l	CPU Clock (MHz) or 0
*	<- D1.l FPU Clock (MHz) or 0
*	<- D2.l Relative CPU speed
*
		clrfo
gcl_EClock	fo.l	1	; E clock
gcl_MsgPort	fo.l	1	; ^Timer MsgPort
gcl_TimerReq	fo.l	1	; ^Timer Request
gcl_TimerBase	fo.l	1	; ^Timer Base
gcl_CPUClk	fo.l	1	; CPU Clock
gcl_FPUClk	fo.l	1	; FPU clock
gcl_CPUType	fo.b	1	; CPU Type: 0:000 1:010 2:020 3:030 4:040 5:060
gcl_FPUType	fo.b	1	; FPU Type: 0:--- 1:881 2:882 3:040 4:060
gcl_SIZEOF	fo.w	0

		public	GetClocks
GetClocks	movem.l d2-d7/a0-a4,-(SP)
		link	a5,#gcl_SIZEOF
		clr.l	(gcl_CPUClk,a5)
		clr.l	(gcl_FPUClk,a5)
	;-- open timer device
		exec	CreateMsgPort
		move.l	d0,(gcl_MsgPort,a5)
		beq	.exit1
		move.l	d0,a0
		move.l	#IOTV_SIZE,d0
		exec	CreateIORequest
		move.l	d0,(gcl_TimerReq,a5)
		beq	.exit2
		lea	(.timername,PC),a0
		move.l	#UNIT_MICROHZ,d0
		move.l	(gcl_TimerReq,a5),a1
		moveq	#0,d1
		exec	OpenDevice
		tst.l	d0
		bne	.exit3
		move.l	(gcl_TimerReq,a5),a0
		move.l	(IO_DEVICE,a0),(gcl_TimerBase,a5)
	;-- find e-clock frequency
		move.l	#0,-(SP)
		move.l	#0,-(SP)
		move.l	SP,a0
		move.l	(gcl_TimerBase,a5),a6
		jsr	(_TIMERReadEClock,a6)
		add.l	#8,SP
		move.l	d0,(gcl_EClock,a5)
	;-- get CPU type
		move.l	4.w,a0
		move	(AttnFlags,a0),d0
		btst	#AFB_FPGA,d0		; FPGA?
		bne	.exit4			;   -> yes: no result, will be useless anyway
		moveq	#5,d1			; 060?
		btst	#AFB_68060,d0
		bne	.cpu_ok
		subq	#1,d1			; 040?
		btst	#AFB_68040,d0
		bne	.cpu_ok
		subq	#1,d1			; 030?
		btst	#AFB_68030,d0
		bne	.cpu_ok
		subq	#1,d1			; 020?
		btst	#AFB_68020,d0
		bne	.cpu_ok
		subq	#1,d1			; 010?
		btst	#AFB_68010,d0
		bne	.cpu_ok
		subq	#1,d1			; 000 (or something unknown)
.cpu_ok		move.b	d1,(gcl_CPUType,a5)
	;-- get FPU type
		moveq	#4,d1			; maybe 060
		btst	#AFB_FPU40,d0
		beq	.ext_fpu
		btst	#AFB_68060,d0
		bne	.fpu_ok
		subq	#1,d1			; no, it's 040
		bra	.fpu_ok
.ext_fpu	moveq	#2,d1			; 882
		btst	#AFB_68882,d0
		bne	.fpu_ok
		subq	#1,d1			; 881
		btst	#AFB_68881,d0
		bne	.fpu_ok
		subq	#1,d1			; no FPU (or something unknown)
.fpu_ok		move.b	d1,(gcl_FPUType,a5)
	;-- test CPU
		exec	Forbid			; make sure caches stay active
		bsr	SetCache		; enable code/data cache, disable branch prediction
		move.l	d0,d1
		bsr	TestCPU			; time CPU
		move.l	d0,d3			; remember result
		move.l	d1,d0			; restore cache settings
		bsr	RestoreCache
		exec	Permit			; enable multitasking again
		move.l	d3,d0			; read result
		beq	.exit4			;   0 -> error (no reason to check FPU then)
		move.l	(gcl_EClock,a5),d1	; D1: EClock
		moveq	#0,d2			; D2: a processor dependent performance constant
		lea	(.cpuconst,PC),a0
		move.b	(gcl_CPUType,a5),d2
		move.b	(a0,d2.w),d2
		bsr	ComputeClk		; compute CPU clock
		move.l	d0,(gcl_CPUClk,a5)
	;-- test FPU
		tst.b	(gcl_FPUType,a5)	; is there an FPU anyway?
		beq	.no_fpu
		exec	Forbid			; make sure caches stay active
		bsr	SetCache		; emable code/data cache, disable branch prediction
		move.l	d0,d1
		bsr	TestFPU			; time FPU
		move.l	d0,d3			; remember result
		move.l	d1,d0			; restore cache settings
		bsr	RestoreCache
		exec	Permit			; enable multitasking again
		move.l	d3,d0			; read result
		beq	.no_fpu			;   0 -> error
		move.l	(gcl_EClock,a5),d1	; D1: EClock
		moveq	#0,d2			; D2: a FPU dependent performance constant
		lea	(.fpuconst,PC),a0
		move.b	(gcl_FPUType,a5),d2
		move.b	(a0,d2.w),d2
		bsr	ComputeClk		; compute FPU clock
		move.l	d0,(gcl_FPUClk,a5)
.no_fpu
	;-- done
.exit4		move.l	(gcl_TimerReq,a5),a1
		exec	CloseDevice
.exit3		move.l	(gcl_TimerReq,a5),a0
		exec	DeleteIORequest
.exit2		move.l	(gcl_MsgPort,a5),a0
		exec	DeleteMsgPort
.exit1		move.l	(gcl_CPUClk,a5),d0
		move.l	(gcl_FPUClk,a5),d1
		unlk	a5
		movem.l	(SP)+,d2-d7/a0-a4
		rts

.timername	dc.b	"timer.device",0

	; CPU PERFORMANCE CONSTANTS
.cpuconst	dc.b	11		; 68000: 11.11 1E6/((CPULOOPS*18)+12)
		dc.b	11		; 68010: 11.11 1E6/((CPULOOPS*18)+12)
		dc.b	25		; 68020: 24.99 1E6/((CPULOOPS* 8)+12)
		dc.b	25		; 68030: 24.99 1E6/((CPULOOPS* 8)+12)
		dc.b	67		; 68040: 66.66 1E6/((CPULOOPS* 3)+ 4)
		dc.b	50		; 68060: 49.99 1E6/((CPULOOPS* 4)+ 5)

	; FPU PERFORMANCE CONSTANTS
.fpuconst	dc.b	"6"		; version number, please increment on changes
		dc.b	 9		; 68881:  9.26 1E6/(FPULOOPS*216)
		dc.b	 9		; 68882:  9.71 1E6/(FPULOOPS*206)
		dc.b	 9		; 68040:  9.71 1E6/(FPULOOPS*206)
		dc.b	14		; 68060: 14.71 1E6/(FPULOOPS*136)
		even

**
* Enable caching.
*
* 	-> A5.l	Local variable base
*	<- D0.l Cache register before change
*
SetCache
		move.l	#CACHEMASK,d0		; enable code & data cache on all CPUs
		move.l	d0,d1
		exec	CacheControl
		cmp.b	#5,(gcl_CPUType,a5)	; turn off branch cache of 68060
		bne	.no_060
		bclr	#23,d0
	;-- change CACR
		move.l	a5,-(SP)
		lea	(.get_cacr,PC),a5
		exec	Supervisor
		move.l	(SP)+,a5
.no_060		rts

		cnop	0,4
.get_cacr	movec.l cacr,d1
		bclr	#23,d1			; turn off EBC
		beq	.no_ebc			; remember old state
		bset	#23,d0
.no_ebc		movec.l d1,cacr
		nop
		rte


**
* Restore caching.
*
* 	-> A5.l	Local variable base
*	-> D0.l Previous cache status
*
RestoreCache	cmp.b	#5,(gcl_CPUType,a5)	; enable branch cache on 68060
		bne	.no_060
		bclr	#23,d0
		beq	.no_060
	;-- restore CACR
		move.l	a5,-(SP)
		lea	(.set_cacr,PC),a5
		exec	Supervisor
		move.l	(SP)+,a5
	;-- restore cache mask on all CPUs
.no_060		move.l	#CACHEMASK,d1
		exec	CacheControl
		rts

.set_cacr	movec.l cacr,d1
		or.l	#(1<<23)|(1<<22),d1
		movec.l d1,cacr
		nop
		rte

**
* Compute clock frequency from test result.
*
*	-> D0.l	Test result, in number of E clock ticks
*	-> D1.l E clock of this machine
*	-> D2.l CPU/FPU related performance constant
*	<- D0.l Clock im MHz, or 0 if error
*
ComputeClk	movem.l d1-d3/a0-a1,-(SP)
		IFD	_MAKE_68020
		 divu.l	d0,d1
		 divu.l	d2,d1
		 move.l	d1,d0
		ELSE
		 exg.l	d0,d1
		 utils	UDivMod32
		 move.l	d2,d1
		 utils.q UDivMod32
		 tst.l	d0
		ENDC
		beq	.exit			; 0 result -> error
	;-- round to typical clock frequencies
		lea	(.limittab,PC),a0	; table of upper boundaries
		lea	(.quarztab,PC),a1	; table of common frequencies
		moveq	#0,d1
.limloop	move.b	(a0)+,d1
		beq	.toofast		; bigger than max -> give direct value
		cmp.l	d1,d0			; less than upper boundary?
		ble	.found
		addq.l	#1,a1			; no -> try next boundary
		bra	.limloop
.found		move.b	(a1),d0			; yes -> use matching quartz frequency
.exit		movem.l (SP)+,d1-d3/a0-a1
		rts
	;-- faster than table
.toofast	divu	#10,d0			; Round down to next divisible by 10
		mulu	#10,d0
		bra	.exit
	;-- error
.error		moveq	#0,d0
		bra	.exit

	;-- upper boundaries, in MHz, null-terminated
.limittab	dc.b	9,12,15,19,22,27,30,35,38,45,57,63,78,90,0

	;-- related common quartz frequencies, in MHz
.quarztab	dc.b	7,10,14,16,20,25,28,33,37,40,50,60,66,80
		even


**
* Measure the CPU performance.
*
* Instruction and data cache must be turned on, branch cache must be turned off.
* Multitasking must be forbidden during measurement.
*
*	-> A5.l	Local variables
*	<- D0.l	Test result in E clocks, 0=error
*
		clrfo
tcpu_prestart	fo.l	2	; Pretest Start
tcpu_prestop	fo.l	2	; Pretest Stop
tcpu_startclk	fo.l	2	; Start timestamp
tcpu_stopclk	fo.l	2	; Stop timestamp
tcpu_SIZEOF	fo.w	0

TestCPU		movem.l d1-d3/a0-a3,-(SP)
		link	a4,#tcpu_SIZEOF
	;-- measure plain stopwatch start/stop time
		exec	Disable
		lea	(tcpu_prestart,a4),a0	; start stopwatch
		move.l	(gcl_TimerBase,a5),a6
		jsr	(_TIMERReadEClock,a6)
		lea	(tcpu_prestop,a4),a0	; stop stopwatch
		jsr	(_TIMERReadEClock,a6)
		exec	Enable
	;-- compute difference
		move.l	(tcpu_prestop+4,a4),d3
		sub.l	(tcpu_prestart+4,a4),d3
		move.l	(tcpu_prestop,a4),d1
		move.l	(tcpu_prestart,a4),d2
		subx.l	d2,d1
		tst.l	d1
		bne	.error			; 0 -> no e-clock present!
	;-- measure real CPU performance
		exec	Disable
		lea	(tcpu_startclk,a4),a0	; start stopwatch
		move.l	(gcl_TimerBase,a5),a6
		jsr	(_TIMERReadEClock,a6)
		move.l	#CPULOOPS,d0		; busy loop
		cnop	0,4
.loop		subq.l	#1,d0			; just count down
		bcc.b	.loop
		lea	(tcpu_stopclk,a4),a0	; stop stopwatch
		jsr	(_TIMERReadEClock,a6)
		exec	Enable
	;-- compute difference
		move.l	(tcpu_stopclk+4,a4),d0
		sub.l	(tcpu_startclk+4,a4),d0
		move.l	(tcpu_stopclk,a4),d1
		move.l	(tcpu_startclk,a4),d2
		subx.l	d2,d1
		tst.l	d1
		bne	.error
	;-- subtract time for starting/stopping stopwatch
		sub.l	d3,d0
		bcs	.error			; first take took longer than second?!
		addq.l	#2,d0			; small compensation
	;-- done
.exit		unlk	a4
		movem.l (SP)+,d1-d3/a0-a3
		rts
	;-- error
.error		moveq	#0,d0
		bra	.exit

**
* Measure the FPU performance.
*
* Instruction and data cache must be turned on, branch cache must be turned off.
* Multitasking must be forbidden during measurement.
*
*	-> A5.l	Local variables
*	<- D0.l	Test result in E clocks, 0=error
*
		clrfo
tfpu_prestart	fo.l	2	; Pretest Start
tfpu_prestop	fo.l	2	; Pretest Stop
tfpu_startclk	fo.l	2	; Start timestamp
tfpu_stopclk	fo.l	2	; Stop timestamp
tfpu_SIZEOF	fo.w	0

TestFPU		movem.l d1-d3/a0-a3,-(SP)
		link	a4,#tfpu_SIZEOF
	;-- measure plain stopwatch start/stop time
		exec	Disable
		lea	(tfpu_prestart,a4),a0	; start stopwatch
		move.l	(gcl_TimerBase,a5),a6
		jsr	(_TIMERReadEClock,a6)
		lea	(tfpu_prestop,a4),a0	; stop stopwatch
		jsr	(_TIMERReadEClock,a6)
		exec	Enable
	;-- compute difference
		move.l	(tfpu_prestop+4,a4),d3
		sub.l	(tfpu_prestart+4,a4),d3
		move.l	(tfpu_prestop,a4),d1
		move.l	(tfpu_prestart,a4),d2
		subx.l	d2,d1
		tst.l	d1
		bne	.error			; 0 -> no e-clock present!
	;-- measure real FPU performance
		exec	Disable
		fmove.w #1,fp1			; set 1.0 to fp1
		lea	(tfpu_startclk,a4),a0	; start stopwatch
		move.l	(gcl_TimerBase,a5),a6
		jsr	(_TIMERReadEClock,a6)
		move.l	#FPULOOPS,d0		; busy loop
		cnop	0,4
.loop		fsqrt.x fp1			; just take square roots of 1
		fsqrt.x fp1
		subq.l	#1,d0			; until counter is 0
		bcc.b	.loop			; TODO: CPU performance should be subtracted
		lea	(tfpu_stopclk,a4),a0	; stop stopwatch
		jsr	(_TIMERReadEClock,a6)
		exec	Enable
	;-- compute difference
		move.l	(tfpu_stopclk+4,a4),d0
		sub.l	(tfpu_startclk+4,a4),d0
		move.l	(tfpu_stopclk,a4),d1
		move.l	(tfpu_startclk,a4),d2
		subx.l	d2,d1
		tst.l	d1
		bne	.error
	;-- subtract time for starting/stopping stopwatch
		sub.l	d3,d0
		bcs	.error			; pretest took longer -> error
	;-- done
.exit		unlk	a4
		movem.l (SP)+,d1-d3/a0-a3
		rts
	;-- error
.error		moveq	#0,d0
		bra	.exit
