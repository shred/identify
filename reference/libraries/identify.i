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

		IFND	LIBRARIES_IDENTIFY_I
LIBRARIES_IDENTIFY_I	SET	1

		IFND	EXEC_TYPES_I
		 INCLUDE 'exec/types.i'
		ENDC

		IFND	EXEC_LIBRARIES_I
		 INCLUDE 'exec/libraries.i'
		ENDC

		IFND	UTILITY_TAGITEM_I
		 INCLUDE utility/tagitem.i
		ENDC

_IDTAGS		EQU	$CD450000

*
* Generic library informations
*
IDENTIFYNAME	MACRO
		dc.b	"identify.library",0
		ENDM

IDENTIFYVERSION EQU	39

	STRUCTURE IdentifyBase,0
	STRUCT	ifyb_LibNode,LIB_SIZE
	LABEL	ifyb_SIZEOF

IDENTIFYBUFLEN	EQU	50		; default buffer length

*
* Expansion() tags
*
IDTAG_ConfigDev EQU	_IDTAGS+$00	;(struct ConfigDev *) ConfigDev
					; structure to be evaluated
IDTAG_ManufID	EQU	_IDTAGS+$01	;UWORD manufacturer ID if no
					; ConfigDev is available
IDTAG_ProdID	EQU	_IDTAGS+$02	;UBYTE product ID if no
					; ConfigDev is available
IDTAG_StrLength EQU	_IDTAGS+$03	;UWORD of maximum buffer length,
					; including termination. Default
					; is 50.
IDTAG_ManufStr	EQU	_IDTAGS+$04	;STRPTR of manufacturer name
					; puffer, or NULL
IDTAG_ProdStr	EQU	_IDTAGS+$05	;STRPTR of product name
					; puffer, or NULL
IDTAG_ClassStr	EQU	_IDTAGS+$06	;STRPTR of product class
					; puffer, or NULL
IDTAG_DeadStr	EQU	_IDTAGS+$07	;STRPTR deadend or recoverable alert?
IDTAG_SubsysStr EQU	_IDTAGS+$08	;STRPTR alert subsystem
IDTAG_GeneralStr EQU	_IDTAGS+$09	;STRPTR alert general cause
IDTAG_SpecStr	EQU	_IDTAGS+$0A	;STRPTR alert specific cause
IDTAG_FuncNameStr EQU	_IDTAGS+$0B	;STRPTR function name
IDTAG_Expansion EQU	_IDTAGS+$0C	;(struct ConfigDev **) for a
					; complete expansion check. Init
					; the variable with NULL.
IDTAG_Secondary EQU	_IDTAGS+$0D	;BOOL warn for secondary expansion
					; boards (defaults to FALSE) [V7]
IDTAG_ClassID	EQU	_IDTAGS+$0E	;ULONG * class ID of the provided
					; expansion board (see below) [V8]
IDTAG_Localize	EQU	_IDTAGS+$0F	;BOOL return localized strings
					; (defaults to TRUE) [V8]
IDTAG_NULL4NA	EQU	_IDTAGS+$10	;BOOL return NULL for not available,
					; else return a string (defaults to
					; FALSE) [V8]
IDTAG_UnknownFlag EQU	_IDTAGS+$11	;UBYTE * A flag that will be set to
					; TRUE if the current expansion was not
					; found in the database. The content
					; will not be changed if the expansion
					; was found. [V39]
IDTAG_Delegate	EQU	_IDTAGS+$12	;BOOL TRUE if unknown boards shall be
					; delegated to other databases. FALSE
					; to skip checking other databases
					; (defaults to TRUE) [V40]

*
* Hardware description types
*
IDHW_SYSTEM	EQU	0	; System (Amiga,DraCo,...)		[V2]
IDHW_CPU	EQU	1	; CPU (68000,68010,...,68060)
IDHW_FPU	EQU	2	; FPU (---,68881,68882,68040,68060)
IDHW_MMU	EQU	3	; MMU (---,68852,68030,68040,68060)
IDHW_OSVER	EQU	4	; OS Version (V*.*)
IDHW_EXECVER	EQU	5	; Exec Version (V*.*)
IDHW_WBVER	EQU	6	; Workbench Version (---,V*.*)
IDHW_ROMSIZE	EQU	7	; OS ROM Size (*KB, *MB)
IDHW_CHIPSET	EQU	8	; Chipset (OCS,ECS,AGA,DraCo)
IDHW_GFXSYS	EQU	9	; Graphic OS (AmigaOS, CyberGraphX, ...)
IDHW_CHIPRAM	EQU	10	; All Chip RAM (*KB, *MB, *GB)
IDHW_FASTRAM	EQU	11	; All Fast RAM (*KB, *MB, *GB)
IDHW_RAM	EQU	12	; All Total RAM (*KB, *MB, *GB)
IDHW_SETPATCHVER EQU	13	; SetPatch Version (---,V*.*)		[V4]
IDHW_AUDIOSYS	EQU	14	; Audio OS (AmigaOS, AHI, ...)		[V5]
IDHW_OSNR	EQU	15	; AmigaOS (2.04, 3.1, ...)
IDHW_VMMCHIPRAM EQU	16	; VMM Chip RAM (*KB, *MB, *GB)
IDHW_VMMFASTRAM EQU	17	; VMM Fast RAM (*KB, *MB, *GB)
IDHW_VMMRAM	EQU	18	; VMM Total RAM (*KB, *MB, *GB)
IDHW_PLNCHIPRAM EQU	19	; Plain Chip RAM (*KB, *MB, *GB)
IDHW_PLNFASTRAM EQU	20	; Plain Fast RAM (*KB, *MB, *GB)
IDHW_PLNRAM	EQU	21	; Plain Total RAM (*KB, *MB, *GB)
IDHW_VBR	EQU	22	; Vector Base Register			[V6]
IDHW_LASTALERT	EQU	23	; Last Alert code
IDHW_VBLANKFREQ EQU	24	; VBlank Frequency
IDHW_POWERFREQ	EQU	25	; Power Frequency
IDHW_ECLOCK	EQU	26	; EClock
IDHW_SLOWRAM	EQU	27	; Plain Slow RAM (*KB, *MB, *GB)
IDHW_GARY	EQU	28	; Gary (---,Normal,...)
IDHW_RAMSEY	EQU	29	; RAMSEY (---,D,F)
IDHW_BATTCLOCK	EQU	30	; Battery Backed Up Clock (---,Found)
IDHW_CHUNKYPLANAR EQU	31	; Chunky To Planar Hardware (---,Found) [V7]
IDHW_POWERPC	EQU	32	; PowerPC present? (---,Found)
IDHW_PPCCLOCK	EQU	33	; PowerPC clock (unit MHz)
IDHW_CPUREV	EQU	34	; CPU revision				[V8]
IDHW_CPUCLOCK	EQU	35	; CPU clock (unit MHz)
IDHW_FPUCLOCK	EQU	36	; FPU clock (unit MHz)
IDHW_RAMACCESS	EQU	37	; Main board RAM access time (unit ns)
IDHW_RAMWIDTH	EQU	38	; Main board RAM width (bit)
IDHW_RAMCAS	EQU	39	; Main board RAM CAS mode
IDHW_RAMBANDWIDTH EQU	40	; Main board RAM bandwidth
IDHW_TCPIP	EQU	41	; TCP/IP stack				[V9]
IDHW_PPCOS	EQU	42	; PowerPC OS
IDHW_AGNUS	EQU	43	; Agnus chip revision
IDHW_AGNUSMODE	EQU	44	; Agnus chip mode
IDHW_DENISE	EQU	45	; Denise chip version			[V10]
IDHW_DENISEREV	EQU	46	; Denise chip revision
IDHW_BOINGBAG	EQU	47	; BoingBag Version (deprecated, part of IDHW_OSNR) [V12]
IDHW_EMULATED	EQU	48	; Emulated Amiga			[V13]
IDHW_XLVERSION	EQU	49	; AmigaXL version
IDHW_HOSTOS	EQU	50	; when emulated: Host OS (see autodocs!)
IDHW_HOSTVERS	EQU	51	; when emulated: Host Version (see autodocs!)
IDHW_HOSTMACHINE EQU	52	; when emulated: Host Machine (see autodocs!)
IDHW_HOSTCPU	EQU	53	; when emulated: Host CPU (see autodocs!)
IDHW_HOSTSPEED	EQU	54	; when emulated: Host CPU speed (unit MHz, see autodocs!)
IDHW_LASTALERTTASK EQU	55	; Task of last alert			[V37]
IDHW_PAULA	EQU	56	; Paula chip revision			[V38]
IDHW_ROMVER	EQU	57	; Physical ROM version
IDHW_RTC	EQU	58	; Realtime Clock			[V40]
IDHW_NUMBEROF	EQU	59	; Number of types, PRIVATE!

*
* IDHW_SYSTEM numerical result codes
*
IDSYS_AMIGA1000 EQU	0	; Amiga 1000
IDSYS_AMIGAOCS	EQU	1	; OCS Amiga 500/2000
IDSYS_AMIGAECS	EQU	2	; ECS Amiga 500/2000
IDSYS_AMIGA500	EQU	3	; Amiga 500
IDSYS_AMIGA2000 EQU	4	; Amiga 2000
IDSYS_AMIGA3000 EQU	5	; Amiga 3000
IDSYS_CDTV	EQU	6	; CDTV
IDSYS_AMIGA600	EQU	7	; Amiga 600
IDSYS_CD32	EQU	8	; CD32
IDSYS_AMIGA1200 EQU	9	; Amiga 1200
IDSYS_AMIGA4000 EQU	10	; Amiga 4000
IDSYS_DRACO	EQU	11	; DraCo
IDSYS_UAE	EQU	12	; Ubiquitous Amiga Emulator
IDSYS_AMIGA4000T EQU	13	; Amiga 4000 Tower
IDSYS_AMIGAXL	EQU	14	; AmigaXL

*
* IDHW_CPU numerical result codes
*
IDCPU_68000	EQU	0	; 68000
IDCPU_68010	EQU	1	; 68010
IDCPU_68020	EQU	2	; 68020
IDCPU_68030	EQU	3	; 68030
IDCPU_68EC030	EQU	4	; 68EC030 (without MMU)
IDCPU_68040	EQU	5	; 68040
IDCPU_68LC040	EQU	6	; 68LC040 (without FPU)
IDCPU_68060	EQU	7	; 68060
IDCPU_68LC060	EQU	8	; 68LC060 (without FPU)
IDCPU_FPGA	EQU	9	; FPGA based CPU

*
* IDHW_FPU numerical result codes
*
IDFPU_NONE	EQU	0	; no FPU
IDFPU_68881	EQU	1	; 68881
IDFPU_68882	EQU	2	; 68882
IDFPU_68040	EQU	3	; 68040
IDFPU_68060	EQU	4	; 68060
IDFPU_FPGA	EQU	5	; FPGA based FPU

*
* IDHW_MMU numerical result codes
*
IDMMU_NONE	EQU	0	; no MMU
IDMMU_68851	EQU	1	; 68851
IDMMU_68030	EQU	2	; 68030
IDMMU_68040	EQU	3	; 68040
IDMMU_68060	EQU	4	; 68060
IDMMU_FPGA	EQU	5	; FPGA based MMU

*
* IDHW_OSNR numerical result codes
*
IDOS_UNKNOWN	EQU	0	; none of the below
IDOS_2_0	EQU	1	; OS2.0	  (V36)
IDOS_2_04	EQU	2	; OS2.04  (V37)
IDOS_2_1	EQU	3	; OS2.1	  (V38)
IDOS_3_0	EQU	4	; OS3.0	  (V39)
IDOS_3_1	EQU	5	; OS3.1	  (V40)
IDOS_3_5	EQU	6	; OS3.5	  (V44 by Haage&Partner)
IDOS_3_9	EQU	7	; OS3.9	  (V45 by Haage&Partner)
IDOS_2_05	EQU	8	; OS2.05  (V37.299+)
IDOS_3_2_PROTO	EQU	9	; OS3.2	  (V43, Walker prototype)
IDOS_3_1_4	EQU 	10	; OS3.1.4 (V46 by Hyperion)
IDOS_3_2	EQU	11	; OS3.2   (V47.96 by Hyperion)
IDOS_3_2_1	EQU	12	; OS3.2.1 (V47.102 by Hyperion)
IDOS_3_5_BB1	EQU	13	; OS3.5   (V44.4 "Boing Bag 1")
IDOS_3_5_BB2	EQU	14	; OS3.5   (V44.5 "Boing Bag 2")
IDOS_3_9_BB1	EQU	15	; OS3.9   (V45.2 "Boing Bag 1")
IDOS_3_9_BB2	EQU	16	; OS3.9   (V45.3 "Boing Bag 2")
IDOS_4_0		EQU 17	; OS4.0 
IDOS_4_1		EQU 18	; OS4.1   (V53.18 update2)
*
* IDHW_CHIPSET numerical result codes
*
IDCS_OCS	EQU	0	; OCS
IDCS_ECS	EQU	1	; ECS
IDCS_AGA	EQU	2	; AGA
IDCS_ALTAIS	EQU	3	; DraCo Altais
IDCS_NECS	EQU	4	; Nearly ECS (no HR-Agnus or HR-Denise)
IDCS_SAGA	EQU	5	; SAGA

*
* IDHW_GFXSYS numerical result codes
*
IDGOS_AMIGAOS	EQU	0	; Plain AmigaOS
IDGOS_EGS	EQU	1	; EGS
IDGOS_RETINA	EQU	2	; Retina
IDGOS_GRAFFITI	EQU	3	; Graffiti
IDGOS_TIGA	EQU	4	; TIGA
IDGOS_PROBENCH	EQU	5	; Merlin ProBench
IDGOS_PICASSO	EQU	6	; Picasso
IDGOS_CGX	EQU	7	; CyberGraphX
IDGOS_CGX3	EQU	8	; CyberGraphX 3
IDGOS_PICASSO96 EQU	9	; Picasso96
IDGOS_CGX4	EQU	10	; CyberGraphX V4

*
* IDHW_AUDIOSYS numerical result codes
*
IDAOS_AMIGAOS	EQU	0	; Plain AmigaOS
IDAOS_MAESTIX	EQU	1	; MaestroPro driver
IDAOS_TOCCATA	EQU	2	; Toccata driver
IDAOS_PRELUDE	EQU	3	; Prelude driver
IDAOS_AHI	EQU	4	; AHI
IDAOS_MACROAUDIO EQU	5	; MacroAudio

*
* IDHW_GARY numerical result codes
*
IDGRY_NONE	EQU	0	; No Gary available
IDGRY_NORMAL	EQU	1	; Normal Gary
IDGRY_ENHANCED	EQU	2	; Enhanced Gary

*
* IDHW_RAMSEY numerical result codes
*
IDRSY_NONE	EQU	0	; No RamSey available
IDRSY_REVD	EQU	1	; RamSey Revision D
IDRSY_REVF	EQU	2	; RamSey Revision F

*
* IDHW_POWERPC numerical result codes
*
IDPPC_NONE	EQU	0	; No PowerPC implemented
IDPPC_OTHER	EQU	1	; Another PowerPC
IDPPC_602	EQU	2	; 602
IDPPC_603	EQU	3	; 603
IDPPC_603E	EQU	4	; 603e
IDPPC_603P	EQU	5	; 603p
IDPPC_604	EQU	6	; 604
IDPPC_604E	EQU	7	; 604e
IDPPC_620	EQU	8	; 620
IDPPC_750CXE	EQU	9
IDPPC_750FX 	EQU	10
IDPPC_750GX 	EQU	11
IDPPC_7410	EQU	12
IDPPC_74XX_VGER	EQU	13
IDPPC_74XX_APOLLO	EQU	14
IDPPC_405LP 	EQU	15
IDPPC_405EP	EQU	16
IDPPC_405GP	EQU	17
IDPPC_405GPR	EQU	18
IDPPC_440EP	EQU	19
IDPPC_440GP	EQU	20
IDPPC_440GX	EQU	21
IDPPC_440SX	EQU	22
IDPPC_440SP	EQU	23
IDPPC_PA6T_1682M	EQU	24
IDPPC_460EX	EQU	25
IDPPC_5121E	EQU	26
IDPPC_P50XX	EQU	27

*
* IDHW_RAMCAS numerical result codes
*
IDCAS_NONE	EQU	0	; Not available
IDCAS_NORMAL	EQU	1	; Normal access
IDCAS_DOUBLE	EQU	2	; Double access

*
* IDHW_TCPIP numerical result codes
*
IDTCP_NONE	EQU	0	; Not available
IDTCP_AMITCP	EQU	1	; AmiTCP
IDTCP_MIAMI	EQU	2	; Miami
IDTCP_TERMITE	EQU	3	; TermiteTCP
IDTCP_GENESIS	EQU	4	; GENESiS
IDTCP_MIAMIDX	EQU	5	; MiamiDX
IDTCP_ROADSHOW	EQU	6	; Roadshow

*
* IDHW_PPCOS numerical result codes
*
IDPOS_NONE	EQU	0	; None
IDPOS_POWERUP	EQU	1	; PowerUP (Phase 5)
IDPOS_WARPOS	EQU	2	; WarpOS (Haage&Partner)
IDPOS_AmigaOS_PPC	EQU	3	; Eyetech, ACubeSystems, A-EON,Hyperion
IDPOS_MorphOS	EQU	4	; MorphOS Development Team, 

*
* IDHW_AGNUS numerical result codes
*
IDAG_NONE	EQU	0	; None
IDAG_UNKNOWN	EQU	1	; Unknown Agnus
IDAG_8361	EQU	2	; Agnus 8361
IDAG_8367	EQU	3	; Agnus 8367
IDAG_8370	EQU	4	; Agnus 8370
IDAG_8371	EQU	5	; Agnus 8371
IDAG_8372_R4	EQU	6	; Agnus 8372 Rev. 1-4
IDAG_8372_R5	EQU	7	; Agnus 8372 Rev. 5
IDAG_8374_R2	EQU	8	; Alice 8374 Rev. 1-2
IDAG_8374_R3	EQU	9	; Alice 8374 Rev. 3-4
IDAG_ANNI	EQU	10	; Anni (SAGA)

*
* IDHW_DENISE numerical result codes
*
IDDN_NONE	EQU	0	; None
IDDN_UNKNOWN	EQU	1	; Unknown Denise (new model?! :-)
IDDN_8362	EQU	2	; Denise 8362
IDDN_8373	EQU	3	; Denise 8373
IDDN_4203	EQU	4	; Lisa 4203 (replaces IDDN_8364)
IDDN_ISABEL	EQU	5	; Isabel (SAGA)

*
* IDHW_PAULA numerical result codes
*
IDPL_NONE	EQU	0	; None
IDPL_UNKNOWN	EQU	1	; Unknown Paula
IDPL_8364	EQU	2	; Paula 8364
IDPL_ARNE	EQU	3	; Arne (SAGA)

*
* IDHW_AGNUSMODE numerical result codes
*
IDAM_NONE	EQU	0	; None
IDAM_NTSC	EQU	1	; NTSC Agnus
IDAM_PAL	EQU	2	; PAL Agnus

*
* IDHW_RTC numerical result codes
*
IDRTC_NONE	EQU	0	; None
IDRTC_OKI	EQU	1	; OKI MSM6242B
IDRTC_RICOH	EQU	2	; Ricoh RP5C01A

*
* IDTAG_ClassID numerical result codes
*
IDCID_UNKNOWN		EQU	0	; unknown functionality
IDCID_MISC		EQU	1	; miscellaneous expansion
IDCID_TURBO		EQU	2	; accelerator
IDCID_TURBORAM		EQU	3	; accelerator RAM
IDCID_TURBOHD		EQU	4	; accelerator + some HD controller
IDCID_TURBOIDE		EQU	5	; accelerator + AT-IDE controller
IDCID_TURBOSCSIHD	EQU	6	; accelerator + SCSI host adapter
IDCID_NET		EQU	7	; some network
IDCID_ARCNET		EQU	8	; ArcNet
IDCID_ETHERNET		EQU	9	; Ethernet
IDCID_AUDIO		EQU	10	; audio
IDCID_VIDEO		EQU	11	; video (video digitizer etc)
IDCID_MULTIMEDIA	EQU	12	; multimedia (audio, video, etc)
IDCID_DSP		EQU	13	; multi purpose DSP
IDCID_BUSBRIDGE		EQU	14	; ISA bus bridge
IDCID_BRIDGE		EQU	15	; PC bridge
IDCID_EMULATOR		EQU	16	; some Emulator hardware
IDCID_MACEMU		EQU	17	; Macintosh emulator hardware
IDCID_ATARIEMU		EQU	18	; Atari emulator hardware
IDCID_GFX		EQU	19	; graphics (register)
IDCID_GFXRAM		EQU	20	; graphics (video RAM)
IDCID_HD		EQU	21	; some HD controller
IDCID_HDRAM		EQU	22	; some HD controller + RAM
IDCID_IDEHD		EQU	23	; IDE controller
IDCID_IDEHDRAM		EQU	24	; IDE controller + RAM
IDCID_SCSIHD		EQU	25	; SCSI host adapter
IDCID_RAMSCSIHD		EQU	26	; SCSI host adapter + RAM
IDCID_CDROM		EQU	27	; CD-ROM interface
IDCID_MODEM		EQU	28	; internal modem
IDCID_ISDN		EQU	29	; internal ISDN terminal adapter
IDCID_MULTIIO		EQU	30	; multi I/O (serial + parallel)
IDCID_SERIAL		EQU	31	; multi serial (no parallel)
IDCID_PARALLEL		EQU	32	; multi parallel (no serial)
IDCID_SCANIF		EQU	33	; scanner interface
IDCID_TABLET		EQU	34	; drawing tablet interface
IDCID_RAM		EQU	35	; plain RAM expansion
IDCID_FLASHROM		EQU	36	; Flash ROM
IDCID_SCSIIDE		EQU	37	; combined SCSI/IDE controller
IDCID_RAMFPU		EQU	38	; RAM expansion + FPU
IDCID_GUESS		EQU	39	; name was unknown but guessed
IDCID_KICKSTART		EQU	40	; KickStart
IDCID_RAM32		EQU	41	; 32bit RAM expansion
IDCID_TURBOANDRAM	EQU	42	; accelerator + RAM expansion
IDCID_ACCESS		EQU	43	; access control
IDCID_INTERFACE		EQU	44	; some interface
IDCID_MFMHD		EQU	45	; MFM HD controller
IDCID_FLOPPY		EQU	46	; floppy disk controller
IDCID_USB		EQU	47	; USB interface
	; Be prepared to get other numbers as well. In this case you
	; should assume IDCID_MISC.

*
* Error codes
*
				;Positive error codes are DOS errors!
IDERR_OKAY	EQU	0	;No error
IDERR_NOLENGTH	EQU	-1	;Buffer length is 0 ??
IDERR_BADID	EQU	-2	;Missing or bad board ID
IDERR_NOMEM	EQU	-3	;Not enough memory
IDERR_NOFD	EQU	-4	;No fitting FD file found
IDERR_OFFSET	EQU	-5	;Function offset not found
IDERR_DONE	EQU	-6	;Done with traversing (not an error)
IDERR_SECONDARY EQU	-7	;Secondary expansion board (not an error)

	ENDC
