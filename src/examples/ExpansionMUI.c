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

#include <stdio.h>
#include <string.h>
#include <clib/alib_protos.h>
#include <exec/memory.h>
#include <libraries/identify.h>
#include <libraries/mui.h>
#include <libraries/configregs.h>
#include <libraries/configvars.h>
#include <proto/exec.h>
#include <proto/expansion.h>
#include <proto/identify.h>
#include <proto/muimaster.h>

#define MAKE_ID(a,b,c,d)        \
        ((ULONG) (a)<<24 | (ULONG) (b)<<16 | (ULONG) (c)<<8 | (ULONG) (d))

struct Library *MUIMasterBase;
struct Library *IdentifyBase;

static __saveds APTR ConstructFunc(
  __reg("a1") struct ConfigDev *cd
)
{
  struct ConfigDev *newcd;

  newcd = AllocVec(sizeof(struct ConfigDev),MEMF_PUBLIC);
  if(newcd)
    CopyMem(cd,newcd,sizeof(struct ConfigDev));
  return(newcd);
}

static __saveds LONG DisplayFunc(
  __reg("a2") char **array,
  __reg("a1") struct ConfigDev *cd
)
{
  static char buf_nr[5];
  static char buf_address[12];
  static char buf_size[6];
  static char buf_id[10];
  static char buf_manuf[IDENTIFYBUFLEN];
  static char buf_product[IDENTIFYBUFLEN];
  static char buf_class[IDENTIFYBUFLEN];

  if(cd)
  {
    ULONG size = cd->cd_BoardSize>>10;
    ULONG unit = 'K';

    if(size>=1024)
    {
      unit = 'M';
      size >>= 10;
    }

    sprintf(buf_nr,"%ld",array[-1]+1);                // Get the entry number
    sprintf(buf_address,"%08lx",cd->cd_BoardAddr);    // board address
    sprintf(buf_size,"%3ld%lc",size,unit);            // board size
    sprintf(buf_id,"%04lx:%02lx",cd->cd_Rom.er_Manufacturer,cd->cd_Rom.er_Product);

    IdExpansionTags(                      // Identify the expansion board
      IDTAG_ConfigDev, cd,
      IDTAG_ManufStr , buf_manuf,
      IDTAG_ProdStr  , buf_product,
      IDTAG_ClassStr , buf_class,
      TAG_DONE
    );

    *array++ = buf_nr;
    *array++ = buf_address;
    *array++ = buf_size;
    *array++ = buf_id;
    *array++ = buf_manuf;
    *array++ = buf_product;
    *array   = buf_class;
  }
  else                                      // Show the title line
  {
    *array++ = "\33b\33cNr.";
    *array++ = "\33b\33cAddress";
    *array++ = "\33b\33cSize";
    *array++ = "\33b\33cID";
    *array++ = "\33b\33cManufacturer";
    *array++ = "\33b\33cProduct";
    *array   = "\33b\33cClass";
  }
  return(0);
}

static __saveds void DestructFunc(
  __reg("a1") struct ConfigDev *cd
)
{
  if(cd) FreeVec(cd);
}

int main(void)
{
  ULONG sigs=0;                         // Signal bits
  const struct Hook ConstructHook = {{NULL,NULL},(void *)ConstructFunc,NULL,NULL};
  const struct Hook DisplayHook   = {{NULL,NULL},(void *)DisplayFunc  ,NULL,NULL};
  const struct Hook DestructHook  = {{NULL,NULL},(void *)DestructFunc ,NULL,NULL};
  Object *app;                          // Application object
  Object *window;                       // Window object
  Object *LV_explist;                   // Expansion listview object
  struct ConfigDev *cd = NULL;          // ConfigDev traverse pointer

  if(IdentifyBase = OpenLibrary("identify.library",5))
  {
    if(MUIMasterBase = OpenLibrary("muimaster.library",11))
    {
      app = ApplicationObject,            // Create the application
        MUIA_Application_Title        , "Expansions",
        MUIA_Application_Version      , "$VER: Expansions V1.2 (20.11.2021)",
        MUIA_Application_Copyright    , "\xA9 1997-2021 by Richard 'Shred' K\xF6rber",
        MUIA_Application_Author       , "Richard K\xF6rber",
        MUIA_Application_Description  , "A small identify.library example",
        MUIA_Application_Base         , "EXPANSIONS",
        MUIA_Application_Window       , window = WindowObject,
          MUIA_Window_Title           , "Expansions Demo",
          MUIA_Window_ID              , MAKE_ID('E','X','P','D'),
          WindowContents, VGroup,
            Child, TextObject,
              MUIA_Frame        , MUIV_Frame_Text,
              MUIA_Background   , MUII_TextBack,
              MUIA_Text_Contents, "\33cA small example how to use\nidentify.library with MUI.",
            End,
            Child, LV_explist = ListviewObject,
              MUIA_Listview_Input , FALSE,
              MUIA_Listview_List  , ListObject,
                MUIA_Frame              , MUIV_Frame_ReadList,
                MUIA_List_ConstructHook , &ConstructHook,
                MUIA_List_DisplayHook   , &DisplayHook,
                MUIA_List_DestructHook  , &DestructHook,
                MUIA_List_Title         , TRUE,
                MUIA_List_Format        , "P=\33r BAR,,P=\33r,BAR,D=6,P=\33c D=6,P=\33r",
              End,
            End,
            Child, TextObject,
              MUIA_Frame        , MUIV_Frame_Text,
              MUIA_Background   , MUII_TextBack,
              MUIA_Text_Contents, "\33cFor unknown boards, please open an issue\nat https://identify.shredzone.org. Thank you!",
            End,
          End,
        End,
      End;

      if(app)
      {
        // Close gadget notification
        DoMethod(window,MUIM_Notify,MUIA_Window_CloseRequest,TRUE,
                  app,2,MUIM_Application_ReturnID,MUIV_Application_ReturnID_Quit);

        // Fill the expansion list
        set(LV_explist,MUIA_List_Quiet,TRUE);   // Do a quick update
        while(cd = FindConfigDev(cd,-1,-1))
        {
          DoMethod(LV_explist,MUIM_List_InsertSingle,cd,MUIV_List_Insert_Bottom);
        }
        set(LV_explist,MUIA_List_Quiet,FALSE);  // Now, display the list

        set(window,MUIA_Window_Open,TRUE);

        // Main Loop
        while(DoMethod(app,MUIM_Application_NewInput,&sigs) != MUIV_Application_ReturnID_Quit)
        {
          if(sigs)                        // Wait for MUI signals to occur
          {
            sigs = Wait(sigs | SIGBREAKF_CTRL_C);
            if(sigs & SIGBREAKF_CTRL_C) break;    // Aborted
          }
        }
        MUI_DisposeObject(app);           // dispose the application
      }
      CloseLibrary(MUIMasterBase);
    }
    CloseLibrary(IdentifyBase);
  }
  return 0;                             // return code 0
}
