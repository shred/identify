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

*---------------------------------------------------------------*
*       Struktur: Alerts
*
		rsreset
subsys_ID       rs.w    1       ;Object-ID oder -1
subsys_Spec     rs.w    1       ;Spezifischer Fehler (Rel. StrPtr)
subsys_SIZEOF   rs.w    0

		rsreset
general_ID      rs.w    1       ;Alert-ID oder -1
general_Spec    rs.w    1       ;Spezifischer Fehler (Locale-ID)
general_SIZEOF  rs.w    0

		rsreset
alert_ID        rs.l    1       ;Alert-ID oder -1
alert_Spec      rs.w    1       ;Spezifischer Fehler (Locale-ID)
alert_SIZEOF    rs.w    0

		rsreset
object_ID       rs.w    1       ;Object-ID oder -1
object_Spec     rs.w    1       ;Spezifischer Fehler (Rel. StrPtr)
object_SIZEOF   rs.w    0


*---------------------------------------------------------------*
*       Macros zum Erstellen der Tabelle
*
__GLBSUBSYS     SET     0
__GLBGENERAL    SET     0
__GLBALERT      SET     0
__GLBOBJECT     SET     0

ssys            MACRO   ;ID,Spec
__GLBSUBSYS     SET     __GLBSUBSYS+1
		dc.w    \1,ssys\@-strbase
		SAVE
		SECTION strings,DATA
ssys\@           dc.b    \2,0
		IFGT    (*-ssys\@)-50         ;Name zu lang?
		  FAIL  "** Alert-Subsystem-Name zu lang!!!"
		ENDC
		RESTORE
		ENDM

ssdone          MACRO
		dc.w    -1,0
		ENDM

general         MACRO   ;ID,Spec
__GLBGENERAL    SET     __GLBGENERAL+1
		dc.w    \1>>16
		dc.w    \2-MSG_AG_BADPARM
		ENDM

gedone          MACRO
		dc.w    -1,0
		ENDM

alerts          MACRO   ;ID,Spec
__GLBALERT      SET     __GLBALERT+1
		dc.l    \1&$7FFFFFFF
		dc.w    \2-MSG_ACPU_ADDRESSERR
		ENDM

aldone          MACRO
		dc.l    -1
		dc.w    0
		ENDM

object          MACRO   ;ID,Spec
__GLBOBJECT     SET     __GLBOBJECT+1
		dc.w    \1&$7FFF,obj\@-strbase
		SAVE
		SECTION strings,DATA
obj\@           dc.b    \2,0
		IFGT    (*-obj\@)-50         ;Name zu lang?
		  FAIL  "** Alert-Objekt-Name zu lang!!!"
		ENDC
		RESTORE
		ENDM

obdone          MACRO
		dc.w    -1,0
		ENDM

*---------------------------------------------------------------*
*       Includes-Ende
*
