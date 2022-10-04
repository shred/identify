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

		INCLUDE exec/execbase.i
		INCLUDE libraries/configregs.i
		INCLUDE libraries/configvars.i
		INCLUDE lvo/exec.i

		INCLUDE libraries/identify.i

		INCLUDE ID_Expansion.i
		INCLUDE ID_Database.i
		INCLUDE ID_Locale.i

		IFD	_MAKE_68020
		  MACHINE 68020
		ENDC

		SECTION strings,DATA
		public	strbase
strbase		ds.w	0			; String base

		SECTION function,CODE
		public	fcttab
fcttab		ds.w	0			; Function base

		SECTION altmf,CODE
		public	mftab
mftab		ds.w	0			; Alternate MF base

		SECTION text,CODE
**
* ======== EXPANSION DATABASE ========
*
* This is the expansion database of the library.
*
* IMPORTANT: THIS IS NOT AN OFFICIAL LIST OF AMIGA EXPANSIONS!
* ---------  It has been collected and reported from numerous sources. Although
*            this information has been compiled and processed with great care,
*            it is impossible to verify each and every record. Thus, the Identify
*            developers do not guaratee for its completeness or correctness.
*
* This is an open list of expansions. It is okay if you sync it with your own
* database of expansions. However, please be fair and also provide boards that
* are missing here.
*
* Each group starts with the manufacturer ID and manufacturer name, using the "manuf"
* macro. The group ends with the "endmf" macro, giving the same manufacturer ID.
*
* Within this group, boards can be added using the "board" macro. As parameters it gets
* the board ID, board name, and board type.
*
* The "boarda" macro can be used if this board was manufactured by a different company
* than given in the current group. The parameters are board ID, manufacturer name,
* board name, and board type.
*
* Some manufacturers use the same board ID for different boards. For example, GVP has
* an internal sub-ID that can be used to distinguish the boards. The "boardf" macro
* can be used to invoke a function that will try to evaluate the correct board name.
* Parameters are: board ID, reference to the board function.
*
* In the board name, the \247 character can be used as a placeholder for the CPU. It
* must be given at the very beginning of the string (as indicator), and again at the
* position of the CPU number, followed by a default CPU number. For example:
* "\247G-Force \'0\24740" would give "G-Force \'060" if there is a 68060 present, and
* "G-Force \'040" if there is a 68040 present, or on a general board query.
*
* The "\241" marker at the very beginning of the string marks that for expansions that
* always come as a pair, this one is the secondary board. If present, IDERR_SECONDARY
* will be returned by the query as a warning. This feature is not used consequently
* though, and may become deprecated.
*
* All manufacturer IDs and board IDs MUST be given in ascending order!
*
* Take care that there is no space before a comma, otherwise the following parameters
* will be ignored (which will let the assembler fail).
*
* Also take care to escape all non-ASCII characters!
*
		SECTION tables,DATA
		public	manuf_tab
manuf_tab	tabinit

		manuf	00001,"Mikronik"
		board	  170,"Infinity Tower",		MSG_EXP_RAM
		endmf	00001

		manuf	00211,"Pacific Peripherals"	; Profex
		board	  000,"SE 2000 A500",		MSG_EXP_HD
		board	  010,"HD Controller",		MSG_EXP_SCSIHD
		endmf	00211

		manuf	00221,"Kupke"
		board	  000,"Golem RAM Box 2MB",	MSG_EXP_RAM	;A500/A100 2MB RAM exp.
		board	  042,"SE 2000",		MSG_EXP_RAM
		endmf	00221

		manuf	00256,"Memphis"			; Jochheim Computer Tuning?
		board	  000,"Stormbringer",		MSG_EXP_TURBO
		board	  002,"2-8MB RAM (2MB)",	MSG_EXP_RAM
		board	  004,"2-8MB RAM (4MB)",	MSG_EXP_RAM
		board	  019,"Warp Engine",		MSG_EXP_TURBOSCSIHD
		endmf	00256

		manuf	00512,"3-State Computertechnik"
		board	  002,"Megamix 2000",		MSG_EXP_RAM	;512KB-8MB
		endmf	00512

		manuf	00513,"Commodore Braunschweig"
		board	  001,"A2088 XT / A2286 AT",	MSG_EXP_BRIDGE
		board	  002,"A2286 AT",		MSG_EXP_BRIDGE
		board	  084,"A4091",			MSG_EXP_SCSIHD
		board	  103,"A2386 SX",		MSG_EXP_BRIDGE
		endmf	00513

		manuf	00514,"Commodore West Chester"
		board	  001,"A2090 / A2090-A",	MSG_EXP_SCSIHD
		board	  002,"A590 / A2091",		MSG_EXP_SCSIHD
		board	  003,"A590 / A2091",		MSG_EXP_SCSIHD
		board	  004,"A2090-B",		MSG_EXP_SCSIHD
		board	  009,"A2060",			MSG_EXP_ARCNET
		board	  010,"A2052 / A2058 / A590 / A2091", MSG_EXP_RAM
		board	  032,"A560",			MSG_EXP_RAM
		board	  069,"A2232 (prototype)",	MSG_EXP_MULTIIO
		board	  070,"A2232",			MSG_EXP_MULTIIO
		board	  080,"A2620 68020",		MSG_EXP_TURBOANDRAM
		board	  081,"A2630 68030",		MSG_EXP_TURBOANDRAM
		board	  084,"A4091",			MSG_EXP_SCSIHD
		board	  090,"A2065",			MSG_EXP_ETHERNET
		board	  096,"Romulator",		MSG_EXP_MISC
		board	  097,"A3000 Test Fixture",	MSG_EXP_MISC
		board	  103,"A2386 SX",		MSG_EXP_BRIDGE
		board	  106,"CD\xB3\xB2",		MSG_EXP_SCSIHD
		board	  112,"A2065",			MSG_EXP_ETHERNET
		endmf	00514

		manuf	00515,"Commodore West Chester"
		board	  003,"A2090-A Combitec/MacroSystem",MSG_EXP_HD
		endmf	00515

		manuf	00756,"Progressive Periph.&Systems"
		board	  002,"EXP8000",		MSG_EXP_RAM
		endmf	00756

		manuf	00767,"Kolff Computer Supplies"
		board	  000,"KCS Power PC",		MSG_EXP_BRIDGE
		endmf	00767

		manuf	01001,"Tecmar"
		endmf	01001

		manuf	01002,"Telesys"
		endmf	01002

		manuf	01003,"The Micro-Forge"
		endmf	01003

		manuf	01004,"Cardco Ltd."
		board	  004,"Kronos 2000",		MSG_EXP_SCSIHD
		board	  012,"A1000/A2000",		MSG_EXP_SCSIHD
		board	  014,"Escort",			MSG_EXP_SCSIHD
		board	  245,"A2410 HiRes",		MSG_EXP_GFX
		endmf	01004

		manuf	01005,"A-Squared"
		board	  001,"Live! 2000",		MSG_EXP_VIDEO
		endmf	01005

		manuf	01006,"Comspec Communications"
		board	  001,"AX2000",			MSG_EXP_RAM
		endmf	01006

		manuf	01007,"HT Electonics"
		endmf	01007

		manuf	01008,"RDS Software"
		endmf	01008

		manuf	01009,"Anakin Research"
		board	  001,"Easyl",			MSG_EXP_TABLET
		endmf	01009

		manuf	01010,"Microbotics"
		board	  000,"StarBoard II",		MSG_EXP_RAM	; MB1230 XA Accelerator?
		board	  002,"StarBoard II M.F.M.",	MSG_EXP_HD	; StarDrive?
		board	  003,"8-Up! (PIC A)",		MSG_EXP_RAM
		board	  004,"8-Up! (PIC B)",		MSG_EXP_RAM
		board	  018,"Modem 19",		MSG_EXP_MODEM
		board	  032,"Delta Card",		MSG_EXP_RAM
		board	  064,"8-Star!",		MSG_EXP_RAM
		board	  065,"8-Star!",		MSG_EXP_MISC
		board	  068,"VXL RAM*32",		MSG_EXP_RAM
		board	  069,"VXL 68030/6888x",	MSG_EXP_TURBO
		board	  096,"Delta Card",		MSG_EXP_MISC
		board	  129,"MBX 1200 / 1200z",	MSG_EXP_RAM
		board	  136,"VXL Turbo",		MSG_EXP_TURBO
		board	  150,"Hardframe 2000",		MSG_EXP_SCSIHD
		board	  158,"Hardframe 2000",		MSG_EXP_SCSIHD
		board	  193,"MBX 1200 / 1200z",	MSG_EXP_MISC
		endmf	01010

		manuf	01011,"Bob Krauth"
		endmf	01011

		manuf	01012,"Access Associates"
		board	  000,"Allegra",		MSG_EXP_RAM	; correct ID?
		board	  001,"Allegra",		MSG_EXP_RAM
		endmf	01012

		manuf	01013,"Mini Comp Systems Ltd."
		endmf	01013

		manuf	01014,"Cypress Technologies"
		endmf	01014

		manuf	01015,"Fuller Computers"
		endmf	01015

		manuf	01016,"Galaxy Computers"
		endmf	01016

		manuf	01017,"ADA Research"
		endmf	01017

		manuf	01018,"Computer Sevice Italia"
		endmf	01018

		manuf	01019,"Amigo"
		endmf	01019

		manuf	01020,"Micro-Solutions Inc."
		endmf	01020

		manuf	01021,"Stacar International"
		endmf	01021

		manuf	01022,"Video Precisions"
		endmf	01022

		manuf	01023,"ASDG"
		board	  001,"2MB",			MSG_EXP_RAM
		board	  002,"8MB",			MSG_EXP_RAM
		board	  254,"LanRover",		MSG_EXP_ETHERNET
		board	  255,"GPIB / IEEE-488 / Twin-X (dual)",MSG_EXP_SERIAL
		endmf	01023

		manuf	01025,"Ing.-B\xFCro Kalawsky"
		endmf	01025

		manuf	01026,"Computer Tuning"
		endmf	01026

		manuf	01027,"Interplan Unternehmensberatung"
		endmf	01027

		manuf	01028,"Imtronics"
		board	  057,"Hurricane 2800 (68030)",	MSG_EXP_TURBO
		board	  087,"Hurricane 2800 (68030)",	MSG_EXP_TURBO
		endmf	01028

		manuf	01030,"Commodore, University of Lowell"
		board	  000,"A2410 HiRes Framebuffer",MSG_EXP_GFX
		endmf	01030

		manuf	01041,"Design Labs"
		endmf	01041

		manuf	01042,"MCS"
		endmf	01042

		manuf	01043,"B. J. Freeman"
		endmf	01043

		manuf	01044,"Side Effects Inc."
		endmf	01044

		manuf	01045,"Oklahoma Personal Comp."
		endmf	01045

		manuf	01046,"Advanced Micro Innovations"
		endmf	01046

		manuf	01047,"Industrial Support Services"
		endmf	01047

		manuf	01048,"Technisoft"
		endmf	01048

		manuf	01049,"Prolific"
		endmf	01049

		manuf	01050,"Softeam"
		endmf	01050

		manuf	01051,"GRC Electronics"
		endmf	01051

		manuf	01052,"David Lai"
		endmf	01052

		manuf	01053,"Ameristar Technologies"
		board	  001,"A2065",			MSG_EXP_ETHERNET
		board	  009,"A2060 / A560",		MSG_EXP_ARCNET
		board	  010,"A4066",			MSG_EXP_ETHERNET
		board	  020,"1600-GX",		MSG_EXP_GFX
		endmf	01053

		manuf	01054,"Cline Refrigeration"
		endmf	01054

		manuf	01055,"Cardiac Pacemakers"
		endmf	01055

		manuf	01056,"Supra"
		board	  001,"SupraDrive 4x4",		MSG_EXP_SCSIHD
		board	  002,"1000 1MB",		MSG_EXP_RAM
		board	  003,"2000 DMA",		MSG_EXP_SCSIHD
		board	  005,"500",			MSG_EXP_RAMSCSIHD
		board	  008,"500 (Autoboot)",		MSG_EXP_SCSIHD
		board	  009,"500XP / 2000",		MSG_EXP_RAM	;2MB
		board	  010,"SupraRAM 2000",		MSG_EXP_RAM	;2MB-8MB
		board	  011,"2400zi",			MSG_EXP_MODEM
		board	  012,"500XP / SupraDrive WordSync",MSG_EXP_SCSIHD
		board	  013,"SupraDrive ByteSync",	MSG_EXP_SCSIHD
		board	  016,"2400zi+",		MSG_EXP_MODEM
		endmf	01056

		manuf	01057,"Wayne Diener"
		endmf	01057

		manuf	01058,"Computer Systems Ass."
		board	  017,"Magnum 040",		MSG_EXP_TURBOANDRAM
		board	  021,"12 Gauge 030/882",	MSG_EXP_TURBOANDRAM
		endmf	01058

		manuf	01059,"Trionix"
		endmf	01059

		manuf	01060,"David Lucas"
		endmf	01060

		manuf	01061,"Analog Precision"
		endmf	01061

		manuf	01081,"Marc Michael Groth"
		endmf	01081

		manuf	01267,"RBM Digitaltechnik"
		endmf	01267

		manuf	01282,"M-Tech Hardware Design"
		board	  003,"AT500",			MSG_EXP_RAM
		endmf	01282

		manuf	01337,"Thomas Stenzel"
		board	  001,"PyRamIDE",		MSG_EXP_IDEHDRAM
		endmf	01337

		manuf	01576,"Boris Krizma"
		board	  004,"Furia S628 (4MB)",	MSG_EXP_RAM
		board	  008,"Furia S628 (8MB)",	MSG_EXP_RAM
		board	  009,"Furia EC020",		MSG_EXP_TURBO
		board	  019,"Furia EC020",		MSG_EXP_TURBO
		endmf	01576

		manuf	01761,"Great Valley Products"
		board	  008,"Impact Series I",	MSG_EXP_RAMSCSIHD ; A2000 2MB RAM Board
		endmf	01761

		manuf	01803,"UAE"
		board	  001,"Fast RAM",		MSG_EXP_RAM
		board	  002,"Filesystem",		MSG_EXP_HD
		board	  003,"Z3 Fast RAM",		MSG_EXP_RAM
		board	  004,"Boot ROM",		MSG_EXP_MISC
		board	  081,"Fast RAM",		MSG_EXP_RAM
		board	  082,"Filesystem",		MSG_EXP_HD
		board	  083,"Z3 Fast RAM",		MSG_EXP_RAM
		board	  096,"UAEGFX",			MSG_EXP_GFX
		endmf	01803

		manuf	02002,"Mimetics"
		endmf	02002

		manuf	02003,"ACDA"
		endmf	02003

		manuf	02004,"Finn R. Jacobsen"
		endmf	02004

		manuf	02005,"Elthen Electronics"
		endmf	02005

		manuf	02006,"Nine Tiles Computer Systems"
		endmf	02006

		manuf	02007,"Analog Electronics"
		endmf	02007

		manuf	02008,"Bell & Howell"
		endmf	02008

		manuf	02009,"Roland Kochler"
		endmf	02009

		manuf	02010,"ByteBox"
		board	  000,"A500",			MSG_EXP_MISC
		endmf	02010

		manuf	02011,"Prototype ID"
		boarda	  000,"Prototype","General Prototype",MSG_EXP_MISC
		boardf	  001,f_uae_001
		boardf	  002,f_uae_002
		boarda	  003,"UAE","Z3 Fast RAM",	MSG_EXP_RAM
		boarda	  004,"UAE","Boot ROM",		MSG_EXP_MISC
		boarda	  032,"ATL","HDI 1000 Ultrasound",MSG_EXP_MISC	; http://jack.untergrund.net/2016/12/07/tekmagic-4060t-aka-ultrasound-accelerator-en/
		boarda	  081,"UAE","Fast RAM",		MSG_EXP_RAM
		boarda	  082,"UAE","Filesystem",	MSG_EXP_HD
		boarda	  083,"UAE","Z3 Fast RAM",	MSG_EXP_RAM
		boarda	  096,"UAE","UAEGFX",		MSG_EXP_GFX
		boarda	  224,"Vector","Connection",	MSG_EXP_MULTIIO
		boarda	  225,"Vector","Connection",	MSG_EXP_MULTIIO
		boarda	  226,"Vector","Connection",	MSG_EXP_MULTIIO
		boarda	  227,"Vector","Connection",	MSG_EXP_MULTIIO
		endmf	02011

		manuf	02012,"DKB / Power Computing"
		board	  001,"BattDisk",		MSG_EXP_MISC	; RAM disk
		board	  009,"SecureKey",		MSG_EXP_ACCESS
		board	  014,"DKM 3128",		MSG_EXP_RAM
		board	  015,"Rapid Fire",		MSG_EXP_SCSIHD
		board	  016,"DKM 1202",		MSG_EXP_RAMFPU
		board	  018,"Cobra/Viper II 68EC030",	MSG_EXP_TURBO
		boardf	  023,f_dkb_023
		board	  255,"WildFire 060",		MSG_EXP_TURBO
		endmf	02012

		manuf	02013,"Pacific Peripherals"
		endmf	02013

		manuf	02014,"Sysaphus Software"
		endmf	02014

		manuf	02015,"Digitronics"
		endmf	02015

		manuf	02016,"Akron Systems"
		endmf	02016

		manuf	02017,"GVP"
		board	  001,"Impact Series I (4K)",	MSG_EXP_SCSIHD
		board	  002,"Impact Series I (16K/2)",MSG_EXP_SCSIHD
		board	  003,"Impact Series I (16K/3)",MSG_EXP_SCSIHD	; Rev 3.5
		board	  008,"Impact 3001",		MSG_EXP_TURBOIDE; Rev 3, 68030
		board	  009,"\241Impact 3001",	MSG_EXP_RAM	; TurboIDE? 1-16MB 32bit
		board	  010,"Impact Series II",	MSG_EXP_RAM	; 2-8MB
		boardf	  011,f_gvp_011
		board	  013,"Impact 3001",		MSG_EXP_TURBOIDE ; GForce 040 with SCSI ; GVP A2000 68030 Turbo Board
		board	  022,"\247G-Force \'0\24740",	MSG_EXP_TURBOSCSIHD ; ID 32? ; TekMagic A2000'060 Combo (TURBO/RAM)
		board	  032,"Impact Vision 24",	MSG_EXP_GFX
		board	  254,"A1230 030/882",		MSG_EXP_TURBO
		board	  255,"\247G-Force \'0\24740 I/O",MSG_EXP_MULTIIO
		endmf	02017

		manuf	02018,"Calmos"
		endmf	02018

		manuf	02019,"Dover Research"
		endmf	02019

		manuf	02020,"David Krehbiel"
		endmf	02020

		manuf	02021,"Synergy"			; California Access
		board	  001,"Malibu",			MSG_EXP_SCSIHD
		endmf	02021

		manuf	02022,"Xetec"
		board	  001,"FastCard",		MSG_EXP_SCSIHD ;FastTrak
		board	  002,"FastCard",		MSG_EXP_RAM
		board	  003,"FastCard plus",		MSG_EXP_HD
		endmf	02022

		manuf	02023,"Micron Technology"
		endmf	02023

		manuf	02024,"CH Electronics"
		endmf	02024

		manuf	02025,"American Liquid Light"
		endmf	02025

		manuf	02026,"Progressive Periph.&Softw."
		board	  000,"Mercury",		MSG_EXP_TURBO
		board	  001,"A3000 68040",		MSG_EXP_TURBO
		board	  002,"?",			MSG_EXP_RAM
		board	  068,"Rambrandt",		MSG_EXP_GFX
		board	  105,"A2000 68040",		MSG_EXP_TURBOANDRAM
		board	  120,"ProRAM 3000",		MSG_EXP_RAM
		board	  150,"Zeus 040",		MSG_EXP_TURBOSCSIHD
		board	  187,"A500 68040",		MSG_EXP_TURBO
		board	  254,"Pixel64",		MSG_EXP_GFX
		board	  255,"Pixel64",		MSG_EXP_GFXRAM
		endmf	02026

		manuf	02027,"Wicat Systems"
		endmf	02027

		manuf	02028,"Applied Systems&Periph."
		endmf	02028

		manuf	02029,"Delaware Valley Software"
		endmf	02029

		manuf	02030,"Palomax"
		board	  000,"MAX-125",		MSG_EXP_MISC
		endmf	02030

		manuf	02031,"Incognito Software"
		endmf	02031

		manuf	02032,"Jadesign"
		endmf	02032

		manuf	02033,"BVR"
		endmf	02033

		manuf	02034,"Spirit Technology"
		board	  001,"Insider IN1000",		MSG_EXP_RAM	; 1.5MB
		board	  002,"Insider IN500",		MSG_EXP_RAM	; 1.5MB
		board	  003,"SIN500",			MSG_EXP_RAM	; 2MB
		board	  004,"HDAST506",		MSG_EXP_HD
		board	  005,"AX-S IBM",		MSG_EXP_MULTIIO	; Hardware I/O board?
		board	  006,"OctaByte X-RAM",		MSG_EXP_RAM	; 8MB RAM
		board	  008,"Inmate Multifunction",	MSG_EXP_SCSIHD	; Multifunctional (SCSI/FPP/Mem)
		endmf	02034

		manuf	02035,"Spirit Technology"
		endmf	02035

		manuf	02036,"Atronic"
		endmf	02036

		manuf	02037,"Scott Karlin"
		endmf	02037

		manuf	02038,"Howitch"
		endmf	02038

		manuf	02039,"Sullivan Brothers"
		endmf	02039

		manuf	02040,"G I T"
		endmf	02040

		manuf	02041,"Amigo Business Computers"
		endmf	02041

		manuf	02042,"Micro E"
		endmf	02042

		manuf	02043,"Ralph Kruse"
		endmf	02043

		manuf	02044,"Clearpoint Research"
		endmf	02044

		manuf	02045,"Kodiak"
		endmf	02045

		manuf	02046,"AlfaData"
		board	  003,"ALF 3",			MSG_EXP_SCSIHD
		endmf	02046

		manuf	02048,"Commodore Braunschweig"
		endmf	02048

		manuf	02049,"BSC"		; (Elaborate Bytes)
		board	  001,"ALF 2 MFM",		MSG_EXP_HD
		board	  002,"ALF 2",			MSG_EXP_SCSIHD
		board	  003,"ALF 3",			MSG_EXP_SCSIHD
		board	  005,"Oktagon 2008",		MSG_EXP_SCSIHD
		board	  006,"Tandem",			MSG_EXP_SCSIHD
		board	  008,"Memory-Master",		MSG_EXP_RAM
		board	  016,"Multiface",		MSG_EXP_MULTIIO
		board	  032,"Frame Buffer",		MSG_EXP_VIDEO
		board	  064,"ISDN Master",		MSG_EXP_ISDN
		board	  065,"ISDN Master",		MSG_EXP_ISDN
		endmf	02049

		manuf	02050,"Cardco Ltd."	; MicroDyn (C'Ltd Successor)
		board	  004,"Kronos 2000",		MSG_EXP_SCSIHD
		board	  012,"A1000",			MSG_EXP_SCSIHD
		endmf	02050

		manuf	02051,"Spartanics"
		endmf	02051

		manuf	02052,"Jochheim"
		board	  001,"2/8 MB",			MSG_EXP_RAM
		board	  032,"Access 32",		MSG_EXP_RAM
		endmf	02052

		manuf	02053,"Trans Data Systems"
		endmf	02053

		manuf	02054,"Applied Systems&Periph."
		endmf	02054

		manuf	02055,"Checkpoint Technologies"
		board	  000,"Serial Solution (dual)",	MSG_EXP_SERIAL
		endmf	02055

		manuf	02056,"Adept Development"
		endmf	02056

		manuf	02057,"Advanced Computer Design"
		endmf	02057

		manuf	02058,"Sir Netics"
		endmf	02058

		manuf	02059,"Expert Services"
		endmf	02059

		manuf	02060,"Digital Art Systems"
		endmf	02060

		manuf	02061,"Adept Development"
		endmf	02061

		manuf	02062,"Expansion Technologies"
		endmf	02062

		manuf	02063,"Alphatech"
		endmf	02063

		manuf	02064,"Edotronik"
		board	  001,"IEEE-488 Controller",	MSG_EXP_MISC
		board	  002,"8032 development adapter",MSG_EXP_MISC
		board	  003,"High Speed",		MSG_EXP_SERIAL
		board	  004,"24 Bit Realtime Digitizer",MSG_EXP_VIDEO
		board	  005,"32 Bit Parallel I/O",	MSG_EXP_MISC
		board	  006,"PIC Prototype",		MSG_EXP_MISC
		board	  007,"16 Channel ADC",		MSG_EXP_MISC
		board	  008,"VME-Bus controller",	MSG_EXP_INTERFACE
		board	  009,"DSP96000 Realtime Data Acquisition",MSG_EXP_MISC
		endmf	02064

		manuf	02065,"California Access"	; synergy
		board	  001,"Malibu",			MSG_EXP_SCSIHD
		endmf	02065

		manuf	02066,"Bowden, Williams, Full"
		endmf	02066

		manuf	02067,"NES Inc."
		board	  000,"Expansion RAM",		MSG_EXP_RAM
		endmf	02067

		manuf	02068,"Amdev"
		endmf	02068

		manuf	02069,"Big Brother Security"
		endmf	02069

		manuf	02070,"Active Circuits"
		endmf	02070

		manuf	02071,"ICD"
		board	  001,"AdSCSI 2000",		MSG_EXP_SCSIHD ; Advantage SCSI
		board	  003,"AdIDE",			MSG_EXP_IDEHD
		board	  004,"AdRAM 2080",		MSG_EXP_RAM
		board	  035,"Trifecta",		MSG_EXP_HD
		board	  255,"?",			MSG_EXP_IDEHD
		endmf	02071

		manuf	02072,"Multi-Meg Electronique"
		endmf	02072

		manuf	02073,"Kupke"
		board	  001,"Omti",			MSG_EXP_MFMHD	; Golem
		board	  002,"SCSI-II",		MSG_EXP_SCSIHD	; Golem
		board	  003,"Golem Box",		MSG_EXP_RAM	; a2x00 2-8MB
		board	  004,"030/882 (synchronous)",	MSG_EXP_TURBO
		board	  005,"030/882 (asynchronous)",	MSG_EXP_TURBO
		endmf	02073

		manuf	02074,"The Checkered Ball"
		endmf	02074

		manuf	02075,"Hi Tension Computer Services"
		endmf	02075

		manuf	02076,"Alfa Data"
		board	  024,"AlfaRAM",		MSG_EXP_RAM
		endmf	02076

		manuf	02077,"GVP"
		boarda	  002,"Chartscreen Ltd","AGXQ-256 Architect",MSG_EXP_GFX
		board	  009,"A2000-RAM8/2",		MSG_EXP_MISC
		board	  010,"GVP Series II",		MSG_EXP_RAM
		endmf	02077

		manuf	02078,"Interworks Network"
		endmf	02078

		manuf	02079,"Galysh Enterprises"
		endmf	02079

		manuf	02080,"Hardital Synthesis"
		board	  020,"TQM 68030+68882",	MSG_EXP_TURBO
		endmf	02080

		manuf	02081,"GBS"
		endmf	02081

		manuf	02082,"Circum Design"
		endmf	02082

		manuf	02083,"Alberta Micro Electronic"
		endmf	02083

		manuf	02084,"Bestech"
		endmf	02084

		manuf	02085,"Lasar Fantasy"
		endmf	02085

		manuf	02086,"Pulsar"
		endmf	02086

		manuf	02087,"Ivis"
		endmf	02087

		manuf	02088,"Applied Engineering"
		board	  016,"DL2000",			MSG_EXP_MODEM
		board	  224,"RAM Works",		MSG_EXP_RAM
		endmf	02088

		manuf	02089,"Solid-State Design & Dev."
		endmf	02089

		manuf	02090,"Vison Quest"
		endmf	02090

		manuf	02091,"Seaview Software"
		endmf	02091

		manuf	02092,"BSC"		; Elaborate Bytes
		boarda	  002,"AlfaData","ALF 2",	MSG_EXP_SCSIHD
		boarda	  003,"AlfaData","ALF 3",	MSG_EXP_SCSIHD
		boardf	  005,f_bsc_005
		boardf	  006,f_bsc_006
		boarda	  007,"AlfaData","Alpha RAM 1200",MSG_EXP_RAM
		board	  008,"Memory Master",		MSG_EXP_RAM
		board	  016,"Multiface II",		MSG_EXP_MULTIIO
		board	  017,"Multiface",		MSG_EXP_MULTIIO
		board	  018,"Multiface III",		MSG_EXP_MULTIIO
		board	  024,"Tandem AT-2008 CD",	MSG_EXP_IDEHD
		board	  032,"Framebuffer",		MSG_EXP_GFX
		board	  033,"\241Graffiti",		MSG_EXP_GFXRAM
		board	  034,"Graffiti",		MSG_EXP_GFX
		board	  064,"ISDN MasterCard",	MSG_EXP_ISDN
		board	  065,"ISDN MasterCard II",	MSG_EXP_ISDN
		endmf	02092

		manuf	02093,"Bernd Culenfeld"
		endmf	02093

		manuf	02094,"American Liquid Light"
		endmf	02094

		manuf	02095,"CEGITES"
		endmf	02095

		manuf	02097,"Silicon Peace"
		endmf	02097

		manuf	02098,"Black Belt Systems"
		endmf	02098

		manuf	02099,"VillageTronic"
		board	  137,"Ariadne",		MSG_EXP_ETHERNET
		endmf	02099

		manuf	02100,"ReadySoft"
		endmf	02100

		manuf	02101,"Phoenix"
		board	  033,"ST506 Autoboot",		MSG_EXP_MFMHD
		board	  034,"SCSI Autoboot",		MSG_EXP_SCSIHD
		board	  064,"DMX",			MSG_EXP_MISC
		board	  190,"Memory Board",		MSG_EXP_RAM
		endmf	02101

		manuf	02102,"Advanced Storage Solutions"
		board	  001,"Nexus",			MSG_EXP_SCSIHD
		board	  008,"Nexus",			MSG_EXP_RAM
		endmf	02102

		manuf	02103,"Rombo Productions"
		endmf	02103

		manuf	02104,"Impulse"
		board	  000,"FireCracker 24 NTSC",	MSG_EXP_GFX
		board	  001,"FireCracker 24 PAL",	MSG_EXP_GFX
		endmf	02104

		manuf	02105,"Beta Unlimited"
		endmf	02105

		manuf	02106,"Memory Expansion System"
		endmf	02106

		manuf	02107,"Vortex Computer Systems"
		endmf	02107

		manuf	02108,"Platypus Systems"
		endmf	02108

		manuf	02109,"Gigatron"
		endmf	02109

		manuf	02110,"PG Electronics"
		endmf	02110

		manuf	02111,"New Technologies Group"
		endmf	02111

		manuf	02112,"Interactive Video Systems"	; IVS (Pacific Peripherals)
		board	  002,"GrandSlam PIC 2",	MSG_EXP_SCSIHD
		board	  004,"GrandSlam PIC 1",	MSG_EXP_SCSIHD
		board	  016,"OverDrive",		MSG_EXP_SCSIHD
		board	  048,"TrumpCard Classic",	MSG_EXP_SCSIHD
		board	  052,"TrumpCard Pro / Grand Slam",MSG_EXP_SCSIHD
		board	  064,"Meta-4",			MSG_EXP_RAM
		board	  191,"Wavetools",		MSG_EXP_AUDIO
		board	  242,"Vector",			MSG_EXP_SCSIHD
		board	  243,"Vector 030/882",		MSG_EXP_TURBOANDRAM
		board	  244,"Vector",			MSG_EXP_SCSIHD
		endmf	02112

		manuf	02113,"Vector"
		board	  227,"Connection",		MSG_EXP_MULTIIO
		endmf	02113

		manuf	02114,"Pacific Digital"
		board	  002,"Symposium",		MSG_EXP_MISC
		endmf	02114

		manuf	02115,"Xanadu"
		endmf	02115

		manuf	02116,"Pacific Digital"
		board	  002,"PC-Access",		MSG_EXP_MISC
		endmf	02116

		manuf	02117,"XPert"
		board	  001,"\241Visiona",		MSG_EXP_GFXRAM
		board	  002,"Visiona",		MSG_EXP_GFX
		board	  003,"\241Merlin",		MSG_EXP_GFXRAM
		board	  004,"Merlin",			MSG_EXP_GFX
		board	  201,"Merlin",			MSG_EXP_GFX
		endmf	02117

		manuf	02118,"The Amiga Centre"
		endmf	02118

		manuf	02119,"Digital Pacific"
		endmf	02119

		manuf	02120,"Solid State Leisure"
		endmf	02120

		manuf	02121,"Hydra Systems"
		board	  001,"Amiganet",		MSG_EXP_ETHERNET
		endmf	02121

		manuf	02122,"Cumana"
		endmf	02122

		manuf	02123,"KAPS 2C Conception"
		endmf	02123

		manuf	02124,"Mike Mason"
		endmf	02124

		manuf	02125,"For Your Eyes"
		endmf	02125

		manuf	02126,"VOB Computersysteme"
		board	  001,"Access X",		MSG_EXP_HD
		endmf	02126

		manuf	02127,"Sunrize Industries"
		board	  001,"AD1012",			MSG_EXP_AUDIO
		board	  002,"AD516",			MSG_EXP_AUDIO
		board	  003,"DD512",			MSG_EXP_AUDIO
		endmf	02127

		manuf	02128,"Triceratops"
		board	  001,"Multiport",		MSG_EXP_MULTIIO
		endmf	02128

		manuf	02129,"Applied Magic Inc."
		board	  001,"DMI Resolver (TI34010)",	MSG_EXP_GFX
		board	  002,"Vivid-24",		MSG_EXP_GFX
		board	  006,"Digital Broadcaster 32",	MSG_EXP_VIDEO
		board	  009,"Digital Broadcaster Elite",MSG_EXP_VIDEO
		endmf	02129

		manuf	02130,"Alfa-Laval"
		endmf	02130

		manuf	02131,"Multigros"
		endmf	02131

		manuf	02132,"Archos"
		endmf	02132

		manuf	02133,"Icom Simulations"
		endmf	02133

		manuf	02134,"Commodore Test Engineering"
		endmf	02134

		manuf	02135,"Microcreations"
		endmf	02135

		manuf	02136,"Shoestring Productions"
		endmf	02136

		manuf	02137,"Faberushi"
		endmf	02137

		manuf	02138,"Evesham Micro"
		endmf	02138

		manuf	02139,"Pangulin Laser Software"
		endmf	02139

		manuf	02140,"Thomas Rudloff"
		endmf	02140

		manuf	02141,"Daniel Hohabir"
		endmf	02141

		manuf	02142,"GFX-Base"
		board	  000,"GDA-1 VRAM",		MSG_EXP_GFX
		board	  001,"GDA-1",			MSG_EXP_GFX
		endmf	02142

		manuf	02143,"Axellabs"
		endmf	02143

		manuf	02144,"RocTec"
		board	  001,"RH 800C",		MSG_EXP_HD
		board	  002,"RH 800C",		MSG_EXP_RAM
		endmf	02144

		manuf	02145,"Ingenieurb\xFCro Helfrich" ; Omega Datentechnik?
		boarda	  032,"Hertz Elektronik","Rainbow II",MSG_EXP_GFX
		board	  033,"Rainbow III",		MSG_EXP_GFX
		boarda	  052,"E3B","Algor (Pro)",	MSG_EXP_USB
		boarda	  128,"Kato","Melody MPEG",	MSG_EXP_AUDIO
		boarda	  129,"E3B","Unity",		MSG_EXP_ETHERNET
		boarda	  200,"E3B","Highway",		MSG_EXP_USB
		boarda	  201,"E3B","Mizar",		MSG_EXP_USB ; Algor Prototype
		boarda	  203,"E3B","Algor",		MSG_EXP_USB
		boarda	  232,"E3B","Highway",		MSG_EXP_USB
		endmf	02145

		manuf	02146,"Atlantis"
		endmf	02146

		manuf	02147,"Skytec Computers"
		endmf	02147

		manuf	02148,"Protar"
		endmf	02148

		manuf	02149,"ACS"
		endmf	02149

		manuf	02150,"Software Results Enterpr." ; (D.Salomon)
		board	  001,"Golden Gate 2 Bus+",	MSG_EXP_BRIDGE	; pure IDE bus bridge?
		endmf	02150

		manuf	02151,"Infinity Systems"
		endmf	02151

		manuf	02152,"Trade It"
		endmf	02152

		manuf	02153,"Suntec"
		endmf	02153

		manuf	02154,"DJW Micro Systems"
		board	  001,"Horizon",		MSG_EXP_GFX
		board	  002,"BlackBox",		MSG_EXP_GFX
		board	  003,"Voyager",		MSG_EXP_GFX
		endmf	02154

		manuf	02155,"Power Computing"
		endmf	02155

		manuf	02156,"MacroSystems"
		endmf	02156

		manuf	02157,"Masoboshi"
		boarda	  000,"DCE","Viper 520 CD",	MSG_EXP_TURBO
		board	  003,"MasterCard SC201",	MSG_EXP_RAM
		board	  004,"MasterCard MC702",	MSG_EXP_SCSIIDE
		board	  007,"MVD 819",		MSG_EXP_MISC
		endmf	02157

		manuf	02158,"HAL"
		endmf	02158

		manuf	02159,"Mainhattan Data"
		board	  001,"A-Team",			MSG_EXP_IDEHD
		endmf	02159

		manuf	02160,"Digital Processing System"
		endmf	02160

		manuf	02161,"Blue Ribbon"
		board	  002,"One Stop Music Shop",	MSG_EXP_AUDIO
		endmf	02161

		manuf	02162,"XPert"
		board	  001,"Domino",			MSG_EXP_RAM
		board	  002,"Domino",			MSG_EXP_MISC
		endmf	02162

		manuf	02164,"Superformance"
		endmf	02164

		manuf	02165,"Overland Engineering"
		endmf	02165

		manuf	02166,"Thomas Hamren"
		endmf	02166

		manuf	02167,"VillageTronic"
		board	  001,"\241Domino",		MSG_EXP_GFXRAM
		board	  002,"Domino",			MSG_EXP_GFX
		board	  003,"Domino 16M Prototype",	MSG_EXP_GFX
		board	  011,"\241Picasso II / II+",	MSG_EXP_GFXRAM
		board	  012,"Picasso II / II+",	MSG_EXP_GFX
		board	  013,"Picasso II (Segmented Mode)",MSG_EXP_GFX
		boarda	  016,"Georg Braun","GBAPII++",	MSG_EXP_RAM
		boarda	  017,"Georg Braun","GBAPII++",	MSG_EXP_GFX
		board	  021,"\241Picasso IV Z2",	MSG_EXP_GFXRAM
		board	  022,"\241Picasso IV Z2",	MSG_EXP_GFXRAM
		board	  023,"Picasso IV Z2",		MSG_EXP_GFX
		board	  024,"Picasso IV Z3",		MSG_EXP_GFX
		board	  201,"Ariadne",		MSG_EXP_ETHERNET
		board	  202,"Ariadne II",		MSG_EXP_ETHERNET
		board	  240,"Picasso II+",		MSG_EXP_RAM
		board	  241,"Picasso II+",		MSG_EXP_GFX
		board	  242,"Picasso IV ECS Flickerfixer",MSG_EXP_GFX
		board	  243,"Picasso IV AGA Flickerfixer",MSG_EXP_GFX
		board	  244,"Pablo II",		MSG_EXP_VIDEO
		board	  245,"Picasso IV",		MSG_EXP_VIDEO
		board	  246,"Paloma (PAL)",		MSG_EXP_VIDEO	; TV Tuner
		board	  247,"Paloma (NTSC)",		MSG_EXP_VIDEO	; TV Tuner
		board	  248,"Concierto",		MSG_EXP_AUDIO
		endmf	02167

		manuf	02168,"Toolbox Design"
		endmf	02168

		manuf	02169,"Digital Processing System"
		endmf	02169

		manuf	02170,"Superformance"
		endmf	02170

		manuf	02171,"Utilities Unlimited"
		board	  021,"Emplant Deluxe",		MSG_EXP_MACEMU
		board	  032,"Emplant Deluxe",		MSG_EXP_MACEMU
		endmf	02171

		manuf	02172,"phase 5"
		endmf	02172

		manuf	02173,"J\xFCrgen Kommos"
		endmf	02173

		manuf	02174,"Electronic Design"
		endmf	02174

		manuf	02175,"James Cook University"
		endmf	02175

		manuf	02176,"Amitrix"
		board	  001,"?",			MSG_EXP_MULTIIO
		board	  002,"CD-RAM (CDTV)",		MSG_EXP_RAM
		endmf	02176

		manuf	02177,"Ferranti"
		endmf	02177

		manuf	02178,"Leviathan Development"
		endmf	02178

		manuf	02179,"United Video"
		endmf	02179

		manuf	02180,"GPSoft"
		endmf	02180

		manuf	02181,"ArMax"
		board	  000,"oMniBus",		MSG_EXP_GFX
		endmf	02181

		manuf	02182,"CP Computer"
		endmf	02182

		manuf	02183,"Amiga Module&Oberon Klub"
		endmf	02183

		manuf	02184,"ITEK Neser & Sieber"
		endmf	02184

		manuf	02185,"Phillip C. Lello"
		endmf	02185

		manuf	02186,"Cyborg Design Services"
		endmf	02186

		manuf	02187,"G2 Systems"
		endmf	02187

		manuf	02188,"Pro System"
		endmf	02188

		manuf	02189,"ZEUS"
		board	  001,"ConneXion",		MSG_EXP_ETHERNET
		board	  002,"ConneXion (A2065 emulation)",MSG_EXP_ETHERNET
		endmf	02189

		manuf	02190,"Altatech"
		endmf	02190

		manuf	02191,"NewTek"
		board	  000,"VideoToaster",		MSG_EXP_VIDEO
		endmf	02191

		manuf	02192,"M-Tech (Germany)"
		board	  001,"AT500",			MSG_EXP_IDEHD
		board	  003,"68030",			MSG_EXP_TURBO
		board	  005,"A1204",			MSG_EXP_RAMFPU
		board	  006,"68020i",			MSG_EXP_TURBO
		board	  032,"A1200 T68030/42 RTC",	MSG_EXP_TURBORAM
		board	  033,"Viper MK V / E-Matrix 530",MSG_EXP_SCSIHD	;E-Matrix: IDEHD, TURBORAM?
		board	  034,"8 MB",			MSG_EXP_RAM
		board	  036,"Viper MK V / E-Matrix 530",MSG_EXP_SCSIHD	;E-Matrix: IDE/SCSI
		endmf	02192

		manuf	02193,"GVP"
		board	  001,"EGS 28/24 Spectrum",	MSG_EXP_GFX
		board	  002,"EGS 28/24 Spectrum",	MSG_EXP_GFXRAM
		endmf	02193

		manuf	02194,"Marpet Developments"
		board	  001,"M1207",			MSG_EXP_RAMFPU
		endmf	02194

		manuf	02195,"Ingenieurb\xFCro Helfrich"
		board	  005,"Piccolo",		MSG_EXP_GFXRAM
		board	  006,"Piccolo",		MSG_EXP_GFX
		board	  007,"Peggy Plus MPEG",	MSG_EXP_VIDEO
		board	  008,"VideoCruncher",		MSG_EXP_VIDEO
		board	  010,"Piccolo SD-64",		MSG_EXP_GFXRAM
		board	  011,"Piccolo SD-64",		MSG_EXP_GFX
		endmf	02195

		manuf	02196,"The Neo Group"
		endmf	02196

		manuf	02197,"Cyon"
		endmf	02197

		manuf	02198,"Bob Research Group"
		endmf	02198

		manuf	02199,"Richmond Sound Design"
		endmf	02199

		manuf	02200,"US Cybernetics"
		endmf	02200

		manuf	02201,"Fulvio Ieva"
		endmf	02201

		manuf	02202,"Silicon Studio Ltd."
		board	  000,"20bit / 4 channel",	MSG_EXP_AUDIO
		board	  001,"Digital Multitrack",	MSG_EXP_AUDIO
		endmf	02202

		manuf	02203,"MacroSystem USA"
		board	  019,"Warp Engine 40xx",	MSG_EXP_TURBOSCSIHD
		endmf	02203

		manuf	02204,"Conspector Entertainment"
		endmf	02204

		manuf	02205,"Laserforum"
		endmf	02205

		manuf	02206,"Elbox"			; http://www.elbox.com/products_id.html
		board	  001,"Elbox 500/2MB",		MSG_EXP_RAM
		board	  002,"Elbox 500/0.5MB",	MSG_EXP_RAM
		board	  003,"Elbox CDTV/2MB",		MSG_EXP_RAM
		board	  004,"Elbox CDTV/8MB",		MSG_EXP_RAM
		board	  005,"Elbox 600/1MB",		MSG_EXP_RAM
		board	  006,"Elbox 1200/4MB",		MSG_EXP_RAM
		board	  007,"Elbox 1200/0-8",		MSG_EXP_RAM
		board	  008,"FastATA 1200 MK-I",	MSG_EXP_IDEHD
		board	  009,"Elbox 1230",		MSG_EXP_TURBO
		board	  010,"PC Key 1200",		MSG_EXP_KEYBOARD
		board	  011,"E/Box 1200 Tower",	MSG_EXP_MISC
		board	  012,"PC Key 600",		MSG_EXP_KEYBOARD
		board	  013,"Allegro CDFS",		MSG_EXP_CDROM
		board	  014,"Amiga 1200 E/Box",	MSG_EXP_MISC
		board	  015,"ScanDoubler/Flickerfixer",MSG_EXP_MISC
		board	  016,"FastATA 1200 Lite",	MSG_EXP_IDEHD
		board	  017,"Buffered Interface 4xEIDE\'99",MSG_EXP_IDEHD
		board	  018,"FastATA 1200",		MSG_EXP_IDEHD
		board	  019,"FastATA 1200 MK-II Gold",MSG_EXP_IDEHD
		board	  020,"E/Box 4000 + Zorro III/ISA",MSG_EXP_BUSBRIDGE
		board	  024,"FastATA 1200 MK-II",	MSG_EXP_IDEHD
		board	  025,"FastATA 4000 MK-I",	MSG_EXP_IDEHD
		board	  026,"Zorro IV",		MSG_EXP_BUSBRIDGE
		board	  027,"Hyperport",		MSG_EXP_INTERFACE
		board	  028,"Mroocheck PC",		MSG_EXP_MOUSE
		board	  029,"FastATA 4000 MK-II",	MSG_EXP_IDEHD
		board	  030,"FastATA Zorro IV",	MSG_EXP_IDEHD
		board	  031,"Mediator Zorro IV PCI",	MSG_EXP_BUSBRIDGE
		board	  032,"Mediator 1200 PCI",	MSG_EXP_BUSBRIDGE
		board	  033,"Mediator PCI 4000 Core Logic",MSG_EXP_MISC
		board	  034,"Elbox 4000 PCI",		MSG_EXP_BUSBRIDGE
		board	  035,"Mirage 4000 PCI",	MSG_EXP_BUSBRIDGE
		board	  036,"Elbox 3000 PCI",		MSG_EXP_BUSBRIDGE
		board	  037,"Elbox Tower PCI",	MSG_EXP_BUSBRIDGE
		board	  038,"Spider",			MSG_EXP_USB
		board	  039,"Mirage 3000",		MSG_EXP_MISC
		board	  040,"Mediator 1200 SX PCI",	MSG_EXP_BUSBRIDGE
		board	  041,"Elbox 4000Di PCI",	MSG_EXP_BUSBRIDGE
		board	  042,"Mirage 1200",		MSG_EXP_MISC
		board	  043,"Spider II",		MSG_EXP_USB
		board	  044,"eFlash 4000/1MB",	MSG_EXP_FLASHROM
		board	  045,"eFlash 4000/2MB",	MSG_EXP_FLASHROM
		board	  046,"Cocolino MK-I",		MSG_EXP_MOUSE
		board	  047,"eFlash 1200/1MB",	MSG_EXP_FLASHROM
		board	  048,"Mediator 1200 LT2 PCI",	MSG_EXP_BUSBRIDGE
		board	  049,"Mediator 1200 LT4 PCI",	MSG_EXP_BUSBRIDGE
		board	  050,"Cocolino MK-II",		MSG_EXP_MOUSE
		board	  051,"Cocolino MK-III",	MSG_EXP_MOUSE
		board	  052,"Elbox 500/8MB",		MSG_EXP_RAM
		board	  053,"FastATA 1200 MK-III",	MSG_EXP_IDEHD
		board	  054,"(AG4)",			MSG_EXP_MISC
		board	  055,"D-Box 1200",		MSG_EXP_MISC
		board	  056,"Dragon 1200 PCI/AGP",	MSG_EXP_BUSBRIDGE
		board	  057,"Dragon 1200 ColdFire",	MSG_EXP_TURBO
		board	  058,"(SL)",			MSG_EXP_MISC
		board	  059,"(ME8)",			MSG_EXP_MISC
		board	  060,"Mediator 1200 TX PCI",	MSG_EXP_BUSBRIDGE
		board	  061,"(F44)",			MSG_EXP_MISC
		board	  062,"FastATA 4000 MK-V",	MSG_EXP_IDEHD
		board	  063,"Mediator PCI 4000 Core Logic",MSG_EXP_MISC
		board	  064,"FastATA 1200 MK-IV",	MSG_EXP_IDEHD
		board	  065,"FastATA 1200 MK-IV",	MSG_EXP_SATAHD
		board	  066,"FastATA 1200 ZIV",	MSG_EXP_SATAHD
		board	  067,"FastATA 4000 MK-VI/MK-VII",MSG_EXP_SATAHD ; MK6: BotROM 6.0-8.0, MK7: BotROM 9.0
		board	  068,"Elbox 3000Di PCI",	MSG_EXP_BUSBRIDGE
		board	  069,"FastATA 1200 MK-V",	MSG_EXP_SATAHD
		board	  071,"BlackBOX 1200",		MSG_EXP_MISC
		board	  072,"BlackBOX 1200 MK-II",	MSG_EXP_MISC
		board	  159,"Mediator PCI Zorro IV",	MSG_EXP_RAM
		board	  160,"Mediator PCI 1200",	MSG_EXP_RAM
		board	  161,"Mediator PCI 4000",	MSG_EXP_RAM
		board	  168,"Mediator PCI 1200 SX",	MSG_EXP_RAM
		board	  176,"Mediator PCI 1200 LT2",	MSG_EXP_RAM
		board	  177,"Mediator PCI 1200 LT4",	MSG_EXP_RAM
		board	  188,"Mediator PCI 1200 TX",	MSG_EXP_RAM
		board	  191,"Mediator PCI 4000",	MSG_EXP_RAM	; MK-II/MK-III
		endmf	02206

		manuf	02207,"Applied Magic"
		endmf	02207

		manuf	02208,"SDL"
		endmf	02208

		manuf	02372,"AmigaXL"			; confirmed by H&P
		board	  001,"emulated",		MSG_EXP_RAM
		board	  002,"emulated",		MSG_EXP_HD
		board	  003,"emulated",		MSG_EXP_RAM
		board	  096,"emulated",		MSG_EXP_GFX
		endmf	02372

		manuf	02560,"Harms"
		board	  016,"030 plus",		MSG_EXP_TURBO
		board	  019,"Turbo-Jet 1230xi",	MSG_EXP_TURBO
		board	  208,"3500 Prof. 030/882",	MSG_EXP_TURBOANDRAM	;2-16MB
		endmf	02560

		manuf	02588,"a1k.org Community"	; see https://www.a1k.org/forum/index.php?threads/40276/
		board	  001,"Protein_1",		MSG_EXP_MISC	; by botfixer and crasbe
		board	  002,"68030TK 4MB 32bit SRAM",	MSG_EXP_RAM	; by Matze
		board	  003,"68030TK",		MSG_EXP_TURBO	; by Matze
		board	  004,"68030TK IDE controller",	MSG_EXP_IDEHD	; by Matze
		board	  005,"Nova-Thylacine Rev.1",	MSG_EXP_MISC	; by crasbe & ACT Australia
		board	  006,"Nova-Thylacine Rev.2",	MSG_EXP_MISC	; by crasbe & ACT Australia
		board	  007,"Expansion for 68030TK",	MSG_EXP_MISC	; by Matze
		board	  008,"68EC020TK",		MSG_EXP_RAM	; by Matze
		board	  009,"68EC020TK",		MSG_EXP_RAM	; by Matze
		board	  011,"romdisk",		MSG_EXP_MISC	; by cnvogelg/nospam2000
		board	  012,"FPGA-TK",		MSG_EXP_RAM
		board	  013,"FPGA-TK SD-Card",	MSG_EXP_MISC
		board	  014,"68030-TK2",		MSG_EXP_RAM
		board	  015,"68030TK2",		MSG_EXP_TURBO	; by Matze
		board	  042,"BoardsLAB",		MSG_EXP_MISC	; by bubbob42
		board	  060,"68060-TK",		MSG_EXP_TURBO	; by Matze
		board	  123,"LAN Card",		MSG_EXP_ETHERNET; by buggs/Scrat/Matze
		board	  124,"Matzes Clockport",	MSG_EXP_MISC	; by Matze
		board	  125,"Matzes IDE-Controller",	MSG_EXP_IDEHD	; by Matze
		board	  208,"Dicke Olga A2000-030TK",	MSG_EXP_TURBOIDE
		endmf	02588

		manuf	02640,"Micronik"
		board	  010,"RCA 120",		MSG_EXP_RAM
		endmf	02640

		manuf	03084,"Team 4"
		board	  012,"Kasmin",			MSG_EXP_GFX
		endmf	03084

		manuf	03643,"E3B"
		board	  016,"Deneb ZIII",		MSG_EXP_USB
		board	  018,"Deneb ZII",		MSG_EXP_USB
		board	  019,"Deneb ROM",		MSG_EXP_USB
		board	  020,"Deneb ROM Rescue",	MSG_EXP_USB
		board	  023,"Deneb ZII Clockport",	MSG_EXP_USB
		board	  032,"BigRam+",		MSG_EXP_RAM
		board	  033,"BigRam+",		MSG_EXP_RAM
		board	  048,"Prisma Megamix",		MSG_EXP_AUDIO
		board	  200,"Prometheus Firestorm Upgrade",MSG_EXP_BUSBRIDGE
		endmf	03643

		manuf	03855,"Micronik"
		board	  001,"Infinitiv Z3",		MSG_EXP_SCSIHD
		endmf	03855

		manuf	04096,"MegaMicro"
		board	  003,"SCRAM 500",		MSG_EXP_SCSIHD
		board	  004,"SCRAM 500",		MSG_EXP_RAM
		endmf	04096

		manuf	04110,"DigiFeX"
		board	  010,"Interact",		MSG_EXP_ETHERNET
		endmf	04110

		manuf	04136,"Imtronics"	; Ronin?
		board	  057,"Hurricane 2800 030/882",	MSG_EXP_TURBOANDRAM
		board	  064,"Kronos II",		MSG_EXP_SCSIHD
		board	  087,"Hurricane 2800 030/882",	MSG_EXP_TURBOANDRAM
		endmf	04136

		manuf	04149,"ProTAR"
		board	  051,"?",			MSG_EXP_SCSIHD
		board	  052,"?",			MSG_EXP_RAM
		endmf	04149

		manuf	04369,"Frank Strau\xDF Elektronik"
		endmf	04369

		manuf	04626,"Individual Computers"	; see http://wiki.icomp.de/wiki/Autoconfig_IDs
		boardf    000,f_icomp_000
		board	  005,"ISDN Surfer",		MSG_EXP_ISDN
		board	  007,"VarIO",			MSG_EXP_MULTIIO
		board	  010,"Kickflash",		MSG_EXP_FLASHROM
		board	  021,"ACA1221",		MSG_EXP_TURBOANDRAM
		board	  022,"ACA1221EC",		MSG_EXP_TURBOANDRAM
		board	  023,"X-Surf",			MSG_EXP_ETHERNET
		board	  024,"ACA1221lc",		MSG_EXP_TURBOANDRAM
		boardf	  026,f_icomp_026
		board	  027,"ACA1211",		MSG_EXP_MISC	; Control registers (64KB @E90000)
		board	  028,"ACA1234",		MSG_EXP_TURBO	; Control registers (64KB @E90000)
		board	  029,"ACA1234",		MSG_EXP_RAM
		board	  032,"ACA1233n (020 mode)",	MSG_EXP_RAM	; Serial = MHz, >128 = 2019 version
		board	  033,"ACA1233n",		MSG_EXP_TURBOANDRAM ; Serial = MHz, >128 = 2019 version
		boardf	  042,f_icomp_042
		board	  064,"ACA500",			MSG_EXP_MISC
		board	  065,"ACA500plus",		MSG_EXP_MISC
		board	  066,"Catweasel MK3",		MSG_EXP_FLOPPY
		board	  068,"ACA1233n (2016.0)",	MSG_EXP_TURBOANDRAM	; Serial = MHz
		board	  069,"ACA630",			MSG_EXP_TURBOANDRAM
		board	  070,"ACA620",			MSG_EXP_TURBOANDRAM
		board	  072,"ACA1233n (2016.0, 020 mode)", MSG_EXP_RAM 	; Serial = MHz
		board	  073,"ACA500plus virtual autoconfig", MSG_EXP_MISC
		board	  100,"X-Surf-100",		MSG_EXP_ETHERNET
		endmf	04626

		manuf	04648,"Flesch Hornemann"
		endmf	04648

		manuf	04680,"Kupke/Golem"
		board	  001,"OMTI HD 3000",		MSG_EXP_MFMHD
		endmf	04680

		manuf	04711,"RBM Digitaltechnik"
		board	  001,"IOBlix",			MSG_EXP_MULTIIO
		board	  002,"IOBlix 1200S",		MSG_EXP_SERIAL
		board	  003,"IOBlix 1200P",		MSG_EXP_PARALLEL
		endmf	04711

		manuf	04754,"MacroSystems"
		endmf	04754

		manuf	05000,"ITH"
		board	  001,"ISDN-Master II",		MSG_EXP_ISDN
		endmf	05000

		manuf	05001,"VMC"
		board	  001,"ISDN Blaster Z2",	MSG_EXP_ISDN
		board	  002,"HyperCOM 4",		MSG_EXP_MULTIIO
		board	  003,"HyperCOM 3",		MSG_EXP_MULTIIO
		board	  006,"HyperCOM 4Z+",		MSG_EXP_MULTIIO
		board	  007,"HyperCOM 3+",		MSG_EXP_MULTIIO
		boarda	  015,"Michael B\xF6hmer","ICY",MSG_EXP_INTERFACE
		boarda	  239,"E3B","Highway (Prototype)",MSG_EXP_USB
		endmf	05001

		manuf	05010,"Amibience Creation Tech"
		board	  001,"Thylacine",		MSG_EXP_USB
		endmf	05010

		manuf	05011,"Creative Development"
		endmf	05011

		manuf	05012,"Georg Braun"
		board	  011,"Phoenix Turbo-II",	MSG_EXP_TURBO
		board	  012,"Phoenix Turbo-FE",	MSG_EXP_TURBO
		board	  013,"Turbo IV / GBA1000 SRAM",MSG_EXP_TURBOANDRAM
		board	  014,"GBA1000 SDRAM-1",	MSG_EXP_RAM
		board	  015,"GBA1000 SDRAM-2",	MSG_EXP_RAM
		board	  021,"Phoenix 4MB",		MSG_EXP_RAM
		board	  022,"CDTV 4MB",		MSG_EXP_RAM
		board	  023,"Phoenix 8MB",		MSG_EXP_RAM
		board	  040,"GBA1000-60 SDRAM-1",	MSG_EXP_RAM
		board	  041,"GBA1000-60 SDRAM-2",	MSG_EXP_RAM
		board	  042,"GBA Mini-Thylacine USB Controller",MSG_EXP_USB
		endmf	05012

		manuf	05013,"Swedish UG"
		endmf	05013

		manuf	05014,"Jakub Bednarski"
		endmf	05014

		manuf	05015,"KryoFlux"
		board	  006,"Zeus68k",		MSG_EXP_IDEHD
		board	  008,"Zeus68k",		MSG_EXP_TURBO
		endmf	05015

		manuf	05016,"Apollo Team"	; Igor Majstorovic?
		board	  001,"Vampire 600",		MSG_EXP_TURBO
		board	  002,"Vampire 500",		MSG_EXP_TURBO
		board	  003,"FireBird V4",		MSG_EXP_TURBO
		board	  004,"IceDrake V4",		MSG_EXP_TURBO
		board	  005,"V4 Standalone",		MSG_EXP_TURBO
		board	  006,"Vampire 1200",		MSG_EXP_TURBO
		board	  007,"Manticore V4",		MSG_EXP_TURBO
		endmf	05016

		manuf	05017,"Alastair M. Robinson"
		board	  017,"Minimig Z3 FastRAM",	MSG_EXP_RAM
		endmf	05017

		manuf	05018,"Austex Software"
		endmf	05018

		manuf	05019,"S\xF6ren Gust"
		endmf	05019

		manuf	05020,"Rok Krajnc"
		board	  000,"Minimig Z2 FastRAM",	MSG_EXP_RAM
		board	  016,"Minimig Z3 FastRAM",	MSG_EXP_RAM
		board	  032,"Minimig Z3 EthernetCard",MSG_EXP_ETHERNET
		board	  048,"Minimig Z3 GraphicsCard",MSG_EXP_GFX
		board	  064,"Minimig Z3 SoundCard",	MSG_EXP_AUDIO
		endmf	05020

		manuf	05030,"Tim Tashpulatov"
		board	  023,"Z3SDRam",		MSG_EXP_RAM
		board	  024,"dm9k",			MSG_EXP_ETHERNET
		endmf	05030

		manuf	05040,"7-bit"
		board	  017,"Wicher 500I",		MSG_EXP_MISC
		endmf	05040

		manuf	05050,"Sakura IT"
		endmf	05050

		manuf	05060,"FPGA Arcade"
		board	  010,"Replay",			MSG_EXP_AUDIO
		board	  016,"Replay",			MSG_EXP_ETHERNET
		board	  020,"Replay",			MSG_EXP_GFX
		endmf	05060

		manuf	05070,"CancerSoft"
		endmf	05070

		manuf	05080,"TerribleFire"		; Stephen Leary?
		board	  000,"A TerribleFire board",	MSG_EXP_TURBO
		board	  130,"TF1260",			MSG_EXP_TURBO
		endmf	05080

		manuf	05090,"iRIX Labs"		; http://irixlabs.com/
		board	  001,"HC 508",			MSG_EXP_TURBO
		board	  002,"SD Drive",		MSG_EXP_HD	; Classic 520 & SD Drive Z2
		board	  005,"Classic 520",		MSG_EXP_RAM
		endmf	05090

		manuf	05100,"Brookhouse Engineering"
		endmf	05100

		manuf	05110,"Eduardo Arana"
		endmf	05110

		manuf	05120,"CS-LAB"
		board	  001,"WARP",			MSG_EXP_TURBO
		endmf	05120

		manuf	05130,"Roert Miranda"
		endmf	05130

		manuf	05140,"RastPort"
		endmf	05140

		manuf	05150,"Amiga Kit"
		board	  001,"ZorRAM A2000",		MSG_EXP_RAM
		board	  002,"A1200 8MB",		MSG_EXP_RAM
		board	  003,"A600 8MB",		MSG_EXP_RAM
		board	  004,"A500 8MB",		MSG_EXP_RAM
		board	  005,"A1200 8MB v2",		MSG_EXP_RAM
		board	  006,"ZorRAM 8MB v2",		MSG_EXP_RAM
		endmf	05150

		manuf	05160,"Central Texas CUG"
		endmf	05160

		manuf	05170,"Confusion Research Center"
		endmf	05170

		manuf	05180,"Solar Soyuz Zaibatsu"
		endmf	05180

		manuf	05190,"Matthias Hampel"
		board	  010,"Freeway",		MSG_EXP_USB
		endmf	05190

		manuf	05191,"a1k.org Community"
		boarda	  010,"Matthias Hampel","Freeway",MSG_EXP_USB
		board	  011,"Freeway Pro",		MSG_EXP_USB
		endmf	05191

		manuf	05500,"Inhouse Information"
		board	  100,"ISDN Engine I",		MSG_EXP_ISDN
		endmf	05500

		manuf	05768,"Bio-Con"
		board	  137,"BC-1208MA",		MSG_EXP_MISC
		endmf	05768

		manuf	06148,"HK-Computer"
		board	  000,"Vector",			MSG_EXP_RAM
		endmf	06148

		manuf	06502,"Cloanto"
		endmf	06502

		manuf	06520,"Oliver Gantert"
		endmf	06520

		manuf	07777,"Rafal Gabriel Chyla"
		board	  034,"30t 68020",		MSG_EXP_TURBO
		endmf	07777

		manuf	08215,"Vortex"
		board	  003,"Athlet",			MSG_EXP_IDEHD
		board	  007,"Golden Gate 80386SX",	MSG_EXP_BRIDGE
		board	  008,"Golden Gate 80386SX",	MSG_EXP_RAM
		board	  009,"Golden Gate 80486",	MSG_EXP_BRIDGE
		endmf	08215

		manuf	08244,"Spirit"
		board	  003,"InBoard",		MSG_EXP_MISC
		endmf	08244

		manuf	08290,"Expansion Systems"
		board	  001,"DataFlyer",		MSG_EXP_SCSIHD
		board	  002,"\241DataFlyer",		MSG_EXP_RAM
		endmf	08290

		manuf	08448,"ReadySoft"
		board	  001,"AMax II/IV",		MSG_EXP_MACEMU
		endmf	08448

		manuf	08512,"Phase 5"
		board	  001,"Blizzard 1-8MB",		MSG_EXP_RAM
		board	  002,"Blizzard",		MSG_EXP_TURBO
		board	  006,"Blizzard 1220-IV",	MSG_EXP_TURBO
		board	  010,"FastLane Z3",		MSG_EXP_RAM
		boardf	  011,f_phase5_011
		boardf	  012,f_phase5_012
		board	  013,"\247Blizzard 12\24730",	MSG_EXP_TURBO	; Blizzard 1230-I -II -III
		boardf	  017,f_phase5_017
		boardf	  024,f_phase5_024
		board	  025,"\247CyberStorm \'0\24760 MK-II",MSG_EXP_TURBO
		board	  034,"CyberVision 64",		MSG_EXP_GFX
		board	  050,"CyberVision 3D Prototype",MSG_EXP_GFX
		board	  067,"CyberVision 3D",		MSG_EXP_GFX
		board	  068,"CyberVision PPC",	MSG_EXP_GFX
		boardf	  100,f_phase5_100
		board	  101,"G-Rex 1200",		MSG_EXP_BUSBRIDGE
		board	  110,"Blizzard PPC",		MSG_EXP_TURBOSCSIHD
		endmf	08512

		manuf	08553,"Digital Processing Systems"
		board	  001,"Personal Animation Recorder",MSG_EXP_VIDEO
		endmf	08553

		manuf	08704,"ACT"
		boardf	  000,f_act_000
		boarda	  001,"Sang/C\'T","Transputer Link",MSG_EXP_INTERFACE
		endmf	08704

		manuf	08738,"ACT"
		board	  034,"AT-Apollo",		MSG_EXP_MISC
		boardf	  035,f_apollo_035
		endmf	08738

		manuf	09512,"Tower Technologies"
		board	  000,"ZetaCom Z2 Prototype",	MSG_EXP_MULTIIO
		board	  001,"ZetaCom Z2",		MSG_EXP_MULTIIO
		endmf	09512

		manuf	09999,"QuikPak"
		board	  022,"A40\24760T 680\24760",	MSG_EXP_TURBO
		endmf	09999

		manuf	10676,"Electronic Design"
		board	  001,"Frame Machine",		MSG_EXP_VIDEO
		board	  136,"ZIP",			MSG_EXP_RAM
		endmf	10676

		manuf	14195,"Media-net-Point"
		endmf	14195

		manuf	14501,"Petsoff LP"
		board	  000,"Delfina DSP",		MSG_EXP_DSP
		board	  001,"Delfina DSP Lite",	MSG_EXP_DSP
		board	  002,"Delfina DSP Plus",	MSG_EXP_DSP
		endmf	14501

		manuf	16375,"Uwe Gerlach"
		board	  212,"RAM/ROM",		MSG_EXP_MISC
		endmf	16375

		manuf	16707,"At\xE9o Concepts"
		board	  252,"At\xE9oBus (IO)",	MSG_EXP_BUSBRIDGE
		board	  253,"\241At\xE9oBus (Memory)",MSG_EXP_BUSBRIDGE
		board	  254,"Pixel64",		MSG_EXP_GFX
		board	  255,"\241Pixel64",		MSG_EXP_GFXRAM
		endmf	16707

		manuf	16708,"ALiENDESiGN"
		board	  000,"RePulse",		MSG_EXP_AUDIO
		endmf	16708

		manuf	16945,"Albrecht Computer Technik"
		board	  001,"Prelude",		MSG_EXP_AUDIO
		endmf	16945

		manuf	17440,"HK Computer"		; Vector ?
		board	  000,"Vector",			MSG_EXP_RAM
		boarda	  001,"Elsat","E1204",		MSG_EXP_TURBOANDRAM
		endmf	17440

		manuf	18260,"MacroSystem"
		board	  003,"Maestro",		MSG_EXP_AUDIO
		board	  004,"VLab",			MSG_EXP_VIDEO
		board	  005,"MaestroPro",		MSG_EXP_AUDIO
		board	  006,"Retina",			MSG_EXP_GFX
		board	  008,"MultiEvolution",		MSG_EXP_SCSIHD
		board	  012,"Toccata",		MSG_EXP_AUDIO
		board	  016,"Retina BLT Z3",		MSG_EXP_GFX
		board	  018,"VLab-Motion",		MSG_EXP_VIDEO
		board	  019,"DraCo Altais",		MSG_EXP_GFX
		board	  023,"DraCo Motion",		MSG_EXP_VIDEO
		board	  024,"DraCo MachineControl",	MSG_EXP_MULTIIO
		board	  253,"Falcon \'040",		MSG_EXP_TURBO
		endmf	18260

		manuf	19796,"Markt & Technik"
		board	  042,"RAM/ROM",		MSG_EXP_MISC
		endmf	19796

		manuf	22359,"Markt & Technik"
		board	  137,"Videotext decoder",	MSG_EXP_MISC
		endmf	22359

		manuf	26464,"Combitec"
		board	  018,"?",			MSG_EXP_RAM
		endmf	26464

		manuf	26470,"Combitec"
		board	  018,"?",			MSG_EXP_RAM
		board	  130,"?",			MSG_EXP_RAM
		endmf	26470

		manuf	28014,"MNT Research"
		board	  001,"VA2000",			MSG_EXP_GFX	; Zorro III
		board	  002,"VA2000",			MSG_EXP_GFX	; Zorro II
		board	  003,"ZZ9000",			MSG_EXP_GFXRAM	; Zorro II
		board	  004,"ZZ9000",			MSG_EXP_GFXRAM	; Zorro III
		board	  005,"ZZ9000",			MSG_EXP_RAM	; Zorro III
		endmf	28014

		manuf	28019,"Michal Schulz"
		board	  001,"Emu68 Support",		MSG_EXP_MISC
		board	  016,"RAM Expansion",		MSG_EXP_RAM
		board	  033,"Device Tree",		MSG_EXP_MISC
		board	  034,"Broadcom SDHC",		MSG_EXP_HD
		endmf	28019

		manuf	32768,"SKI Peripherals"
		board	  008,"M.A.S.T. Fireball",	MSG_EXP_SCSIHD
		board	  128,"SCSI / Dual Serial",	MSG_EXP_MISC
		endmf	32768

		manuf	43437,"Reis-Ware"
		board	  017,"Scan King",		MSG_EXP_SCANIF
		endmf	43437

		manuf	43521,"Cameron"
		board	  016,"Personal",		MSG_EXP_SCANIF ; a4 / 1 Bit hand scanner
		endmf	43521

		manuf	43537,"Reis-Ware"
		board	  017,"Handyscanner",		MSG_EXP_SCANIF
		endmf	43537

		manuf	44359,"Matay"
		board	  001,"Prometheus (Rev. E)",	MSG_EXP_BUSBRIDGE
		endmf	44359

		manuf	46504,"Phoenix"
		board	  033,"ST506 Autoboot",		MSG_EXP_MFMHD
		board	  034,"SCSI Autoboot",		MSG_EXP_SCSIHD
		board	  064,"DMX",			MSG_EXP_MISC
		board	  190,"Memory",			MSG_EXP_RAM
		endmf	46504

		manuf	49160,"Combitec"
		board	  042,"OMTI",			MSG_EXP_HD
		board	  043,"SRAM Card",		MSG_EXP_RAM
		endmf	49160

		manuf	61453,"Forefront Technologies"
		endmf	61453

		manuf	63524,"Inverted Prototype ID"
		endmf	63524

		manuf	63525,"2-complement Prototype ID"
		endmf	63525,END

		; IMPORTANT: Last emdmf must have the END parameter appended!

		SECTION strings,DATA
		IFGT	(*-strbase)-32767
		  FAIL	"** Table of names exceeded maximum space!"
		ENDC



		SECTION text,CODE

**
* ======== BOARD SPECIFIC FUNCTIONS ========
*
* These functions are invoked if different boards share the same board ID. They
* are supposed to evaluate what actual board is present in the system, e.g. by
* checking manufacturer proprietary sub-IDs.
*
* For database queries by manufacturer ID and board ID, the board might not actually
* be present in the system for further checks. The functions must be prepared to get
* NULL as ConfigDev pointer, and return a fixed (random) example board instead.
*
* All functions have this register allocation:
*	-> A0.l	^Current manufacturer name
*	-> A3.l ^Current board structure
*	-> A4.l ^String base
*	-> A5.l ^ConfigDev or NULL (!)
*	<- D0.l Class ID
*	<- A0.l ^Manufacturer name (might be changed)
*	<- A1.l ^Board name
* Registers A4,D4-D6 MUST NOT be changed!
*

**
* GVP (02017) ID 11
*
gvpepclist	gvpinit
		gvpepc	$20,"G-Force \'040",	MSG_EXP_TURBO
		gvpepc	$30,"G-Force \'040",	MSG_EXP_TURBOSCSIHD
		gvpepc	$40,"A1291",		MSG_EXP_SCSIHD
		gvpepc	$60,"Combo \'030 R4",	MSG_EXP_TURBO
		gvpepc	$70,"Combo \'030 R4",	MSG_EXP_TURBOSCSIHD
		gvpepc	$78,"Phone Pak",	MSG_EXP_UNKNOWN
		gvpepc	$98,"IO-Extender",	MSG_EXP_MULTIIO
		gvpepc	$a0,"G-Force \'030",	MSG_EXP_TURBO
		gvpepc	$b0,"G-Force \'030",	MSG_EXP_TURBOSCSIHD
		gvpepc	$c0,"A530",		MSG_EXP_TURBO
		gvpepc	$d0,"A530",		MSG_EXP_TURBOSCSIHD
		gvpepc	$e0,"Combo \'030 R3",	MSG_EXP_TURBO
		gvpepc	$f0,"Combo \'030 R3",	MSG_EXP_TURBOSCSIHD
gvpepcfix	gvpepc	$f8,"Impact Series II",	MSG_EXP_SCSIHD
		gvpend

f_gvp_011	move.l	a5,d0			; ConfigDev present?
		beq	.fix			;  no -> just return a fixed board
	;-- get the GVP EPC
		move.l	(cd_BoardAddr,a5),a1
		add.l	#$8000,a1
		move.b	(1,a1),d0
		and	#GVP_EPCMASK,d0
	;-- scan the list of EPCs
		lea	(gvpepclist,PC),a2
.loop		sub.b	(a2)+,d0
		beq	.found
		bcs	.fix
		addq.l	#gvp_SIZEOF-1,a2
		bra	.loop
	;-- fetch name and type
.found		moveq	#0,d0
		move.b	(a2)+,d0
		add.l	#MSG_EXP_UNKNOWN-1,d0
		move	(a2),d1
		lea	(a4,d1.w),a1
		rts

	;-- use a fix record
.fix		lea	(gvpepcfix+1,PC),a2
		bra	.found


**
* Phase 5 (08512) ID 011
*
		defstr	blizz1230ii,"\247Blizzard 1230-II", 	MSG_EXP_TURBO
		defstr	fastlane,"FastLane Z3",			MSG_EXP_SCSIHD
		defstr	cyberscsi,"CyberSCSI",			MSG_EXP_SCSIHD
		defstr	cyber040,"\247CyberStorm 0\24740",	MSG_EXP_TURBO

f_phase5_011	move.l	a5,d0			; ConfigDev present?
		beq	.fastlane		;  no -> return a fixed board
	;-- find out type
		move.l	(cd_BoardAddr,a5),a1
		move.b	(cd_Rom+er_Type,a5),d1
		and.b	#ERT_TYPEMASK,d1
		cmp.b	#ERT_ZORROIII,d1	; if it's a Zorro III board,
		beq	.fastlanecyber		;  it's a FastLane or CyberSCSI
	;-- Cyberstorm 040?
		move.l	(execbase,PC),a1
		move	(AttnFlags,a1),d1
		btst	#AFB_68040,d1		; if there is a 040 processor present
		bne	.cyber040		;   it's likely a 040 MK-I
	;-- Blizzard 1230
		lea	(str_blizz1230ii,a4),a1 ; otherwise it must be a Blizzard
		move.l	#typ_blizz1230ii,d0
		bra	.done
	;-- CyberStorm 040
.cyber040	lea	(str_cyber040,a4),a1
		move.l	#typ_cyber040,d0
		bra	.done
	;-- Fastlane oder CyberSCSI
.fastlanecyber	bsr	NameFromNode		; find handler node
		beq	.cyberscsi
		move.l	d0,a1
		cmp.b	#"z",(a1)+
		bne	.cyberscsi
		cmp.b	#"3",(a1)
		bne	.cyberscsi
	;-- Fastlane
.fastlane	lea	(str_fastlane,a4),a1
		move.l	#typ_fastlane,d0
		bra	.done
	;-- CyberSCSI
.cyberscsi	lea	(str_cyberscsi,a4),a1
		move.l	#typ_cyberscsi,d0
	;-- done
.done		rts


**
* Phase 5 (08512) ID 012
*
		defstr	blizz1220,"Blizzard 1220",	MSG_EXP_TURBO
		defstr	cybfastscsi,"CyberStorm",	MSG_EXP_SCSIHD

f_phase5_012	move.l	a5,d0			; ConfigDev present?
		beq	.blizz1220		;  no -> return a fixed board
	;-- find out type
		move.l	(execbase,PC),a1
		move	(AttnFlags,a1),d1
		btst	#AFB_68020,d1		; 020 present?
		beq	.cyberstorm		;  then it's a CyberStorm SCSI
		btst	#AFB_68030,d1		; no 030+ present?
		bne	.cyberstorm		;  then it's a CyberStorm SCSI
	;-- Blizzard 1230-IV
.blizz1220	lea	(str_blizz1220,a4),a1
		move.l	#typ_blizz1220,d0
		bra	.done
	;-- CyberStorm SCSI
.cyberstorm	lea	(str_cybfastscsi,a4),a1
		move.l	#typ_cybfastscsi,d0
	;-- done
.done		rts


**
* Phase 5 (08512) ID 017
*
		defstr	blizz1230iv,"Blizzard 1230-IV",	MSG_EXP_TURBO
		defstr	blizz1240,"Blizzard 1240T/ERC", MSG_EXP_TURBO
		defstr	blizz1260,"Blizzard 1260",	MSG_EXP_TURBO

f_phase5_017	move.l	a5,d0			; ConfigDev present?
		beq	.bliz060		;  no -> return a fixed board
	;-- find out type
		move.l	(execbase,PC),a1
		move	(AttnFlags,a1),d1
		btst	#AFB_68060,d1		; 060 present?
		bne	.bliz060		;  then it's a Blizzard 1260
		btst	#AFB_68040,d1		; 040 present?
		bne	.bliz040		;  then it's a Blizzard 1240
	;-- Blizzard 1230-IV
		lea	(str_blizz1230iv,a4),a1
		move.l	#typ_blizz1230iv,d0
		bra	.done
	;-- Blizzard 1240
.bliz040	lea	(str_blizz1240,a4),a1
		move.l	#typ_blizz1240,d0
		bra	.done
	;-- Blizzard 1260
.bliz060	lea	(str_blizz1260,a4),a1
		move.l	#typ_blizz1260,d0
	;-- done
.done		rts


**
* Phase 5 (08512) ID 024
*
		defstr	blizz2060,"Blizzard 2060",	MSG_EXP_TURBOANDRAM
		defstr	blizz2040,"Blizzard 2040ERC",	MSG_EXP_TURBOANDRAM

f_phase5_024	move.l	a5,d0			; ConfigDev present?
		beq	.bliz060		;  no -> return a fixed board
	;-- find out type
		move.l	(execbase,PC),a1
		move	(AttnFlags,a1),d1
		btst	#AFB_68060,d1		; 060 present?
		bne	.bliz060		;  then it's a Blizzard 2060
	;-- Blizzard 2040
		lea	(str_blizz2040,a4),a1
		move.l	#typ_blizz2040,d0
		bra	.done
	;-- Blizzard 2060
.bliz060	lea	(str_blizz2060,a4),a1
		move.l	#typ_blizz2060,d0
	;-- done
.done		rts


**
* Apollo (08738) ID 035
*
		defstr	app1230,"Apollo 1230",		MSG_EXP_TURBO
		defstr	app2030,"Apollo 2030",		MSG_EXP_TURBO
		defstr	app1240,"Apollo 1240",		MSG_EXP_TURBO
		defstr	app1260,"Apollo 1260",		MSG_EXP_TURBO
		defstr	app4040,"Apollo 4040",		MSG_EXP_TURBO
		defstr	app4060,"Apollo 4060",		MSG_EXP_TURBO

f_apollo_035	move.l	a5,d0			; ConfigDev present?
		beq	.app1230		;  no -> return a fixed board
	;-- find out type
		move.l	(execbase,PC),a1
		move	(AttnFlags,a1),d1
		btst	#AFB_68060,d1		; 060 present?
		bne	.app1260		;  check 060 boards
		btst	#AFB_68040,d1		; 040 present?
		bne	.app1240		;  check 040 boards
	;-- check for AGA chipset
		move	$dff07c,d1
		cmp.b	#$f8,d1
		beq	.app1230		; AGA -> Apollo 1230
	;-- check 040 boards
.app1240	bsr	isA1200			; Amiga 1200?
		beq	.is_app1240
		lea	(str_app4040,a4),a1	;  no -> Apollo 4040
		move.l	#typ_app4040,d0
		bra	.done
.is_app1240	lea	(str_app1240,a4),a1	;  yes -> Apollo 1240
		move.l	#typ_app1240,d0
		bra	.done
	;-- check 060 boards
.app1260	bsr	isA1200			; Amiga 1200?
		beq	.is_app1260
		lea	(str_app4060,a4),a1	;  no -> Apollo 4060
		move.l	#typ_app4060,d0
		bra	.done
.is_app1260	lea	(str_app1260,a4),a1	;  yes -> Apollo 1260
		move.l	#typ_app1260,d0
		bra	.done
	;-- Apollo 2030
.app2030	lea	(str_app2030,a4),a1
		move.l	#typ_app2030,d0
		bra	.done
	;-- Apollo 1230
.app1230	lea	(str_app1230,a4),a1
		move.l	#typ_app1230,d0
	;-- done
.done		rts


**
* DKB (02012) ID 023
*
		defstr	dkb060turbo,"WildFire 060",	MSG_EXP_TURBO
		defstr	dkb060kick,"WildFire 060",	MSG_EXP_KICKSTART

f_dkb_023	move.l	a5,d0			; ConfigDev present?
		beq	.dkbturbo		;  no -> return a fixed board
	;-- find out type
		cmp.l	#512*1024,(cd_BoardSize,a5) ; 512 KB Board size?
		bne	.dkbturbo		;  no -> it's the turbo board
	;-- DKB kickstart
.dkbkick	lea	(str_dkb060kick,a4),a1
		move.l	#typ_dkb060kick,d0
		bra	.done
	;-- DKB turbo
.dkbturbo	lea	(str_dkb060turbo,a4),a1
		move.l	#typ_dkb060turbo,d0
	;-- done
.done		rts


**
* Phase 5 (08512) ID 100
*
		defstr	cyberppc,"CyberStorm PPC",	MSG_EXP_TURBOSCSIHD
		defstr	cybermk3,"\247CyberStorm \'0\24760 MK-III",MSG_EXP_TURBOSCSIHD

f_phase5_100	move.l	a0,-(SP)		; is there a PowerPC?
		moveq	#IDHW_POWERPC,d0
		sub.l	a0,a0
		bsr	IdHardwareNum
		cmp.l	#IDPPC_NONE,d0
		beq	.mk3
	;-- CyberPPC
		lea	(str_cyberppc,a4),a1
		move.l	#typ_cyberppc,d0
		bra	.done
	;-- CyberMKIII
.mk3		lea	(str_cybermk3,a4),a1
		move.l	#typ_cybermk3,d0
	;-- done
.done		move.l	(SP)+,a0
		rts


**
* UAE (02011) ID 001
*
		defstr	uae001,"Fast RAM",	MSG_EXP_RAM
		defstr2 uae001mf,"UAE"
		defstr	hacker,"?",		MSG_EXP_SCSIHD
		defstr2 hackermf,"Hacker Inc."

f_uae_001	move.l	a5,d0			; ConfigDev present?
		beq	.hacker			;  no -> return a fixed board
	;-- find out type
		bsr	isEmulated		; Are we living in an emulation?
		bne	.hacker
	;-- UAE Emulated
		lea	(str_uae001mf,a4),a0
		lea	(str_uae001,a4),a1
		move.l	#typ_uae001,d0
		bra	.done
	;-- DKB turbo
.hacker		lea	(str_hackermf,a4),a0
		lea	(str_hacker,a4),a1
		move.l	#typ_hacker,d0
	;-- done
.done		rts


**
* ACT (08704) ID 000
*
		defstr	act620,"Apollo A620 68020",	MSG_EXP_TURBO
		defstr	sx32,"SX32 MK2",		MSG_EXP_TURBO

f_act_000	move.l	a5,d0			; ConfigDev present?
		beq	.hacker			;  no -> return a fixed board
	;-- find out type
		move.l	a0,a2			; is there a cdui.library?
		moveq	#0,d0
		exec	OpenLibrary
		move.l	a2,a0
		tst.l	d0
		beq	.hacker			;  no -> Apollo A620
		move.l	d0,a1
		exec.q	CloseLibrary
		move.l	a2,a0
	;-- SX32
		lea	(str_sx32,a4),a1
		move.l	#typ_sx32,d0
		bra	.done
	;-- ACT turbo
.hacker		lea	(str_act620,a4),a1
		move.l	#typ_act620,d0
	;-- done
.done		rts
.cduiname	dc.b	"cdui.library",0	 ;cdui.library (CD32)
		even


**
* UAE (02011) ID 002
*
		defstr	uae002,"Filesystem", 	MSG_EXP_HD
		defstr2 uae002mf,"UAE"
		defstr	rmf,"QuickNet QN2000", 	MSG_EXP_ETHERNET
		defstr2 rmfmf,"Resource Management Force"

f_uae_002	move.l	a5,d0			; ConfigDev present?
		beq	.rmf			;  no -> return a fixed board
	;-- find out tpe
		bsr	isEmulated		; Are we emulated?
		bne	.rmf
	;-- UAE Emulated
		lea	(str_uae002mf,a4),a0
		lea	(str_uae002,a4),a1
		move.l	#typ_uae002,d0
		bra	.done
	;-- RMF
.rmf		lea	(str_rmfmf,a4),a0
		lea	(str_rmf,a4),a1
		move.l	#typ_rmf,d0
	;-- done
.done		rts


**
* BSC (02092) ID 005
*
		defstr	okt2008,"Oktagon 2008",		MSG_EXP_SCSIHD
		defstr	okt4008,"Oktagon 4008",		MSG_EXP_SCSIHD

f_bsc_005	move.l	a5,d0			; ConfigDev present?
		beq	.o2008			;  no -> return a fixed board
	;-- find out type
		move	$dff07c,d1		; Are we AGA?
		and	#$000F,d1
		cmp	#$0008,d1
		beq	.o4008
	;-- Oktagon 2008
.o2008		lea	(str_okt2008,a4),a1
		move.l	#typ_okt2008,d0
		bra	.done
	;-- Oktagon 4008
.o4008		lea	(str_okt4008,a4),a1
		move.l	#typ_okt4008,d0
	;-- done
.done		rts


**
* BSC (02092) ID 006
*
		defstr	tandem,"Tandem AT-2008/508",	MSG_EXP_IDEHD
		defstr	ide68030tk,"68030TK IDE controller", MSG_EXP_IDEHD
		defstr2 ide68030tkmf,"a1k.org Community"

f_bsc_006	move.l	a5,d0			; ConfigDev present?
		beq	.istandem		;  no -> return a fixed board
	;-- 68030TK present?
		move.l	#2588,d0		; a1k.org Community
		move.l	#2,d1			; 68030TK RAM
		bsr	isBoardPresent
		beq	.istandem
	;-- 68030TK IDE controller (obsolete ID)
		lea	(str_ide68030tkmf,a4),a0
		lea	(str_ide68030tk,a4),a1
		move.l	#typ_ide68030tk,d0
		bra	.done
	;-- Generic Expansion
.istandem	lea	(str_tandem,a4),a1
		move.l	#typ_tandem,d0
	;-- done
.done		rts


**
* Individual Computers (04626) ID 000
*
		defstr	icompbuddha,"Buddha", MSG_EXP_IDEHD
		defstr	icompflash,"Buddha Flash", MSG_EXP_IDEHD
f_icomp_000	move.l	a5,d0			; ConfigDev present?
		beq	.ibuddha		;  no -> return generic expansion
	;-- check serial number
		move.l	(cd_Rom+er_SerialNumber,a5),d0
		beq	.ibuddha
	;-- buddha flash
		lea	(str_icompflash,a4),a1
		move.l	#typ_icompflash,d0
		bra	.done
	;-- buddha classic or generic
.ibuddha	lea	(str_icompbuddha,a4),a1
		move.l	#typ_icompbuddha,d0
	;-- done
.done		rts


**
* Individual Computers (04626) ID 026
*
		defstr	icompmemory,"BigRam 2630",		MSG_EXP_RAM
		defstr	icompreverse,"BigRam 2630 Reverse",	MSG_EXP_RAM
		defstr	icompaca1211,"ACA1211",			MSG_EXP_RAM
f_icomp_026	move.l	a5,d0			; ConfigDev present?
		beq	.imemory		;  no -> return generic memory expansion
	;-- is ACA1211 present?
		move.l	#4626,d0		; Individual Computers
		move.l	#27,d1			; ACA1211 registers
		bsr	isBoardPresent
		bne	.iaca1211
	;-- BigRam Reverse Edition?
		move.l	(cd_Rom+er_SerialNumber,a5),d0
		cmp.l	#2631,d0
		bne	.imemory
		lea	(str_icompreverse,a4),a1
		move.l	#typ_icompreverse,d0
		bra	.done
	;-- ACA1211 Memory Expansion
.iaca1211	lea	(str_icompaca1211,a4),a1
		move.l	#typ_icompaca1211,d0
		bra	.done
	;-- BigRam Memory Expansion
.imemory	lea	(str_icompmemory,a4),a1
		move.l	#typ_icompmemory,d0
	;-- done
.done		rts



**
* Individual Computers (04626) ID 042
*
		defstr	icompcatmk1,"Catweasel",	MSG_EXP_FLOPPY
		defstr	icompcatmk2,"Catweasel MK2",	MSG_EXP_FLOPPY
f_icomp_042	move.l	a5,d0			; ConfigDev present?
		beq	.imk1			;  no -> return generic expansion
	;-- check serial number
		move.l	(cd_Rom+er_SerialNumber,a5),d0
		cmp.l	#2,d0
		bne	.imk1
	;-- Catweasel MK2
		lea	(str_icompcatmk2,a4),a1
		move.l	#typ_icompcatmk2,d0
		bra	.done
	;-- Generic Expansion
.imk1		lea	(str_icompcatmk1,a4),a1
		move.l	#typ_icompcatmk1,d0
	;-- done
.done		rts


*
* ======== STATISTICS ========
*
		ECHO	"##"
		ECHO	"## Manufacturers = ",__GLBMANUF
		ECHO	"## Boards        = ",__GLBBOARD
		ECHO	"##"
