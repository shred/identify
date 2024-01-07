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

VERSION		EQU	44
REVISION	EQU	0

VERSNR		MACRO
		dc.b	'44.0'
		ENDM

DATE		MACRO
		dc.b	'7.1.2024'
		ENDM

PRGNAME 	MACRO
		dc.b	'identify.library'
		ENDM


VERS		MACRO
		PRGNAME
		dc.b	' '
		VERSNR
		ENDM

VSTR		MACRO
		VERS
		dc.b	' ('
		DATE
		dc.b	')'
		ENDM

VSTRING 	MACRO
		VSTR
		dc.b	13,10,0
		ENDM

VERSTAG 	MACRO
		dc.b	0,'$VER: '
		VSTR
		dc.b	0
		ENDM
