/*
 * identify.library
 *
 * Copyright (C) 2021 Frank Wille
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
 */

#include <proto/exec.h>
#include <exec/libraries.h>

/* #include <powerpc/powerpc.h> */
/* This include should be used here, but it contains some bugs. So... */
struct PPCArgs {
        APTR  PP_Code;
        LONG  PP_Offset;
        ULONG PP_Flags;
        APTR  PP_Stack;
        ULONG PP_StackSize;
        ULONG PP_Regs[15];
        DOUBLE PP_FRegs[8];
};
#define PPERR_SUCCESS  0


/* inline code for RunPPC */
LONG __RunPPC(__reg("a0")struct PPCArgs *,__reg("a6")void *)="\tjsr\t-30(a6)";
#define RunPPC(x) __RunPPC((x),PowerPCBase)


static struct PPCArgs ppcargs;

extern APTR ppc_getinfo;  /* PPC function to call */


int PPC_CPU_Clock()
{
  struct Library *PowerPCBase;
  int rc = 0;

  if (PowerPCBase = OpenLibrary("powerpc.library",10)) {
    ppcargs.PP_Code = &ppc_getinfo;
    ppcargs.PP_Regs[13] = (ULONG)&ppc_getinfo; /* base addr. in r30 */
    ppcargs.PP_Regs[14] = (ULONG)PowerPCBase;  /* lib base in r31 */
    if (RunPPC(&ppcargs) == PPERR_SUCCESS)
      rc = (int)ppcargs.PP_Regs[0];  /* result from r3 */
    CloseLibrary(PowerPCBase);
  }
  return (rc);
}
