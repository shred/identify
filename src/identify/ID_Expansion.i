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

**
* Expansion database: Manufacturer
*
		rsreset
manuf_ID	rs.w	1	; Manufacturer ID (difference to the predecessor!)
manuf_Name	rs.w	1	; Manufacturer name (relative to strbase)
manuf_Next	rs.w	1	; Offset to next manufacturer (relative to manuf_ID)
manuf_SIZEOF	rs.w	0

**
* Expansion database: Board
*
		rsreset
board_ID	rs.b	1	; Board ID (difference to the predecessor!)
board_Type	rs.b	1	; Board class (locale ID, 0 indicates a function)
board_Name	rs.w	1	; Board name (relative to strbase) >=0 function, <0 alt name
board_SIZEOF	rs.w	0

**
* Expansion database: Alternate manufacturer
*
		rsreset
altmf_Manuf	rs.w	1	; Manufacturer name (relative to strbase)
altmf_Name	rs.w	1	; Board name (relative to strbase)
altmf_Class	rs.w	1	; Board class (locale ID)
altmf_SIZEOF	rs.w	0

**
* GVP EPC definitions
*
		rsreset
gvp_EPC		rs.b	1	; EPC (difference to predecessor!)
gvp_Class	rs.b	1	; Board class (locale ID)
gvp_Name	rs.w	1	; Board name (relative to strbase)
gvp_SIZEOF	rs.w	0


GVP_EPCMASK	EQU	$F8	; EPC mask for GVP products
