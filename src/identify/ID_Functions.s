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

		INCLUDE exec/memory.i
		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i
		INCLUDE exec/interrupts.i
		INCLUDE dos/dos.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/dos.i
		INCLUDE lvo/utility.i

		INCLUDE libraries/identify.i

		INCLUDE ID_Functions.i
		INCLUDE ID_Locale.i

		IFD	_MAKE_68020
		  MACHINE 68020
		ENDC

		SECTION strings,DATA
strbase		ds.w	0

		SECTION text,CODE

**
* Initialize the functions module.
*
		public	InitFunctions
InitFunctions	movem.l d0-d1/a0-a1,-(sp)
		lea	(liblist,PC),a0
		NEWLIST a0
	;-- add handler for low-memory situations
		move.l	(execbase,PC),a6
		cmp	#39,(LIB_VERSION,a6)
		blo	.nomh
		lea	(memint,PC),a1
		exec.q	AddMemHandler
	;-- done
.nomh		movem.l (SP)+,d0-d1/a0-a1
		rts

**
* Exit the functions module.
*
		public	ExitFunctions
ExitFunctions	movem.l d0-d7/a0-a6,-(SP)
		move.l	(execbase,PC),a6
		cmp	#39,(LIB_VERSION,a6)
		blo	.nomh
		lea	(memint,PC),a1
		exec.q	RemMemHandler
.nomh		bsr	FreeList
		movem.l (SP)+,d0-d7/a0-a6
		rts

**
* Identify an OS function.
*
*	-> A0.l	^Name of the library
*	-> D0.l Function offset
*	-> A1.l ^Tags
*	<- D0.l Error code
*
		clrfo
fn_LibName	fo.l	1	; ^Library name
fn_Offset	fo.l	1	; Offset
fn_FuncNameStr	fo.l	1	; ^Function name
fn_StrLength	fo.w	1	; String length (-1 for dbra)
fn_SIZEOF	fo.w	0

		public	IdFunction
IdFunction	movem.l d1-d7/a0-a3/a5-a6,-(sp)
		link	a4,#fn_SIZEOF
		move.l	a0,(fn_LibName,a4)
		tst.l	d0			; offset must be negative
		bmi	.isneg
		neg.l	d0			; otherwise negate it
.isneg		move.l	d0,(fn_Offset,a4)
		move.l	a1,a3
	;-- gather all parameters
		move.l	a3,a0
		move.l	#IDTAG_FuncNameStr,d0
		moveq	#0,d1
		utils	GetTagData
		move.l	d0,(fn_FuncNameStr,a4)
		beq	.done
		move.l	a3,a0
		move.l	#IDTAG_StrLength,d0
		moveq	#50,d1
		utils	GetTagData
		subq	#1,d0
		bcs	.err_nolength
		move	d0,(fn_StrLength,a4)
	;-- search table for library
		move.l	(fn_LibName,a4),a0
		bsr	FindTable
		tst.l	d0			; error -> exit
		bne	.exit
	;-- find offset
		move.l	(fn_Offset,a4),d0
		move.l	(fnch_FList,a0),a0
.findloop	tst.l	(a0)			; not found?
		beq	.err_notfound
		cmp.l	(func_Offset,a0),d0	; correct offset
		beq	.found
		move.l	(a0),a0			; next node
		bra	.findloop
	;-- copy function name
.found		move.l	(LN_NAME,a0),a0
		move.l	(fn_FuncNameStr,a4),a1
		move	(fn_StrLength,a4),d0
.copylen	move.b	(a0)+,(a1)+
		dbeq	d0,.copylen
	;-- done
.done		moveq	#0,d0
.exit		unlk	a4
		movem.l (sp)+,d1-d7/a0-a3/a5-a6
		rts
	;-- error
.err_notfound	moveq	#IDERR_OFFSET,d0	; offset was not found
		bra	.exit
.err_nolength	moveq	#IDERR_NOLENGTH,d0	; string length was 0
		bra	.exit

**
* Locate a function table. If the table is not found, it will be generated.
*
*	-> A0.l ^Library name
*	<- D0.l Error code
*	<- A0.l ^fnch structure
*	   A4.l (unchanged)
*
		clrfo
ft_LibName	fo.l	1	; ^Library name
ft_NewNode	fo.l	1	; ^New function node
ft_SIZEOF	fo.w	0

FindTable	link	a4,#ft_SIZEOF
		move.l	a0,(ft_LibName,a4)
	;-- table already present?
		move.l	a0,a1
		lea	(liblist,PC),a0
		exec	FindName
		tst.l	d0			; found -> use it
		bne	.found
	;-- create node
		move.l	(ft_LibName,a4),a2
		strln.b a2,d0			; length of library name
		add.l	#fnch_SIZEOF,d0		; + structure size
		move.l	#MEMF_PUBLIC|MEMF_CLEAR,d1
		exec	AllocVec
		move.l	d0,(ft_NewNode,a4)
		beq	.err_nomem
		move.l	d0,a1
		lea	(fnch_FList,a1),a0	; initialize function table
		NEWLIST a0
		lea	(fnch_SIZEOF,a1),a0
		move.l	a0,(LN_NAME,a1)
		copy.b	(a2)+,(a0)+		; copy name to node
		move.l	(ft_LibName,a4),a0
		lea	(fnch_FList,a1),a1
		bsr	FillNode		; fill table with function nodes
		bne	.err_fill
	;-- add node to list
		move.l	(ft_NewNode,a4),a1
		lea	(liblist,PC),a0
		exec	AddTail
		move.l	(ft_NewNode,a4),d0
	;-- done
.found		move.l	d0,a0
		moveq	#0,d0
.exit		unlk	a4
		rts
	;-- error
.err_fill	move.l	d0,d3			; error while filling the table
		move.l	(ft_NewNode,a4),a1	; release faulty node
		exec	FreeVec
		move.l	d3,d0
		bra	.exit
.err_nomem	moveq	#IDERR_NOMEM,d0		; not enough memory
		bra	.exit

**
* Fill list with library functions.
*
*	-> A0.l ^Library name
*	-> A1.l ^List header
*	<- D0.l Error code (+CCR)
*
MAXLINELEN	EQU	256		; maximum line length

		clrfo
fln_FileName	fo.l	1		; ^name of FD file
fln_FileHandle	fo.l	1		; ^FileHandle
fln_ListHeader	fo.l	1		; ^new function node
fln_CurrOffset	fo.l	1		; current offset
fln_LibName	fo.l	1		; ^Library name
fln_LineBuffer	fo.b	MAXLINELEN	; line buffer
fln_SIZEOF	fo.w	0

FillNode	movem.l d2-d7/a2-a3/a5,-(sp)
		link	a4,#fln_SIZEOF
		move.l	a0,(fln_LibName,a4)
		move.l	a1,(fln_ListHeader,a4)
		move.l	#-6,(fln_CurrOffset,a4) ; start offset is -6
	;-- locate the FD file
		move.l	a0,a2
		strln.b a0,d0			; length of library name
		moveq	#50,d1
		add.l	d1,d0			; add some reserve space
		move.l	#MEMF_PUBLIC,d1
		exec	AllocVec
		move.l	d0,(fln_FileName,a4)
		beq	.err_nomem
		moveq	#0,d7			; counts the iteration
.nameloop	move.l	(fln_FileName,a4),a0
		move	d7,d0
		lea	(.str_fd,PC),a1		; 1st: "FD:"
		subq	#2,d0
		bcs	.pathcopy
		lea	(.str_inc,PC),a1	; 2nd: "INCLUDE:fd/"
		subq	#2,d0
		bcs	.pathcopy
		; to be continued with further FD file paths
		bra	.err_nofile		; FD file could not be found
.pathcopy	copy.b	(a1)+,(a0)+
		subq.l	#1,a0
		move.l	(fln_LibName,a4),a1
.copyloop	move.b	(a1)+,d0
		beq	.copydone
		cmp.b	#".",d0
		beq	.copydone
		move.b	d0,(a0)+
		bra	.copyloop
.copydone	lea	(.str_libfd,PC),a1
		btst	#0,d7
		beq	.suf_ok			; add ".fd" suffix
		add.w	#4,a1
.suf_ok		copy.b	(a1)+,(a0)+		; then try "_lib.fd" suffix
		move.l	(fln_FileName,a4),d1	; file exists?
		move.l	#ACCESS_READ,d2
		dos	Lock
		move.l	d0,d1			; yes -> read
		bne	.file_ok
		addq	#1,d7			; no -> try next file name combination
		bra	.nameloop
.file_ok	dos	UnLock
	;-- open file for reading
		move.l	(fln_FileName,a4),d1
		move.l	#MODE_OLDFILE,d2
		dos	Open
		move.l	d0,(fln_FileHandle,a4)
		beq	.err_dos
	;-- read FD file
.lineloop	move.l	(fln_FileHandle,a4),d1
		lea	(fln_LineBuffer,a4),a0
		move.l	a0,d2
		move.l	#MAXLINELEN-2,d3	; read max buffer len-2 (bug in V36/V37)
		dos	FGets			; read line by line
		tst.l	d0			; EOF reached?
		beq	.checkeof
		lea	(fln_LineBuffer,a4),a0	; read line
		move.b	(a0),d0			; check first char
		cmp.b	#"#",d0			; Escape Char? -> command
		beq	.is_cmd
		cmp.b	#"*",d0			; Comment? -> skip
		beq	.lineloop
		cmp.b	#32,d0			; Control char? -> skip
		bls	.lineloop
	;---- read function name
.findloop	move.b	(a0)+,d0		; read characters
		cmp.b	#"(",d0			; until '(', space or control char
		beq	.foundend
		cmp.b	#32,d0
		bhi	.findloop
.foundend	clr.b	-(a0)			; terminate
	;---- create function node
		lea	(fln_LineBuffer,a4),a2
		strln.b a2,d0			; get line length
		tst.l	d0
		beq	.lineloop		; ignore empty lines
		add.l	#func_SIZEOF,d0		; add structure size
		move.l	#MEMF_PUBLIC|MEMF_CLEAR,d1
		exec	AllocVec		; allocate memory
		tst.l	d0
		beq	.err_nomem2		; error -> no memory
		move.l	d0,a1			; Assemble new node
		move.l	(fln_CurrOffset,a4),(func_Offset,a1) ; function offset
		lea	(func_SIZEOF,a1),a0
		move.l	a0,(LN_NAME,a1)
		copy.b	(a2)+,(a0)+		; copy function name to node
		move.l	(fln_ListHeader,a4),a0
		exec	AddTail			; append to list
	;---- decrement offset
		subq.l	#6,(fln_CurrOffset,a4)
		bra	.lineloop
	;-- possible end of file reached
.checkeof	dos	IoErr
		tst.l	d0
		bne	.err_dos2		; I/O error -> exit
	;-- clean up
.iseof		move.l	(fln_FileHandle,a4),d1	; close file
		dos	Close
		move.l	(fln_FileName,a4),a1	; release file name buffer
		exec	FreeVec
	;-- done
		moveq	#0,d0			; success!
.exit		unlk	a4
		movem.l (sp)+,d2-d7/a2-a3/a5
		tst.l	d0			; +CCR
		rts

	;-- error
.err_nomem2	move.l	(fln_ListHeader,a4),a3	; remove node
.err_freeloop	move.l	(a3),a1
		tst.l	(a1)
		beq	.err_freedone
		move.l	a1,d5
		exec	Remove
		move.l	d5,a1			; release memory
		exec	FreeVec
		bra	.err_freeloop
.err_freedone	moveq	#IDERR_NOMEM,d0		; out of memory
.err_dos2	move.l	d0,d7
		move.l	(fln_FileHandle,a4),d1	; close file
		dos	Close
		bra	.err_free2
.err_dos	dos	IoErr			; I/O error
		move.l	d0,d7
.err_free2	move.l	(fln_FileName,a4),a1	; release file name
		exec	FreeVec
		move.l	d7,d0			; return error
		bra	.exit
.err_nofile	moveq	#IDERR_NOFD,d7		; FD file was not found
		bra	.err_free2
.err_nomem	moveq	#IDERR_NOMEM,d0		; out of memory
		bra	.exit

	;-- handle FD file command
.is_cmd		moveq	#$20,d1
		lea	(1,a0),a1		; skip first hash
		move.b	(a1)+,d0
		cmp.b	#"#",d0			; a second hash?
		bne	.findloop		; no -> not a command, skip line
		move.b	(a1)+,d0		; read first character
		or.b	d1,d0			; lowercase
		cmp.b	#"e",d0			; _e_nd?
		beq	.is_end
		cmp.b	#"b",d0			; _b_ias?
		beq	.is_bias
		bra	.lineloop		; unknown/uninteresting, ignore line
	;---- ##bias
.is_bias	move.b	(a1)+,d0
		or.b	d1,d0
		cmp.b	#"i",d0			; b_i_as?
		bne	.lineloop
		move.b	(a1)+,d0
		or.b	d1,d0
		cmp.b	#"a",d0			; bi_a_s?
		bne	.lineloop
		move.b	(a1)+,d0
		or.b	d1,d0
		cmp.b	#"s",d0			; bia_s_?
		bne	.lineloop
		move.l	a1,d1
		clr.l	-(sp)			; read offset
		move.l	sp,d2
		dos	StrToLong		; convert string to number
		move.l	(sp)+,d0
		bmi	.set_new_off		; negate if positive
		neg.l	d0
.set_new_off	move.l	d0,(fln_CurrOffset,a4)	; this is our new offset
		bra	.lineloop
	;---- ##end
.is_end		move.b	(a1)+,d0
		or.b	d1,d0
		cmp.b	#"n",d0			; e_n_d?
		bne	.lineloop
		move.b	(a1)+,d0
		or.b	d1,d0
		cmp.b	#"d",d0			; en_d_?
		bne	.lineloop
		bra	.iseof			; yes -> stop reading the file

.str_libfd	dc.b	"_lib.fd",0
.str_fd		dc.b	"FD:",0
.str_inc	dc.b	"INCLUDE:FD/",0
		even

**
* Free the functions database.
*
FreeList	movem.l d0-d3/d7/a0-a4,-(sp)
	;-- iterate through list
		move.l	(liblist,PC),a4
.loop1		tst.l	(a4)
		beq	.done
	;-- iterate through function records
		move.l	(fnch_FList,a4),a3
.loop2		tst.l	(a3)
		beq	.done2
	;-- release function node
		move.l	a3,a1
		move.l	(a3),a3
		move.l	a1,d7
		exec	Remove			; remove node
		move.l	d7,a1
		exec	FreeVec			; free node memory
		bra	.loop2
	;-- release library node
.done2		move.l	a4,a1
		move.l	(a4),a4
		move.l	a1,d7
		exec	Remove			; remove library node
		move.l	d7,a1
		exec	FreeVec			; free node memory
		bra	.loop1
	;-- done
.done		movem.l (sp)+,d0-d3/d7/a0-a4
		rts

**
* Handle Low Memory situations by freeing the functions database.
*
*	-> A0.l	^MemHandlerData
*	-> A1.l ^is_Data
*	<- D0.l MemHandler result
*
LMHFreeList	bsr	FreeList		; just release the database
		moveq	#MEM_ALL_DONE,d0	; that's all we can do
		rts


*
* ======== Variables ========
*
		cnop	0,4
liblist		ds.b	MLH_SIZE		; list of all functions
memint		dc.l	0,0			; memory handler structure
		dc.b	NT_INTERRUPT,1
		dc.l	.name,0,LMHFreeList
.name		dc.b	"Identify MemHandler",0
		even
