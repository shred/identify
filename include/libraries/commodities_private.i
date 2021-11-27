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

		INCLUDE exec/nodes.i

*
* ======== Private Commodity Structures ========
*
		rsreset
bc_Node		rs.b	LN_SIZE
bc_Name		rs.b	CBD_NAMELEN
bc_Title	rs.b	CBD_TITLELEN
bc_Descr	rs.b	CBD_DESCRLEN
bc_Task		rs.l	1
bc_Dummy1	rs.l	1
bc_Dummy2	rs.l	1
bc_Flags	rs.w	1
bc_SIZEOF	rs.w	0

COF_ACTIVE	EQU	2
