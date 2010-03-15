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

		INCLUDE exec/lists.i
		INCLUDE exec/nodes.i

*---------------------------------------------------------------*
*       Struktur: Function
*
		rsreset
fnch_Node       rs.b    LN_SIZE         ;Node
fnch_FList      rs.b    MLH_SIZE        ;Alle Funktionsnodes
fnch_SIZEOF     rs.w    0

		rsreset
func_Node       rs.b    LN_SIZE         ;Node
func_Offset     rs.l    1               ;Offset der Funktion
func_SIZEOF     rs.w    0

*---------------------------------------------------------------*
*       Includes-Ende
*
