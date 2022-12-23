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

VERSION		EQU	41
REVISION	EQU	0

DATE		MACRO
		dc.b	'23.12.2022'
		ENDM

PRGNAME 	MACRO
		dc.b	'identify.library'
		ENDM

VERS		MACRO
		dc.b	'identify.library 41.0'
		ENDM

VSTRING 	MACRO
		dc.b	'identify.library 41.0 (23.12.2022)',13,10,0
		ENDM

VERSTAG 	MACRO
		dc.b	0,'$VER: identify.library 41.0 (23.12.2022)',0
		ENDM

VSTR		MACRO
		dc.b	'identify.library 41.0 (23.12.2022)'
		ENDM
