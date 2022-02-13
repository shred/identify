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
		INCLUDE dos/dos.i
		INCLUDE libraries/configregs.i
		INCLUDE libraries/configvars.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/expansion.i
		INCLUDE lvo/dos.i

		INCLUDE ID_Base.i
		INCLUDE ID_Locale.i

		INCLUDE identify.library_rev.i

		IFD	_MAKE_68020
		  MACHINE 68020
		ENDC

		SECTION text,CODE

**
* Initialize library
*
Start		moveq	#0,d0
		rts

**
* Describe library
*
InitDDescrip	dc.w	RTC_MATCHWORD
		dc.l	InitDDescrip
		dc.l	EndCode
		dc.b	RTF_AUTOINIT,VERSION,NT_LIBRARY,0
		dc.l	libname,libidstring,Init
libname		PRGNAME
		dc.b	0
libidstring	VSTRING
		VERS
		IFD	_MAKE_68020
		 dc.b	" 68020"
		ENDC
		dc.b	13,10,0
		even

**
* Copyright note for hex reader
*
		dc.b	"(C) 1996-2022 Richard 'Shred' K\xF6rber ",$a
		dc.b	"License: GNU Lesser General Public License v3 ",$a
		dc.b	"Source: https://identify.shredzone.org",0
		even
		cnop	0,4


**
* Init table
*
Init		dc.l	idb_SIZEOF,FuncTab,DataTab,InitFct


**
* Function table. Keep this order, only append!
*
FuncTab		dc.l	LOpen,LClose,LExpunge,LNull	; Standard functions
		dc.l	IdExpansion			; -30
		dc.l	IdHardware			; -36
		dc.l	IdAlert				; -42
		dc.l	IdFunction			; -48
		dc.l	IdHardwareNum			; -54
		dc.l	IdHardwareUpdate		; -60
		dc.l	IdFormatString			; -66
		dc.l	IdEstimateFormatSize		; -72
		dc.l	-1


**
* Data table
*
DataTab		INITBYTE	 LN_TYPE,NT_LIBRARY
		INITLONG	 LN_NAME,libname
		INITBYTE	 LIB_FLAGS,LIBF_SUMUSED|LIBF_CHANGED
		INITWORD	 LIB_VERSION,VERSION
		INITWORD	 LIB_REVISION,REVISION
		INITLONG	 LIB_IDSTRING,libidstring
		dc.l	0


**
* Initialize library
*
*	-> D0.l	^LibBase
*	-> A0.l	^SegList
*	-> A6.l	^SysLibBase
*	<- D0.l	^LibBase
*
InitFct		movem.l d1-d7/a0-a6,-(SP)
	;-- remember vectors
		move.l	d0,a5
		move.l	d0,identifybase
		move.l	a6,(idb_SysLib,a5)
		move.l	a6,execbase
		move.l	a0,(idb_SegList,a5)
	;-- open resources
		lea	(.utilsname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,utilsbase
		beq	.error1
		lea	(.dosname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,dosbase
		beq	.error1
		lea	(.expname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,expbase
		beq	.error1
		lea	(.gfxname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,gfxbase
		beq	.error1
		lea	(.boardsname,PC),a1
		moveq	#3,d0
		exec	OpenLibrary
		move.l	d0,boardsbase		; OK if it was not found
	;-- initialize modules
		bsr	InitLocale
		bsr	InitExpansion
		bsr	InitHardware
		bsr	InitFunctions
	;-- done
		move.l	a5,d0
.exit		movem.l (SP)+,d1-d7/a0-a6
		rts

	;-- error
.error1		moveq	#0,d0
		bra	.exit

.utilsname	dc.b	"utility.library",0
.expname	dc.b	"expansion.library",0
.dosname	dc.b	"dos.library",0
.gfxname	dc.b	"graphics.library",0
.boardsname	dc.b	"boards.library",0
		even


**
* Open library
*
*	-> D0.l	Version
*	-> A6.l	^LibBase
*	<- D0.l	^LibBase if successful
*
LOpen		addq	#1,(LIB_OPENCNT,a6)
		bclr	#IDLB_DELEXP,(idb_Flags+1,a6)
		move.l	a6,d0
		rts


**
* Close library
*
*	-> A6.l	^LibBase
*	<- D0.l	^SegList or 0
*
LClose		moveq	#0,d0
		subq	#1,(LIB_OPENCNT,a6)
		bne	.notlast
		btst	#IDLB_DELEXP,(idb_Flags+1,a6)
		beq	.notlast
		bsr	LExpunge
.notlast	rts


**
* Expunge library
*
*	-> A6.l	^LibBase
*
LExpunge	movem.l d7/a5-a6,-(SP)
	;-- check state
		move.l	a6,a5
		move.l	(idb_SysLib,a5),a6
		tst	(LIB_OPENCNT,a5)	; still opened?
		beq	.expimmed
.abort		bset	#IDLB_DELEXP,(idb_Flags+1,a5)	; remember to expunge
		moveq	#0,d0
		bra	.exit
	;-- close library
.expimmed	move.l	(idb_SegList,a5),d7
		move.l	a5,a1
		exec	Remove
	;-- exit modules
		bsr	ExitFunctions
		bsr	ExitHardware
		bsr	ExitExpansion
		bsr	ExitLocale
	;-- close resources
		move.l	(boardsbase,PC),d0
		beq	.noBoards
		move.l	d0,a1
		exec	CloseLibrary
.noBoards	move.l	(gfxbase,PC),a1
		exec	CloseLibrary
		move.l	(expbase,PC),a1
		exec	CloseLibrary
		move.l	(utilsbase,PC),a1
		exec	CloseLibrary
		move.l	(dosbase,PC),a1
		exec	CloseLibrary
	;-- release memory
		moveq	#0,d0
		move.l	a5,a1
		move	(LIB_NEGSIZE,a5),d0
		sub.l	d0,a1
		add	(LIB_POSSIZE,a5),d0
		exec	FreeMem
	;-- done
		move.l	d7,d0
.exit		movem.l (SP)+,d7/a5-a6
		rts


**
* Do nothing
*
LNull		moveq	#0,d0
		rts



		public	identifybase, utilsbase, dosbase, expbase, execbase, gfxbase
		public	boardsbase, _SysBase

		even
identifybase	dc.l	0
dosbase		dc.l	0
utilsbase	dc.l	0
execbase	dc.l	0
expbase		dc.l	0
gfxbase		dc.l	0
boardsbase	dc.l	0
_SysBase	EQU	execbase
		even
