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

		INCLUDE ID_Expansion.i
		INCLUDE ID_Locale.i

		IFD	_MAKE_68020
		  MACHINE 68020
		ENDC

		SECTION text,CODE

**
* Initializes the expansion module.
*
		public	InitExpansion
InitExpansion	movem.l d0-d1/a0,-(SP)
		move.l	(execbase,PC),a0
		moveq	#"6",d0			; Maximum CPU type number (68060)
		move	(AttnFlags,a0),d1
		btst	#AFB_68060,d1
		bne	.done
		subq	#2,d0
		btst	#AFB_68040,d1
		bne	.done
		subq	#1,d0
		btst	#AFB_68030,d1
		bne	.done
		subq	#1,d0
		btst	#AFB_68020,d1
		bne	.done
		subq	#1,d0
		btst	#AFB_68010,d1
		bne	.done
		subq	#1,d0
.done		move.b	d0,cpuchar
		movem.l (SP)+,d0-d1/a0
		rts

**
* Exits the expansion module.
*
		public	ExitExpansion
ExitExpansion	rts

**
* Fetches the name of an expansion from the database.
*
*	-> A0.l	^Tags
*	<- D0.l	Error code
*
		clrfo
exp_TagItem	fo.l	1	; ^^TagItem for NextTagItem()
exp_ConfigDev	fo.l	1	; ^ConfigDev structure
exp_CDevPtr	fo.l	1	; Current ^ConfigDev pointer
exp_ManufID	fo.w	1	; Manufacturer ID
exp_ProdID	fo.w	1	; Product ID
exp_ManufStr	fo.l	1	; ^Manufacturer string
exp_ProdStr	fo.l	1	; ^Product string
exp_ClassStr	fo.l	1	; ^Class string
exp_ClassID	fo.l	1	; ^Class ID string
exp_ReturnCode	fo.l	1	; Return code
exp_UnknownFlag	fo.l	1	; ^Flag if board is unknown
exp_Secondary	fo.b	1	; Secondary warnings
exp_GotID	fo.b	1	; Is it a valid ID for searching?
exp_Localize	fo.b	1	; Is the result to be localized?
exp_Delegate	fo.b	1	; Delegate if unknown?
exp_StrLength	fo.w	1	; String length -1 (i.e. prepared for dbra)
exp_Buffer	fo.b	10	; Temporary buffer
exp_SIZEOF	fo.w	0

		public	IdExpansion
IdExpansion	movem.l d1-d7/a0-a3/a5-a6,-(sp)
		link	a4,#exp_SIZEOF
	;-- clear the structure
		moveq	#((exp_ConfigDev-exp_StrLength)/2)-1,d0
		lea	(exp_ConfigDev,a4),a1
.clear		clr	-(a1)
		dbra	d0,.clear
		move.l	a0,(exp_TagItem,a4)
		move	#49,(exp_StrLength,a4)
		st	(exp_Localize,a4)
		st	(exp_Delegate,a4)
	;-- collect search parameters
.tagloop	lea	(exp_TagItem,a4),a0
		utils	NextTagItem
		tst.l	d0
		beq	.tagdone
		move.l	d0,a0
		move.l	(a0)+,d0		; tag key
		move.l	(a0),d1			; tav value
		sub.l	#IDTAG_ConfigDev,d0			; IDTAG_ConfigDev ?
		beq	.configdev
		subq.l	#IDTAG_ManufID-IDTAG_ConfigDev,d0	; IDTAG_ManufID ?
		beq	.manufid
		subq.l	#IDTAG_ProdID-IDTAG_ManufID,d0		; IDTAG_ProdID ?
		beq	.prodid
		subq.l	#IDTAG_StrLength-IDTAG_ProdID,d0	; IDTAG_StrLength ?
		beq	.strlength
		subq.l	#IDTAG_ManufStr-IDTAG_StrLength,d0	; IDTAG_ManufStr ?
		beq	.manufstr
		subq.l	#IDTAG_ProdStr-IDTAG_ManufStr,d0	; IDTAG_ProdStr ?
		beq	.prodstr
		subq.l	#IDTAG_ClassStr-IDTAG_ProdStr,d0	; IDTAG_ClassStr ?
		beq	.classstr
		subq.l	#IDTAG_Expansion-IDTAG_ClassStr,d0	; IDTAG_Expansion ?
		beq	.expansion
		subq.l	#IDTAG_Secondary-IDTAG_Expansion,d0	; IDTAG_Secondary ?
		beq	.secondary
		subq.l	#IDTAG_ClassID-IDTAG_Secondary,d0	; IDTAG_ClassID ?
		beq	.classid
		subq.l	#IDTAG_Localize-IDTAG_ClassID,d0	; IDTAG_Localize ?
		beq	.localized
		subq.l	#IDTAG_UnknownFlag-IDTAG_Localize,d0	; IDTAG_UnknownFlag ?
		beq	.unkflag
		subq.l	#IDTAG_Delegate-IDTAG_UnknownFlag,d0	; IDTAG_Delegate ?
		beq	.delegate
		bra	.tagloop		; unknown tag, ignore it
	;-- set tags
.configdev	move.l	d1,a5
		move.l	d1,(exp_ConfigDev,a4)
		beq	.tagloop
		move	(cd_Rom+er_Manufacturer,a5),(exp_ManufID,a4)	;Manufacturer
		move.b	(cd_Rom+er_Product,a5),(exp_ProdID+1,a4)	;Product
		st	(exp_GotID,a4)
		bra	.tagloop
.manufid	move	d1,(exp_ManufID,a4)
		st	(exp_GotID,a4)
		bra	.tagloop
.prodid		move.b	d1,(exp_ProdID+1,a4)
		; intentionally no st (..)
		bra	.tagloop
.strlength	subq	#1,d1
		bcs	.err_nolength
		move	d1,(exp_StrLength,a4)
		bra	.tagloop
.manufstr	move.l	d1,(exp_ManufStr,a4)
		bra	.tagloop
.prodstr	move.l	d1,(exp_ProdStr,a4)
		bra	.tagloop
.classstr	move.l	d1,(exp_ClassStr,a4)
		bra	.tagloop
.expansion	tst.l	d1
		beq	.tagloop
		move.l	d1,a2
		move.l	(a2),a0
		moveq	#-1,d0
		moveq	#-1,d1
		expans	FindConfigDev
		move.l	d0,a5
		move.l	d0,(exp_ConfigDev,a4)
		move.l	d0,(a2)
		beq	.err_done
		move	(cd_Rom+er_Manufacturer,a5),(exp_ManufID,a4)	;Manufacturer
		move.b	(cd_Rom+er_Product,a5),(exp_ProdID+1,a4)	;Product
		st	(exp_GotID,a4)
		bra	.tagloop
.secondary	tst.l	d1
		sne	(exp_Secondary,a4)
		bra	.tagloop
.classid	move.l	d1,(exp_ClassID,a4)
		bra	.tagloop
.localized	tst.l	d1
		sne	(exp_Localize,a4)
		bra	.tagloop
.delegate	tst.l	d1
		sne	(exp_Delegate,a4)
		bra	.tagloop
.unkflag	move.l	d1,(exp_UnknownFlag,a4)
		bra	.tagloop
	;-- prepare search
.tagdone	tst.b	(exp_GotID,a4)		; is there anything to search?
		beq	.err_badid
	;-- start search
		move.l	a5,a0
		move	(exp_ManufID,a4),d0
		move	(exp_ProdID,a4),d1
		bsr	GetBoard
		move.l	a1,d1			; do we know this expansion?
		bne	.evaluate
	;-- check boards.lib for unknown boards
		move.l	(exp_UnknownFlag,a4),d1	; unknown flag present?
		beq	.nounkflag
		move.l	d1,a3
		st	(a3)			;   yes: set to true
.nounkflag	move.l	(boardsbase,PC),d1	; boards.lib not present?
		beq	.evaluate		;   just go on with our check
		tst.b	(exp_Delegate,a4)	; do we want to delegate?
		beq	.evaluate		;   no: do not check boards.lib
		cmp	#49,(exp_StrLength,a4)	; boards.lib requires a fixed
		blt	.evaluate		;   50 char buffer
		movem.l	d2-d7/a0-a6,-(sp)
		move.l	d1,a6
		move.l	(exp_ManufStr,a4),a0
		move.l	a0,d0
		bne	.bManufOk		; do we want the manufacturer string?
		lea	(boardsDeadBuffer,PC),a0 ; use dead buffer if not requested
.bManufOk	move.l	(exp_ProdStr,a4),a1
		move.l	a1,d0
		bne	.bProdOk		; do we want the product string?
		lea	(boardsDeadBuffer,PC),a1 ; use dead buffer if not requested
.bProdOk	move.l	(exp_ConfigDev,a4),a2
		move	(exp_ManufID,a4),d0
		move	(exp_ProdID,a4),d1
		moveq	#SB_BUS_NATIVE,d2
		jsr	(GetBoardNameNew,a6)
		move	d0,d1
		movem.l	(sp)+,d2-d7/a0-a6
		move.l	#MSG_EXP_UNKNOWN,d0
		tst	d1
		bne	.proddone		; found something!
	;-- is the manufacturer ID unknown?
.evaluate	tst.l	(exp_ManufStr,a4)	; do we want to have a manuf. anyway?
		beq	.manufdone
		move.l	a0,d1
		bne	.manufok
		moveq	#0,d1
		move	(exp_ManufID,a4),d1	; convert
		bsr	.to_num
	;-- copy
.manufok	move.l	(exp_ManufStr,a4),a2
		move	(exp_StrLength,a4),d1
.manufcopy	move.b	(a0)+,(a2)+
		dbeq	d1,.manufcopy
		clr.b	-(a2)
	;-- is the product ID unknown?
.manufdone	tst.l	(exp_ProdStr,a4)	; do we want to have a product anyway?
		beq	.proddone
		move.l	a1,d1
		bne	.prodok
	;-- evaluate product via node
		bsr	NameFromNode		; do we have a name?
		beq	.prodconv		;   no: just conver the ID
		move.l	d0,a1
		move.l	(exp_ProdStr,a4),a2
		move	(exp_StrLength,a4),d1
.proddotcopy	move.b	(a1)+,d0
		cmp.b	#".",d0			; stop at the period
		bne	.nodot
		moveq	#0,d0			; then terminate
.nodot		move.b	d0,(a2)+
		dbeq	d1,.proddotcopy
		clr.b	-(a2)
		move.l	#MSG_EXP_GUESS,d0	; tell that we could only guess
		bra	.proddone
	;-- give a product ID
.prodconv	moveq	#0,d1
		move	(exp_ProdID,a4),d1
		bsr	.to_num
		move.l	a0,a1
		move.l	#MSG_EXP_UNKNOWN,d0
	;-- copy
.prodok		move.l	(exp_ProdStr,a4),a2
		move	(exp_StrLength,a4),d1
		move.b	(a1),d2			; check for special characters
		cmp.b	#"\241",d2		; is there a secondary meaning?
		bne	.no2nd
		tst.b	(exp_Secondary,a4)	; shall we warn about it?
		beq	.no2ndwarn
		moveq	#IDERR_SECONDARY,d2
		move.l	d2,(exp_ReturnCode,a4)
.no2ndwarn	addq.l	#1,a1
		move.b	(a1),d2
.no2nd		cmp.b	#"\247",d2		; CPU number placeholder?
		beq	.cpu_special
.prodcopy	move.b	(a1)+,(a2)+
		dbeq	d1,.prodcopy
.prod_reentry	clr.b	-(a2)			; <- coming back from cpu_special
	;-- convert class
.proddone	move.l	(exp_ClassID,a4),d1
		beq	.noclassid
		move.l	d1,a2
		move.l	d0,d1
		sub.l	#MSG_EXP_UNKNOWN,d1
		move.l	d1,(a2)
.noclassid	move.l	(exp_ClassStr,a4),d1
		beq	.classdone
		move.l	d1,a2
		move.b	(exp_Localize,a4),d1	; localize?
		bsr	GetNewLocString
		move	(exp_StrLength,a4),d1
.classcopy	move.b	(a0)+,(a2)+
		dbeq	d1,.classcopy
		clr.b	-(a2)
	;-- to be continued...
.classdone
	;-- done
.done		move.l	(exp_ReturnCode,a4),d0
.exit		unlk	a4
		movem.l (sp)+,d1-d7/a0-a3/a5-a6
		rts

	;-- error
.err_nolength	moveq	#IDERR_NOLENGTH,d0	; buffer length is zero
		bra	.exit
.err_badid	moveq	#IDERR_BADID,d0		; bad or missing ID
		bra	.exit
.err_done	moveq	#IDERR_DONE,d0		; done
		bra	.exit

	;-- replace CPU number placeholder
.cpu_special	move.l	d0,-(SP)
		addq.l	#1,a1
		move.l	(exp_ConfigDev,a4),d2
.speccopy	move.b	(a1)+,d0
		cmp.b	#"\247",d0		; placeholder character for CPU number
		bne	.specnocpu
		move.b	(a1)+,d0		; fetch the CPU number
		tst.l	d2			; there is no ConfigDev?
		beq	.specnocpu		; then just use the default CPU number
		move.b	(cpuchar,PC),d0
.specnocpu	move.b	d0,(a2)+
		dbeq	d1,.speccopy
		move.l	(SP)+,d0
		bra	.prod_reentry

	;-- fast converter to number
.to_num		lea	(exp_Buffer+10,a4),a0	; use buffer from end to start
		clr.b	-(a0)			; set a terminator
.divloop	divu	#10,d1			; divide by 10
		swap	d1
		add.b	#"0",d1			; remainder is the number
		move.b	d1,-(a0)
		clr	d1
		swap	d1			; continue with the rest
		bne	.divloop		; until value is zero
		move.b	#"#",-(a0)		; prepend hash
		rts


**
* Finds a board in the expansion database.
*
* Manufacturer and board ID must have a valid range.
*
*	-> A0.l	^ConfigDev or NULL
*	-> D0.w	Manufacturer ID
*	-> D1.b Board ID
*	<- A0.l ^Manufacturer name or NULL
*	<- A1.l ^Board name or NULL
*	<- D0.l Board class ID
*
GetBoard	movem.l d1-d4/a2-a5,-(SP)
		and	#$00ff,d1		; D1.w: Board ID
		lea	strbase,a4		; A4: String-Base
		move.l	a0,a5			; A5: ConfigDev
		sub.l	a0,a0			; A0: Manuf-Name
		sub.l	a1,a1			; A1: Board-Name
	;-- search manufacturer
		lea	manuf_tab,a3		; database start
.loopmanuf	sub	(manuf_ID,a3),d0	; is it the desired manuf. ID?
		beq	.foundmanuf
		bcs	.exit			; not found: exit
		adda.w	(manuf_Next,a3),a3	; not the ID: jump to next node
		bra	.loopmanuf
.foundmanuf	move.l	a4,a0
		adda.w	(manuf_Name,a3),a0	; found: set the manufacturer name
	;-- search board
		move	(manuf_Next,a3),d4	; number of boards of this manuf.
		subq	#manuf_SIZEOF,d4
		addq.l	#manuf_SIZEOF,a3	; ^first board struct
		move.b	d1,d2
.loopboard	subq	#board_SIZEOF,d4	; end reached?
		bcs	.exit
		sub.b	(board_ID,a3),d2	; desired board ID?
		beq	.foundboard
		addq.l	#board_SIZEOF,a3	; next board struct
		bra	.loopboard
.foundboard	move	(board_Name,a3),d2	; fetch board name
		moveq	#0,d0
		move.b	(board_Type,a3),d0	; fetch board type
		beq	.callfct
		move.l	a4,a1
		add.w	d2,a1			; generate board name
		add.l	#MSG_EXP_UNKNOWN-1,d0
	;-- done
.exit		movem.l (SP)+,d1-d4/a2-a5
		rts

	;-- invoke board function
.callfct	tst	d2			; alternate manufacturer?
		bmi	.altmf
	;---- start function
		lea	fcttab,a2
		move.l	(a2,d2.w),a2
		jsr	(a2)			; call board function
		bra	.exit

	;---- alternate manufacturer
.altmf		lea	mftab,a2
		not	d2
		mulu	#altmf_SIZEOF,d2
		adda.w	d2,a2
		move.l	a4,a0
		adda.w	(a2)+,a0
		move.l	a4,a1
		adda.w	(a2)+,a1
		moveq	#0,d0
		move	(a2),d0
		add.l	#MSG_EXP_UNKNOWN,d0
		bra	.exit

**
* Reads the name from a handler node.
*
*	-> A5.l	^ConfigDev or NULL
*	<- D0.l ^Name or NULL (+CCR)
*
		public	NameFromNode
NameFromNode	movem.l d1-d3/d6/a0-a3,-(SP)
		move.l	a5,d0
		beq	.bad			; No ConfigDev, no result
		move.l	(cd_Driver,a5),d3	; ^driver node
		beq	.bad			;   no -> just use number
		btst	#0,d3			; even address?
		bne	.bad			;   no -> something is wrong
		move.l	d3,a1			; is it mapped in RAM?
		exec	TypeOfMem
		tst.l	d0
		beq	.bad			;   no -> something is wrong
		move.l	d3,a0
		move.l	(LN_NAME,a0),d3		; fetch node name
		beq	.bad			;   no driver -> exit
		move.l	d3,a1
		exec	TypeOfMem		; name mapped in RAM?
		tst.l	d0
		beq	.bad			;   no -> something is wrong
		move.l	d3,d0			; +CCR
.exit		movem.l (SP)+,d1-d3/d6/a0-a3
		rts
.bad		moveq	#0,d0
		bra	.exit


*
* ======== COMMON HELPER ROUTINES ========
*

**
* Test if a certain manufacturer/product ID is present.
*
*	-> d0.l	Manufacturer ID
*	-> d1.l	Product ID
*	<- CCR	eq:not present, ne:present
*
		public	isBoardPresent
isBoardPresent	movem.l a0-a1,-(SP)
		sub.l	a0,a0
		expans	FindConfigDev
		tst.l	d0
		movem.l (SP)+,a0-a1
		rts


**
* Tests if we are living in an emulated Amiga.
*
*	<- CCR	eq:yes, ne:no
*
		public	isEmulated
isEmulated	movem.l a0-a1,-(SP)
		moveq	#IDHW_SYSTEM,d0
		sub.l	a0,a0
		bsr	IdHardwareNum
		cmp.l	#IDSYS_UAE,d0
		movem.l (SP)+,a0-a1
		rts

**
* Tests if this is an Amiga 1200.
*
*	<- CCR	eq:yes, ne:no
*
		public	isA1200
isA1200		movem.l d1/a0-a1,-(SP)
		moveq	#IDHW_SYSTEM,d0
		sub.l	a0,a0
		bsr	IdHardwareNum
		cmp.l	#IDSYS_AMIGA1200,d0
		movem.l (SP)+,d1/a0-a1
		rts


*
* ======== VARIABLES ========
*
cpuchar		dc.b	"0"		; CPU type (680#0)
boardsDeadBuffer ds.b	60		; dead space for boards.lib strings, write only
		even
