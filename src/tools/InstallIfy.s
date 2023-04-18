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

		INCLUDE exec/ports.i
		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i
		INCLUDE dos/dos.i
		INCLUDE dos/rdargs.i
		INCLUDE dos/var.i
		INCLUDE utility/tagitem.i
		INCLUDE libraries/identify.i
		INCLUDE lvo/exec.i
		INCLUDE lvo/dos.i
		INCLUDE lvo/identify.i

IDENTIFYVER	EQU	40

VERSION		MACRO
		  dc.b	"2.0"
		ENDM
DATE		MACRO
		  dc.b	"18.04.2023"
		ENDM

		SECTION text,CODE

Start	;-- open resources
		lea	(dosname,PC),a1
		moveq	#36,d0
		exec	OpenLibrary
		move.l	d0,dosbase
		beq	.error1
	;-- read parameters
		lea	(template,PC),a0
		move.l	a0,d1
		lea	(ArgList,PC),a0
		move.l	a0,d2
		moveq	#0,d3
		dos	ReadArgs
		move.l	d0,args
		bne	.arg_ok
		bsr	help
		bra	.error2
	;-- open identify
.arg_ok		lea	(identifyname,PC),a1
		moveq	#IDENTIFYVER,d0
		exec	OpenLibrary
		move.l	d0,identifybase
		bne	.gotid
		lea	(msg_noidentify,PC),a0
		move.l	a0,d1
		pea	IDENTIFYVER.w
		move.l	SP,d2
		dos	VPrintf
		addq.l	#4,SP
		bra	.error3
	;-- let's work
.gotid		moveq	#0,d7
		move.l	(ArgList+arg_Update,PC),d0 	; Update?
		beq	.noupdate
		idfy	IdHardwareUpdate
		bra	.done
.noupdate	move.l	(ArgList+arg_Help,PC),d0	; Help?
		beq	.nohelp
		bsr	help
		bra	.done
.nohelp		move.l	(ArgList+arg_Field,PC),d0 	; Field name
		beq	.error4
		move.l	d0,a0
		lea	(str_table,PC),a1
		bsr	strtoidx
		tst.l	d0
		bpl	.field_ok
		lea	(msg_unknownfield,PC),a0
		move.l	a0,d1
		move.l	(ArgList+arg_Field,PC),-(SP)
		move.l	SP,d2
		dos	VPrintf
		addq.l	#4,SP
		bra	.error4
	;-- which mode?
	; D0.l: the desired hardware field
.field_ok	move.l	(ArgList+arg_Env,PC),d6
		bne	.env_mode
	;-- classic: return as return code
		sub.l	a0,a0
		idfy	IdHardwareNum
		move.l	d0,d7
		bra	.done
	;-- env mode: return as env variable
	; D0.l: the desired hardware field
.env_mode	move.l	(ArgList+arg_Numerical,PC),d1
		beq	.env_string
	;-- env mode as numerical
		sub.l	a0,a0
		idfy	IdHardwareNum
		move.l	d0,-(sp)
		lea	(numformat,PC),a0
		move.l	sp,a1
		lea	(.rawdoproc,PC),a2
		lea	(numformatbuf,PC),a3
		exec	RawDoFmt
		addq.l	#4,sp
		lea	(numformatbuf,PC),a0
		move.l	a0,d2
		move.l	d6,d1
		moveq	#-1,d3				; null terminated
		move.l	#GVF_LOCAL_ONLY,d4
		dos	SetVar
		moveq	#0,d7				; rc = 0
		bra	.done
	;-- env mode as string
	; D0.l: the desired hardware field
.env_string	lea	(.envstringtags),a0
		idfy	IdHardware
		move.l	d0,d2
		move.l	d6,d1
		moveq	#-1,d3				; null terminated
		move.l	#GVF_LOCAL_ONLY,d4
		dos	SetVar
		moveq	#0,d7				; rc = 0
	;-- done
.done		move.l	(identifybase,PC),a1
		exec	CloseLibrary
		move.l	(args,PC),d1
		dos	FreeArgs
		move.l	(dosbase,PC),a1
		exec	CloseLibrary
		move.l	d7,d0
.exit		rts
	;-- rawdofmt
.rawdoproc	move.b	d0,(a3)+
		rts

	;-- error
.error4		move.l	(identifybase,PC),a1
		exec	CloseLibrary
.error3		move.l	(args,PC),d1
		dos	FreeArgs
.error2		move.l	(dosbase,PC),a1
		exec	CloseLibrary
.error1		moveq	#0,d0
		bra.b	.exit

.envstringtags	dc.l	IDTAG_Localize, 0		; always English
		dc.l	TAG_DONE

	;-- show help
help		lea	(msg_help,PC),a0
		move.l	a0,d1
		dos	PutStr
		rts


str_table	dc.b	"SYSTEM",0
		dc.b	"CPU",0
		dc.b	"FPU",0
		dc.b	"MMU",0
		dc.b	"OSVER",0
		dc.b	"EXECVER",0
		dc.b	"WBVER",0
		dc.b	"ROMSIZE",0
		dc.b	"CHIPSET",0
		dc.b	"GFXSYS",0
		dc.b	"CHIPRAM",0
		dc.b	"FASTRAM",0
		dc.b	"RAM",0
		dc.b	"SETPATCHVER",0
		dc.b	"AUDIOSYS",0
		dc.b	"OSNR",0
		dc.b	"VMMCHIPRAM",0
		dc.b	"VMMFASTRAM",0
		dc.b	"VMMRAM",0
		dc.b	"PLNCHIPRAM",0
		dc.b	"PLNFASTRAM",0
		dc.b	"PLNRAM",0
		dc.b	"VBR",0
		dc.b	"LASTALERT",0
		dc.b	"VBLANKFREQ",0
		dc.b	"POWERFREQ",0
		dc.b	"ECLOCK",0
		dc.b	"SLOWRAM",0
		dc.b	"GARY",0
		dc.b	"RAMSEY",0
		dc.b	"BATTCLOCK",0
		dc.b	"CHUNKYPLANAR",0
		dc.b	"POWERPC",0
		dc.b	"PPCCLOCK",0
		dc.b	"CPUREV",0
		dc.b	"CPUCLOCK",0
		dc.b	"FPUCLOCK",0
		dc.b	"RAMACCESS",0
		dc.b	"RAMWIDTH",0
		dc.b	"RAMCAS",0
		dc.b	"RAMBANDWIDTH",0
		dc.b	"TCPIP",0
		dc.b	"PPCOS",0
		dc.b	"AGNUS",0
		dc.b	"AGNUSMODE",0
		dc.b	"DENISE",0
		dc.b	"DENISEREV",0
		dc.b	"BOINGBAG",0
		dc.b	"EMULATED",0
		dc.b	"XLVERSION",0
		dc.b	"HOSTOS",0
		dc.b	"HOSTVERS",0
		dc.b	"HOSTMACHINE",0
		dc.b	"HOSTCPU",0
		dc.b	"HOSTSPEED",0
		dc.b	"LASTALERTTASK",0
		dc.b	"PAULA",0
		dc.b	"ROMVER",0
		dc.b	"RTC",0
		dc.b	0
		even

**
* Convert string to index.
*
*	-> A0.l	^String (until next space)
*	-> A1.l ^List of strings
*	<- D0.l Index of match or -1:not found
*	<- A0.l ^Position after the match
*
strtoidx	 movem.l d1-d2/a1-a2,-(SP)
	;-- init
		moveq	#-1,d0			; Index -1
		move.l	a0,a2
	;-- outer: iterate through list
.nexttry	addq.l	#1,d0
		tst.b	(a1)			; Last entry
		beq	.not_found
		move.l	a2,a0
	;-- inner: compare string
.cmploop	move.b	(a0)+,d2
		cmp.b	#'a',d2			; to uppercase
		blo.b	.updone
		cmp.b	#'z',d2
		bhi.b	.updone
		sub.b	#$20,d2
.updone		move.b	(a1)+,d1
		beq	.test_found
		cmp.b	d2,d1			; match
		beq	.cmploop
	;-- next list entry
.skip		tst.b	(a1)+
		bne	.skip
		bra	.nexttry
	;-- found?
.test_found	subq.l	#1,a0			; point to first mismatch
		tst.b	d2			; terminator?
		beq	.done
		cmp.b	#' ',d2			; space?
		beq	.done
		cmp.b	#'=',d2			; equal?
		beq	.done
		bra	.nexttry
	;-- string not found
.not_found	moveq	#-1,d0
.done		movem.l (SP)+,d1-d2/a1-a2
		rts



*
* ======== Variables ========
*
version		dc.b	0,"$VER: InstallIfy V"
		VERSION
		dc.b	" ("
		DATE
		dc.b	")",$d,$a,0
		even

dosbase		dc.l	0
identifybase	dc.l	0
args		dc.l	0

	;-- Arguments
		rsreset
arg_Field	rs.l	1
arg_Env		rs.l	1
arg_Numerical	rs.l	1
arg_Update	rs.l	1
arg_Help	rs.l	1
arg_SIZEOF	rs.w	0

ArgList		ds.b	arg_SIZEOF
template	dc.b	"FIELD,E=ENV/K,N=NUMERICAL/S,U=UPDATE/S,H=HELP/S",0

numformat	dc.b	"%lu",0
numformatbuf	ds.b	30

versionstr	VERSION
		dc.b	0

dosname		dc.b	"dos.library",0
identifyname	dc.b	"identify.library",0
msg_noidentify	dc.b	"** identify.library V%ld or higher required!\n",0
msg_unknownfield dc.b	"** unknown field name '%s'\n",0

msg_help	dc.b	"InstallIfy V"
		VERSION
		dc.b	" (C) 1999-2023 Richard K\xF6rber - https://identify.shredzone.org\n\n"
		dc.b	"  FIELD     One of the IdHardwareNum fields, see AutoDocs.\n"
		dc.b	"            Example: ""CPU"", ""System"", ""mmu"".\n"
		dc.b	"  ENV       Set the given ENV variable name instead of the\n"
		dc.b	"            return code. Use this if you want to use\n"
		dc.b	"            InstallIfy in CLI scripts.\n"
		dc.b	"  NUMERICAL Set the ENV variable with a numerical result\n"
		dc.b	"            (identical to the return code).\n"
		dc.b	"  UPDATE    Update the information database.\n"
		dc.b	"  HELP      Show this page\n\n"
		dc.b	"The result is returned as DOS return code. See the INCLUDE file\n"
		dc.b	"for its meanings.\n",0
		even

