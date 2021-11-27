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
		INCLUDE exec/nodes.i

*
* ======== Library Base Structure ========
*

		rsreset
idb_Library	rs.b	LIB_SIZE
idb_Flags	rs.w	1
idb_SysLib	rs.l	1
idb_SegList	rs.l	1
idb_SIZEOF	rs.w	0

IDLB_DELEXP	EQU	0		; delay expunge
IDLF_DELEXP	EQU	1<<IDLB_DELEXP


*
* ======== Helper Macros ========
*

**
* Evaluate string length until terminator.
*
*	strln.(b|w|l) <STR>,<LENREG>
*
*	STR	-> string source (unchanged)
*	LENREG	-> register for result
*
strln		MACRO
		move.l	\1,\2
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
