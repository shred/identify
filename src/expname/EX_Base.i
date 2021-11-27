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

		rsreset			; Identify Base
idb_Library	rs.b	LIB_SIZE
idb_Flags	rs.w	1
idb_SysLib	rs.l	1
idb_SegList	rs.l	1
idb_SIZEOF	rs.w	0

IDLB_DELEXP	EQU	0		; do not expunge yet
IDLF_DELEXP	EQU	1<<IDLB_DELEXP
