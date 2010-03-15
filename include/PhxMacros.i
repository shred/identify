*****************************************************************
*								*
*	PhxMacros.i	 PhxAss Macro Extension			*
*								*
*****************************************************************
*
*	$VER: PhxMacros 1.6 (2.10.97)
*	(C) 1996-97 Richard Körber -- All rights reserved
*
*	Requires PhxAss V4.33 or higher!
*
* 1.6	 2.10.97 (shred) added getexec, FALSE, TRUE, NULL
*
* 1.5	27. 2.97 (shred) added fpush, ftop, fpop, fpushm, ftopm,
*		       fpopm, fstore, frecall and clra
*
* 1.4	14. 2.97 (shred) added db, dw and dl macros (compatibility)
*		       added Amiga macros
*
* 1.3	21.10.96 (shred) renamed peek to top, took def2 from phx,
*		       added args and unargs
*
* 1.2	14.10.96 (phx) removed IFCPU macro, fixed ODD macro,
*		       fixed FLIP macro, fixed EXTBL macro,
*		       added another (better) DEF macro, called DEF2.
*
*****************************************************************

		IFND	_PHXMACROS_I
_PHXMACROS_I	SET	-1

align		MACRO			;align <val>
		cnop	0,\1
		ENDM

odd		MACRO			;opposite of 'even'
		cnop	1,2
		ENDM

inc		MACRO			;increment
		addq.\0 #1,\1		;  inc.(b|w|l) <ea>
		ENDM

dec		MACRO			;decrement
		subq.\0 #1,\1		;  dec.(b|w|l) <ea>
		ENDM

push		MACRO			;push to stack
		move.\0 \1,-(sp)	;  push.(w|l)  <ea>
		ENDM

fpush		MACRO			;push float to stack
		fmove.\0 \1,-(sp)	;  fpush.(b|w|l|s|d|x|p) <ea>
		ENDM

top		MACRO			;top stack
		move.\0 (sp),\1		;  top.(w|l)  <ea>
		ENDM

ftop		MACRO			;top float stack
		fmove.\0 (sp),\1	;  ftop.(b|w|l|s|d|x|p) <ea>
		ENDM

pop		MACRO			;pop from stack
		move.\0 (sp)+,\1	;  pop.(w|l)   <ea>
		ENDM

fpop		MACRO			;pop float from stack
		fmove.\0 (sp)+,\1	;  fpop.(b|w|l|s|d|x|p) <ea>
		ENDM

pushm		MACRO			;push register set to stack
		movem.\0 \1,-(sp)	;  pushm.(w|l) <set>
		ENDM

fpushm		MACRO			;push float register set to stack
		fmovem.x \1,-(sp)	;  fpushm.x <set>
		ENDM

pushem		MACRO			;DevPac compatibility
		movem.\0 \1,-(sp)	;  pushem.(w|l) <set>
		ENDM

topm		MACRO			;top register set
		movem.\0 (sp),\1	;  topm.(w|l) <set>
		ENDM

ftopm		MACRO			;top float register set
		fmovem.\0 (sp),\1	;  ftopm.x <set>
		ENDM

popm		MACRO			;pop register set
		movem.\0 (sp)+,\1	;  popm.(w|l)	<set>
		ENDM

fpopm		MACRO			;pop float register set
		fmovem.\0 (sp)+,\1	;  popm.x   <set>
		ENDM

popem		MACRO			;DevPac compatibility
		movem.\0 (sp)+,\1	;  popem.(w|l)	 <set>
		ENDM

store		MACRO			;Push all registers
		movem.l d0-d7/a0-a6,-(sp)
		ENDM

recall		MACRO			;Restore all registers
		movem.l (sp)+,d0-d7/a0-a6
		ENDM

fstore		MACRO			;Push all float registers
		fmovem.x fp0-fp7,-(SP)
		ENDM

frecall		MACRO			;Restore all float registers
		fmovem.x (SP)+,fp0-fp7
		ENDM

clra		MACRO			;Clear an address (or data) register
		suba.\0 \1,\1		;  clra.w a0
		ENDM

rhi		MACRO			;Return when higher
		bls.b	.jmp\@
		rts
.jmp\@
		ENDM

rls		MACRO			;Return when lower/same
		bhi.b	.jmp\@
		rts
.jmp\@
		ENDM

rcc		MACRO			;Return when carry clear
		bhi.b	.jmp\@
		rts
.jmp\@
		ENDM

rhs		MACRO			;Return when higher/same
		bcs.b	.jmp\@
		rts
.jmp\@
		ENDM

rcs		MACRO			;Return when carry set
		bcc.b	.jmp\@
		rts
.jmp\@
		ENDM

rne		MACRO			;Return when not equal
		beq.b	.jmp\@
		rts
.jmp\@
		ENDM

req		MACRO			;Return when equal
		bne.b	.jmp\@
		rts
.jmp\@
		ENDM

rvc		MACRO			;Return when overflow clear
		bvs.b	.jmp\@
		rts
.jmp\@
		ENDM

rvs		MACRO			;Return when overflow set
		bvc.b	.jmp\@
		rts
.jmp\@
		ENDM

rpl		MACRO			;Return when plus
		bmi.b	.jmp\@
		rts
.jmp\@
		ENDM

rmi		MACRO			;Return when minus
		bpl.b	.jmp\@
		rts
.jmp\@
		ENDM

rge		MACRO			;Return when greater/equal
		blt.b	.jmp\@
		rts
.jmp\@
		ENDM

rlt		MACRO			;Return when less than
		bge.b	.jmp\@
		rts
.jmp\@
		ENDM

rgt		MACRO			;Return when greater than
		ble.b	.jmp\@
		rts
.jmp\@
		ENDM

rle		MACRO			;Return when less/equal
		bgt.b	.jmp\@
		rts
.jmp\@
		ENDM

bsrhi		MACRO			;Branch when higher
		bls.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrls		MACRO			;Branch when lower/same
		bhi.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrcc		MACRO			;Branch when carry clear
		bhi.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrhs		MACRO			;Branch when higher/same
		bcs.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrcs		MACRO			;Branch when carry set
		bcc.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrne		MACRO			;Branch when not equal
		beq.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsreq		MACRO			;Branch when equal
		bne.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrvc		MACRO			;Branch when overflow clear
		bvs.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrvs		MACRO			;Branch when overflow set
		bvc.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrpl		MACRO			;Branch when plus
		bmi.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrmi		MACRO			;Branch when minus
		bpl.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrge		MACRO			;Branch when greater/equal
		blt.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrlt		MACRO			;Branch when less than
		bge.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrgt		MACRO			;Branch when greater than
		ble.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

bsrle		MACRO			;Branch when less/equal
		bgt.b	.jmp\@
		bsr.\0	\1
.jmp\@
		ENDM

flip		MACRO			;flip big<->little endian
		IFC	"\0","L"	;  flip.(w|l)  <data register>
		 ror	#8,\1
		 swap	\1
		 ror	#8,\1
		ELSE
		 IFC	"\0","W"
		  ror	#8,\1
		 ENDC
		ENDC
		ENDM

extbl		MACRO			;extb.l for 68000, auto optimizing
		IFGE	__CPU-68020	;  extbl  <data register>
		 extb.l \1
		ELSE
		 ext.w	\1
		 ext.l	\1
		ENDC
		ENDM

db		MACRO			; db <exp>[,<exp>]  equals dc.b
		REPT	NARG
		dc.b	\+
		ENDR
		ENDM

dw		MACRO			; dw <exp>[,<exp>]  equals dc.w
		REPT	NARG
		dc.w	\+
		ENDR
		ENDM

dl		MACRO			; dl <exp>[,<exp>]  equals dc.l
		REPT	NARG
		dc.l	\+
		ENDR
		ENDM

proc		MACRO			;procedure header
__REG\1		REG	\2		;  proc	 <name>,<registerset>
\1		pushm.l __REG\1
		ENDM

xproc		MACRO			;procedure header with reference
__REG\1		REG	\2		;  xproc  <name>,<registerset>
\1		pushm.l __REG\1
		XDEF	\1
		ENDM

endp		MACRO			;procedure end
		popm.l	__REG\1		;  proc	 <name>
		rts
		ENDM

args		MACRO			;put args on stack
__ARGCNT	SET	NARG		;  args	 <param>,<param>,...
CARG		SET	NARG
		REPT	NARG
		move.l	\-,-(sp)
		ENDR
		ENDM

margs		MACRO			;put more args on stack
__ARGCNT	SET	NARG+__ARGCNT	;  margs  <param>,<param>,...
CARG		SET	NARG
		REPT	NARG
		move.l	\-,-(sp)
		ENDR
		ENDM

unargs		MACRO			;restore from last args
		add.l	#__ARGCNT*4,sp	;  unargs
		ENDM

	; The following macros will define strings in the DATA section!

leastr		MACRO			;  leastr     <string>,<address register>
		lea	string\@,\2
		SAVE
		DATA
string\@	dc.b	\1,0
		even
		RESTORE
		ENDM

peastr		MACRO			;  peastr     <string>
		pea	string\@
		SAVE
		DATA
string\@	dc.b	\1,0
		even
		RESTORE
		ENDM

defstr		MACRO			;  defstr     <label>,<string>
		SAVE
		DATA
\1		dc.b	\2,0
		even
		RESTORE
		ENDM

def		MACRO			; def.(b|w|l) <label>[,<label>...]
		SAVE
		BSS
		REPT	NARG
\+		ds.\0	1
		ENDR
		IFC	"\0","B"
		even
		ENDC
		RESTORE
		ENDM

	; STRING OPERATIONS

copy		MACRO			;  copy.(b|w|l) <src>,<dest>
.loop\@		move.\0 \1,\2
		bne	.loop\@
		ENDM

strln		MACRO			;  strlen.(b|w|l) <str>,<lenreg>
		move.l	\1,\2		;	String pointer is not changed!
.loop\@		tst.\0	(\1)+
		bne	.loop\@
		sub.l	\2,\1
		exg	\2,\1
		IFC	"\0","w"
		 lsr.l	#1,\2
		ENDC
		IFC	"\0","l"
		 lsr.l	#2,\2
		ENDC
		ENDM

	; AMIGA RELATED MACROS

clrrg		MACRO			;  clrrg <hwreg>
		IFGE	__CPU-68010
		 clr.w	$dff000+\1
		ELSE
		 move.w #0,$dff000+\1
		ENDC
		ENDM

setrg		MACRO			;  setrg <ea>,<hwreg>
		move.\0 \1,$dff000+\2
		ENDM

getrg		MACRO			;  getrg <hwreg>,<ea>
		move.w	$dff000+\1,\2
		ENDM

trigger		MACRO			;  trigger <hwreg>
		IFGE	__CPU-68010
		 clr.w	$dff000+\1
		ELSE
		 move.w #0,$dff000+\1
		ENDC
		ENDM

keycode		MACRO			;  keycode <data register>
		not.b	\1
		ror.b	#1,\1
		ENDM

copinit		MACRO			;  copinit
__COPBLT	SET	$8000
__COPBELOW	SET	0
		ENDM

copbfe		MACRO			;  copbfe
__COPBLT	SET	0
		ENDM

copbfd		MACRO			;  copbfd
__COPBLT	SET	$8000
		ENDM

copmove		MACRO			;  copmove <data>,<hwreg>[,<data>,<hwreg>...]
		REPT	NARG>>1
__PARAM1	SET	\+
__PARAM2	SET	\+
		dc.w	__PARAM2&$01FE,__PARAM1
		ENDR
		ENDM

copline		MACRO			;  copline <vp>
		IFGE	\1-256
		 IFEQ	__COPBELOW
		  dc.w	$FFDF,$FFFE
__COPBELOW	  SET	1
		 ENDC
		ENDC
		dc.w	(\1&$FF)<<8|$0F,$7FFE|__COPBLT
		ENDM

copwait		MACRO			;  copwait <hp>,<vp>[,<hpm>,<vpm>]
		IFGE	\2-256
		 IFEQ	__COPBELOW
		  dc.w	$FFDF,$FFFE
__COPBELOW	  SET	1
		 ENDC
		ENDC
		IFEQ	NARG-2
		  dc.w	(((\2)&$FF)<<8)|((\1)>>1)|1,$7FFE|__COPBLT
		ELSE
		  dc.w	(((\2)&$FF)<<8)|((\1)>>1)|1
		  dc.w	((((\4)&$FF)<<8)|((\3)>>1)|__COPBLT)&$FFFE
		ENDC
		ENDM

copskip		MACRO			;  copskip <hp>,<vp>[,<hpm>,<vpm>]
		IFGE	\2-256
		 IFEQ	__COPBELOW
		  dc.w	$FFDF,$FFFE
__COPBELOW	  SET	1
		 ENDC
		ENDC
		IFEQ	NARG-2
		  dc.w	(((\2)&$FF)<<8)|((\1)>>1)|1,$7FFF|__COPBLT
		ELSE
		  dc.w	(((\2)&$FF)<<8)|((\1)>>1)|1
		  dc.w	((((\4)&$FF)<<8)|((\3)>>1)|__COPBLT|1)
		ENDC
		ENDM

coppal		MACRO			;  coppal
		IFEQ	__COPBELOW
		 dc.w	$FFDF,$FFFE
__COPBELOW	 SET	1
		ENDC
		ENDM

copend		MACRO			;  copend
		dc.w	$FFFF,$FFFE
		ENDM

		IFND	FALSE
FALSE		SET	0
		ENDC

		IFND	TRUE
TRUE		SET	-1
		ENDC

		IFND	NULL
NULL		SET	0
		ENDC

getexec		MACRO
		move.l	4.w,\1
		ENDM

*-----------------------------------------------------------*
		ENDC
		
*jEdit: :tabSize=8:indentSize=8:mode=assembly-m68k:
