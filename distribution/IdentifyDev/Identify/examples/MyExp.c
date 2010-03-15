/*********************************************************************
**                                                                  **
**                         M Y E X P                                **
**                                                                  **
** A small example for using the identify.library.                  **
** Compiles with any C compiler.                                    **
**                                                                  **
*********************************************************************/
/*
**        (C) 1997 by Richard Körber -- All Rights Reserved
*/

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>
#include <clib/identify_protos.h>
#include <pragmas/exec_pragmas.h>
#include <pragmas/dos_pragmas.h>
#include <pragmas/identify_pragmas.h>
#include <exec/memory.h>
#include <libraries/identify.h>
#include <libraries/configregs.h>
#include <libraries/configvars.h>

struct Library *IdentifyBase;
extern struct Library *DOSBase;

/*------------------------------------------------------------------**
**  main                  -- MAIN PART
*/
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
  return 0;                             // return code 0
}

/********************************************************************/

