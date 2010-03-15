*
* identify.library
*
* Copyright (C) 2010 Richard "Shred" Körber
*   http://identify.shredzone.org
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License / GNU Lesser
* General Public License as published by the Free Software Foundation,
* either version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*

		INCLUDE exec/libraries.i
		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i

		rsreset         	;Identify Base
idb_Library     rs.b    LIB_SIZE        ;Library-Node
idb_Flags       rs.w    1               ; Flags)
idb_SysLib      rs.l    1               ; ^SysBase
idb_SegList     rs.l    1               ; ^SegBase
idb_SIZEOF      rs.w    0

IDLB_DELEXP     EQU     0               ;Noch kein Ausstieg
IDLF_DELEXP     EQU     1<<IDLB_DELEXP
