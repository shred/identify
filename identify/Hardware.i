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

defhws          MACRO   ;Label, Name
\1              EQU     strg\@-strbase
		SAVE
		SECTION strings,DATA
strg\@          dc.b    \2,0
		RESTORE
		ENDM

*---------------------------------------------------------------*
*       Includes-Ende
*
