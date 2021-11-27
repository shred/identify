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

		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i

*
* ======== Function database =========
*
		rsreset
fnch_Node	rs.b	LN_SIZE
fnch_FList	rs.b	MLH_SIZE
fnch_SIZEOF	rs.w	0

		rsreset
func_Node	rs.b	LN_SIZE
func_Offset	rs.l	1
func_SIZEOF	rs.w	0


*
* ======== String function macros =========
*

**
* Copy a string until terminator.
*
*	copy.(b|w|l) <SRC>,<DEST>
*
*	SRC	-> string source (changed)
*	DEST	-> string destination (changed)
*
copy		MACRO
.loop\@		move.\0 \1,\2
		bne	.loop\@
		ENDM

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
