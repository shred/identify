/*
 * identify.library
 *
 * Copyright (C) 2021 Richard "Shred" Koerber
 *        http://identify.shredzone.org
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
 */

#include <exec/memory.h>
#include <libraries/identify.h>
#include <libraries/configregs.h>
#include <libraries/configvars.h>
#include <proto/exec.h>
#include <proto/dos.h>
#include <proto/identify.h>

struct Library *IdentifyBase;

int main(void)
{
  if(IdentifyBase = OpenLibrary("identify.library",6))
  {
    struct ConfigDev *expans = NULL;
    UWORD counter = 0;
    ULONG size;
    ULONG unit;
    char manuf[IDENTIFYBUFLEN];
    char prod[IDENTIFYBUFLEN];
    char pclass[IDENTIFYBUFLEN];

    Printf("Nr Address  Size Description\n"
           "----------------------------------------------------------\n");

    while(!IdExpansionTags(
            IDTAG_ManufStr ,&manuf,
            IDTAG_ProdStr  ,&prod,
            IDTAG_ClassStr ,&pclass,
            IDTAG_Expansion,&expans,
            TAG_DONE))
    {
      unit = 'K';
      size = expans->cd_BoardSize>>10;
      if(size>=1024)
      {
        unit = 'M';
        size >>= 10;
      }

      Printf("%2ld %08lx %3ld%lc %s %s (%s)\n",
             ++counter,
             expans->cd_BoardAddr, size, unit,
             prod, pclass, manuf);
    }
    CloseLibrary(IdentifyBase);
  }
  return 0;
}
