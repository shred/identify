/*********************************************************************
**                                                                  **
**                    E X P A N S I O N M U I                       **
**                                                                  **
** A small example for implementing identify in MUI applications.   **
** Compiles with SAS/C. On other C compilers, some small modifica-  **
** tions will be required regarding the __asm interface. See the    **
** manual of your C compiler for further details.                   **
**                                                                  **
*********************************************************************/
/*
**        (C) 1997 by Richard Körber -- All Rights Reserved
*/

#include <clib/alib_protos.h>
#include <clib/exec_protos.h>
#include <clib/expansion_protos.h>
#include <clib/muimaster_protos.h>
#include <clib/identify_protos.h>
#include <pragmas/exec_pragmas.h>
#include <pragmas/expansion_pragmas.h>
#include <pragmas/muimaster_pragmas.h>
#include <pragmas/identify_pragmas.h>

#include <stdio.h>
#include <string.h>

#include <exec/memory.h>
#include <libraries/identify.h>
#include <libraries/mui.h>
#include <libraries/configregs.h>
#include <libraries/configvars.h>

#define MAKE_ID(a,b,c,d)        \
        ((ULONG) (a)<<24 | (ULONG) (b)<<16 | (ULONG) (c)<<8 | (ULONG) (d))

struct Library *MUIMasterBase;          // Library bases
struct Library *ExpansionBase;
struct Library *IdentifyBase;

/*------------------------------------------------------------------**
**  ConstructFunc         -- Expansion list constructor hook
*/
__saveds __asm APTR ConstructFunc
(
  register __a1 struct ConfigDev *cd
)
{
  struct ConfigDev *newcd;

  newcd = AllocVec(sizeof(struct ConfigDev),MEMF_PUBLIC);
  if(newcd)
    CopyMem(cd,newcd,sizeof(struct ConfigDev));
  return(newcd);
}

/*------------------------------------------------------------------**
**  DisplayFunc           -- Expansion list display hook
*/
__saveds __asm LONG DisplayFunc
(
  register __a2 char **array,
  register __a1 struct ConfigDev *cd
)
{
  static char buf_nr[5];
  static char buf_address[12];
  static char buf_size[6];
  static char buf_id[10];
  static char buf_manuf[IDENTIFYBUFLEN];
  static char buf_product[IDENTIFYBUFLEN];
  static char buf_class[IDENTIFYBUFLEN];

  if(cd)                                  // Show the contents
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

/*------------------------------------------------------------------**
**  DestructFunc          -- Expansion list destructor hook
*/
__saveds __asm void DestructFunc
(
  register __a1 struct ConfigDev *cd
)
{
  if(cd) FreeVec(cd);
}

/*------------------------------------------------------------------**
**  main                  -- MAIN PART
*/
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
    if(ExpansionBase = OpenLibrary("expansion.library",36))
    {
      if(MUIMasterBase = OpenLibrary("muimaster.library",11))
      {
        app = ApplicationObject,            // Create the application
          MUIA_Application_Title        , "Expansions",
          MUIA_Application_Version      , "$VER: Expansions V1.1 (16.4.97)",
          MUIA_Application_Copyright    , "© 1997 by Richard Körber",
          MUIA_Application_Author       , "Richard Körber",
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
                MUIA_Text_Contents, "\33cPlease send the description of all unknown boards\nto Richard Körber <shred@chessy.aworld.de>!",
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
      CloseLibrary(ExpansionBase);
    }
    CloseLibrary(IdentifyBase);
  }
  return 0;                             // return code 0
}

/********************************************************************/

