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


*
* ======== MACROS ========
*
* These macros are used to create the expansion database, and other structures.
*

**
* Initializes the database.
*
tabinit		MACRO
__GLBMANUF	SET	0	; Global counter of manufacturers
__GLBBOARD	SET	0	; Global counter of boards
__CURRMANUF	SET	0	; Current manufacturer ID
__FCODENR	SET	0	; Current function number
__ALTMFNR	SET	-1	; Alternate manufacturer number
		ENDM

**
* Starts a new manufacturer block.
*
* 	manuf <ID>,<Name>
*
*	ID	-> Manufacturer ID
*	Name	-> Manufacturer Name
*
manuf		MACRO
		IFNE	\#-2
		  FAIL	"manuf requires 2 arguments!"
		ENDC
__GLBMANUF	SET	__GLBMANUF+1
__BCOUNTER	SET	manuf_SIZEOF
		dc.w	\1-__CURRMANUF,manuf\@-strbase,__BOARD_\1
__CURRMANUF	SET	\1
__CURRBOARD	SET	0
		SECTION strings,DATA
manuf\@		dc.b	\2,0
		IFGT	(*-manuf\@)-50
		  FAIL	"Manufacturer name is longer than 50 characters!"
		ENDC
		SECTION tables,DATA
		ENDM

**
* Defines a board within the manufacturer block.
*
*	board	<ProdID>,<Name>,<Type>
*
*	ProdId	-> Board ID
*	Name	-> Board Name
*	Type	-> Board Type Code
*
board		MACRO
		IFNE	\#-3
		  FAIL	"board requires 3 arguments!"
		ENDC
__GLBBOARD	SET	__GLBBOARD+1
__BCOUNTER	SET	__BCOUNTER+board_SIZEOF
		dc.b	\1-__CURRBOARD
		dc.b	\3-MSG_EXP_UNKNOWN+1
		dc.w	board\@-strbase
__CURRBOARD	SET	\1
		SECTION strings,DATA
board\@		dc.b	\2,0
		IFGT	(*-board\@)-50
		  FAIL	"Board name is longer than 50 characters!"
		ENDC
		SECTION tables,DATA
		ENDM

**
* Defines a board function within the manufacturer block.
*
*	boardf	<ProdId>,<Func>
*
*	ProdId	-> Board ID
*	Func	-> Pointer to Function
*
boardf		MACRO
		IFNE	\#-2
		  FAIL	"boardf requires 2 arguments!"
		ENDC
__BCOUNTER	SET	__BCOUNTER+board_SIZEOF
		dc.b	\1-__CURRBOARD,0
		dc.w	__FCODENR
__FCODENR	SET	__FCODENR+4
__CURRBOARD	SET	\1
		SECTION function,CODE
		dc.l	\2
		SECTION tables,DATA
		ENDM

**
* Defines a board with an alternate manufacturer name.
*
*	boarda	<ProdId>,<Manuf>,<Name>,<Type>
*
*	ProdId	-> Board ID
*	Manuf	-> Manufacturer Name
*	Name	-> Board Name
*	Type	-> Board Type Code
*
boarda		MACRO
		IFNE	\#-4
		  FAIL	"boarda requires 4 arguments!"
		ENDC
__GLBBOARD	SET	__GLBBOARD+1
__BCOUNTER	SET	__BCOUNTER+board_SIZEOF
		dc.b	\1-__CURRBOARD,0
		dc.w	__ALTMFNR
__CURRBOARD	SET	\1
__ALTMFNR	SET	__ALTMFNR-1
		SECTION strings,DATA
manuf\@		dc.b	\2,0
		IFGT	(*-manuf\@)-50
		  FAIL	"Alternate manufacturer name is longer than 50 characters!"
		ENDC
board\@		dc.b	\3,0
		IFGT	(*-board\@)-50
		  FAIL	"Alternate board name is longer than 50 characters!"
		ENDC
		SECTION altmf,CODE
		dc.w	manuf\@-strbase
		dc.w	board\@-strbase
		dc.w	\4-MSG_EXP_UNKNOWN
		SECTION tables,DATA
		ENDM

**
* Closes a manufacturer block.
*
*	endmf	<ID>[,<END>]
*
*	ID	-> Manufacturer ID
*	END	-> Optional: Final manufacturer definition
*
endmf		MACRO
		dc.b	-1,0
__BOARD_\1	EQU	__BCOUNTER+2
		IFNE	NARG-1
		dc.w	32767
		ENDC
		ENDM

**
* Defines a board name and type.
*
*	defstr <Label>,<Name>,<Type>
*
*	Label	-> Assembler label to be used for the string
*	Name	-> Board name
*	Type	-> Board type
*
defstr		MACRO
		IFNE	\#-3
		  FAIL	"defstr requires 3 arguments!"
		ENDC
__GLBBOARD	SET	__GLBBOARD+1
str_\1		EQU	board\@-strbase
typ_\1		EQU	\3
		SECTION strings,DATA
board\@		dc.b	\2,0
		IFGT	(*-board\@)-50
		  FAIL	"defstr: board name is longer than 50 characters!"
		ENDC
		SECTION text,CODE
		ENDM

**
* Defines a board name only.
*
*	defstr2 <Label>,<Name>
*
*	Label	-> Assembler label to be used for the string
*	Name	-> Board name
*
defstr2		MACRO	;Label, Name
		IFNE	\#-2
		  FAIL	"defstr2 requires 2 arguments!"
		ENDC
str_\1		EQU	board\@-strbase
		SECTION strings,DATA
board\@		dc.b	\2,0
		IFGT	(*-board\@)-50	;Name zu lang?
		  FAIL	"defstr2: board name is longer than 50 characters!"
		ENDC
		SECTION text,CODE
		ENDM

**
* Initializes the GVP data structure.
*
gvpinit		MACRO
__CURREPC	SET	0
		ENDM

**
* Defines a GVP EPC.
*
*	gvpepc	<EPC>,<Name>,<Type>
*
*	EPC	-> EPC number
*	Name	-> Board name
*	Type	-> Board type
*
gvpepc		MACRO
		IFNE	\#-3
		  FAIL	"gvpepc requires 3 arguments!"
		ENDC
__GLBBOARD	SET	__GLBBOARD+1
__BCOUNTER	SET	__BCOUNTER+board_SIZEOF
		dc.b	\1-__CURREPC
		dc.b	\3-MSG_EXP_UNKNOWN+1
		dc.w	board\@-strbase
__CURREPC	SET	\1
		SECTION strings,DATA
board\@		dc.b	\2,0
		IFGT	(*-board\@)-50
		  FAIL	"gvpepc: board name exceeds 50 characters!"
		ENDC
		SECTION text,CODE
		ENDM

**
* Ends the GVP data structure.
*
gvpend		MACRO
		dc.b	-1,0
		ENDM
