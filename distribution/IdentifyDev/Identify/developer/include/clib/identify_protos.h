#ifndef  CLIB_IDENTIFY_PROTOS_H
#define  CLIB_IDENTIFY_PROTOS_H

/*
** identify.library
**
** Copyright (C) 2010 Richard "Shred" Körber
**   http://identify.shredzone.org
**
** This program is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License / GNU Lesser
** General Public License as published by the Free Software Foundation,
** either version 3 of the License, or (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/
LONG IdAlert(ULONG, struct TagItem *);
LONG IdAlertTags(ULONG, ULONG,...);
ULONG IdEstimateFormatSize(STRPTR, struct TagItem *);
ULONG IdEstimateFormatSizeTags(STRPTR, ULONG,...);
LONG IdExpansion(struct TagItem *);
LONG IdExpansionTags(ULONG,...);
ULONG IdFormatString(STRPTR, STRPTR, ULONG, struct TagItem *);
ULONG IdFormatStringTags(STRPTR, STRPTR, ULONG, ...);
LONG IdFunction(STRPTR, LONG, struct TagItem *);
LONG IdFunctionTags(STRPTR, LONG, ULONG,...);
STRPTR IdHardware(ULONG, struct TagItem *);
STRPTR IdHardwareTags(ULONG, ULONG,...);
ULONG IdHardwareNum(ULONG, struct TagItem *);
ULONG IdHardwareNumTags(ULONG, ULONG,...);
void IdHardwareUpdate(void);

#endif
