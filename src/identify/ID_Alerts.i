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

*
* ======== Alert database structure =========
*
		rsreset
subsys_ID	rs.w	1	; Object-ID or -1
subsys_Spec	rs.w	1	; Specific error (relative to StrPtr)
subsys_SIZEOF	rs.w	0

		rsreset
general_ID	rs.w	1	; Alert-ID or -1
general_Spec	rs.w	1	; Specific error (Locale ID)
general_SIZEOF	rs.w	0

		rsreset
alert_ID	rs.l	1	; Alert-ID or -1
alert_Spec	rs.w	1	; Specific error (Locale ID)
alert_SIZEOF	rs.w	0

		rsreset
object_ID	rs.w	1	; Object-ID or -1
object_Spec	rs.w	1	; Specific error (relative to StrPtr)
object_SIZEOF	rs.w	0


*
* ======== Macros for creating the database ========
*
__GLBSUBSYS	SET	0
__GLBGENERAL	SET	0
__GLBALERT	SET	0
__GLBOBJECT	SET	0

**
* Define a subsystem.
*
*	ssys	<ID>,<Spec>
*
*	ID	-> Identifier
*	Spec	-> Specific error
*
ssys		MACRO
		IFNE	\#-2
		  FAIL	"ssys requires 2 arguments!"
		ENDC
__GLBSUBSYS	SET	__GLBSUBSYS+1
		dc.w	\1,ssys\@-strbase
		SECTION strings,DATA
ssys\@		dc.b	\2,0
		IFGT	(*-ssys\@)-50
		  FAIL	"subsystem error is longer than 50 characters!"
		ENDC
		SECTION tables,DATA
		ENDM

**
* End a subsystem.
*
ssdone		MACRO
		dc.w	-1,0
		ENDM

**
* Define a general error.
*
*	ssys	<ID>,<Spec>
*
*	ID	-> Identifier
*	Spec	-> Specific error
*
general		MACRO
		IFNE	\#-2
		  FAIL	"general requires 2 arguments!"
		ENDC
__GLBGENERAL	SET	__GLBGENERAL+1
		dc.w	\1>>16
		dc.w	\2-MSG_AG_BADPARM
		ENDM

**
* End a general error.
*
gedone		MACRO
		dc.w	-1,0
		ENDM

**
* Define an alert.
*
*	ssys	<ID>,<Spec>
*
*	ID	-> Identifier
*	Spec	-> Specific error
*
alerts		MACRO
		IFNE	\#-2
		  FAIL	"alerts requires 2 arguments!"
		ENDC
__GLBALERT	SET	__GLBALERT+1
		dc.l	\1&$7FFFFFFF
		dc.w	\2-MSG_ACPU_ADDRESSERR
		ENDM

**
* End an alert.
*
aldone		MACRO
		dc.l	-1
		dc.w	0
		ENDM

**
* Define an object.
*
*	ssys	<ID>,<Spec>
*
*	ID	-> Identifier
*	Spec	-> Specific error
*
object		MACRO
		IFNE	\#-2
		  FAIL	"object requires 2 arguments!"
		ENDC
__GLBOBJECT	SET	__GLBOBJECT+1
		dc.w	\1&$7FFF,obj\@-strbase
		SECTION strings,DATA
obj\@		dc.b	\2,0
		IFGT	(*-obj\@)-50		;Name zu lang?
		  FAIL	"alert object name is longer than 50 characters!"
		ENDC
		SECTION tables,DATA
		ENDM

**
* End an object.
*
obdone		MACRO
		dc.w	-1,0
		ENDM
