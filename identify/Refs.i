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
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*

	IFND    ID_MAIN
	XREF    identifybase, utilsbase, dosbase, expbase, execbase
	XREF    gfxbase, _SysBase
	ENDC

	IFND    ID_EXPANSION
	XREF    InitExpansion, ExitExpansion, IdExpansion
	ENDC

	IFND    ID_ALERTS
	XREF    IdAlert
	ENDC

	IFND    ID_HARDWARE
	XREF    InitHardware, ExitHardware, IdHardwareNum, IdHardware
	XREF    IdHardwareUpdate, IdFormatString, IdEstimateFormatSize
	ENDC

	IFND    ID_LOCALE
	XREF    InitLocale, ExitLocale, GetLocString, GetNewLocString
	ENDC

	IFND    ID_SUPPORT
	XREF    SPrintF, SPrintSize, Unpack
	ENDC

	IFND    ID_FUNCTIONS
	XREF    InitFunctions, ExitFunctions, IdFunction
	ENDC

	IFND    ID_CLOCKFREQ
	XREF    GetClocks
	ENDC

*jEdit: :tabSize=8:indentSize=8:mode=assembly-m68k:
