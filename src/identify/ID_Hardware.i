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


		clrfo
idhws_Tags	fo.l	1	;Tags
idhws_Type	fo.l	1	;Type
idhws_Localize	fo.b	1	;-1: Localisieren
idhws_NullNA	fo.b	1	;-1: Null for NA
idhws_SIZEOF	fo.w	0

**
* Define a hardware string.
*
*	defhws	<Label>,<Name>
*
*	Label	-> string label
*	Name	-> string name
*
defhws		MACRO
		IFNE	\#-2
		  FAIL	"defhws requires 2 arguments!"
		ENDC
\1		EQU	strg\@-strbase
		SECTION strings,DATA
strg\@		dc.b	\2,0
		SECTION text,CODE
		ENDM

*
* ======== Missing Constants ========
*

	; EQUs for the native.library
NATIVE_HOST_OSNAME	EQU	1
NATIVE_HOST_OSVERS	EQU	2
NATIVE_HOST_MACHINE	EQU	4
NATIVE_HOST_CPUID	EQU	5
NATIVE_HOST_CPUSPEED	EQU	6

	; This constant is missing in exec/execbase.h
AFB_FPU60		EQU	6
