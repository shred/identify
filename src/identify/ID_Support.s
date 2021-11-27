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

		INCLUDE lvo/exec.i

		INCLUDE ID_Locale.i

		IFD	_MAKE_68020
		  MACHINE 68020
		ENDC

		SECTION text,CODE

**
* Format a string.
*
*	-> A0.l	^Target string
*	-> A1.l	^Source string
*	-> A2.l	^Arguments
*
		public	SPrintF
SPrintF		movem.l d0-d3/a0-a3,-(sp)
		move.l	a0,a3
		move.l	a1,a0
		move.l	a2,a1
		lea	(.proc,PC),a2
		exec	RawDoFmt
		movem.l (sp)+,d0-d3/a0-a3
		rts
.proc		move.b	d0,(a3)+
		rts

**
* Print a size (in KB, MB, GB).
*
*	-> A0.l ^Target string
*	-> D0.l Value
*	-> D1.b NewLoc mode
*
		public	SPrintSize
SPrintSize	movem.l d0-d5/a0-a3,-(SP)
		sf	d4
		lea	(.sizetab,PC),a1	; table of sizes
		lea	(.postcomma,PC),a2	; decimal table
		moveq	#2,d5			; number of entries in the size table
.loop		cmp.l	#1000,d0		; less than 1000?
		blo	.print
		addq.l	#4,a1			; try next factor
		move	d0,d2			; rounding needed?
		and	#%1110000,d2
		cmp	#%1110000,d2
		seq	d4
		bne	.not_round
		add.l	#%0010000,d0		; round up
.not_round	lsr.l	#7,d0			; find number of digits
		move	d0,d2
		and	#%111,d2
		lsr.l	#3,d0			; find number of digits before separator
		dbra	d5,.loop
.print		moveq	#0,d5
		move.b	(a2,d2.w),d5
		move	d5,-(SP)
		move.l	d0,-(SP)
		move.l	a0,d3
		move.l	(a1),d0
		bsr	GetNewLocString
		move.l	a0,a1
		move.l	d3,a0
		tst.b	d4			 ; is it rounded?
		beq	.no_sign
		move.b	#"~",(a0)+
.no_sign	move.l	SP,a2
		bsr	SPrintF
		add.l	#4+2,SP
		movem.l (SP)+,d0-d5/a0-a3
		rts

.sizetab	dc.l	MSG_BYTE, MSG_KBYTE, MSG_MBYTE, MSG_GBYTE
.postcomma	dc.b	"01245689"
		even
