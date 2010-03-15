/*
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
 */

/*
 * Hunk compression and encryption tool
 */

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>
#include <clib/powerpacker_protos.h>
#include <pragmas/exec_pragmas.h>
#include <pragmas/dos_pragmas.h>
#include <pragmas/powerpacker_pragmas.h>
#include <exec/memory.h>
#include <dos/stdio.h>
#include <dos/dos.h>
#include <dos/rdargs.h>
#include <libraries/ppbase.h>

extern struct Library *DOSBase;
struct Library *PPBase;

ULONG eff = CRUN_VERYGOOD;
ULONG efftab[] = {~0x09090909, ~0x090A0A0A, ~0x090A0B0B, ~0x090A0C0C, ~0x090A0C0D};

ULONG Compress(APTR data, ULONG len)
{
  APTR crunchinfo;
  ULONG newlen;

  crunchinfo = ppAllocCrunchInfo(eff,SPEEDUP_BUFFMEDIUM,NULL,NULL);
  if(crunchinfo)
  {
    newlen = ppCrunchBuffer(crunchinfo,data,len);
    if(newlen != PP_BUFFEROVERFLOW)
    {
      UBYTE *buf = (UBYTE *)data;
      ppFreeCrunchInfo(crunchinfo);

      buf[newlen-4] ^= 0xFF;
      buf[newlen-3] ^= 0xFF;
      buf[newlen-2] ^= 0xFF;
      buf[newlen-1] ^= 0xFF;

      return(newlen);
    }
    ppFreeCrunchInfo(crunchinfo);
  }
  return(0);
}

#define getw(x) ((block[x]<<8)+block[x+1])
#define getl(x) ((((((block[x]<<8)+block[x+1])<<8)+block[x+2])<<8)+block[x+3])

ULONG Encrypt(STRPTR name, UBYTE *block, ULONG length)
{
  ULONG index = 0, dataindex = 0;
  ULONG hunk, datalen, newlen, numhunk;
  UBYTE *datahunk;
  BPTR fh;
  UWORD number, datanow = 0;

  //-- Daten-Hunk suchen --//
  if(getl(0)==0x03F3)
  {
    numhunk = getl(8);
    index = (numhunk<<2) + 0x14;
    while(numhunk)
    {
      hunk = getl(index);
      switch(hunk)
      {
        case 0x03EA:                            // DATA !!!
          if(dataindex == 0)                    // Ersten Hunk merken
          {
            dataindex = index;
            datahunk = &block[index+8];
            datalen = getl(index+4)<<2;
            datanow = 1;                        // wir sind im Data-hunk
          }
          index += (getl(index+4)<<2) + 8;
          break;

        case 0x03E9:                            // CODE
          index += (getl(index+4)<<2) + 8;
          break;

        case 0x03F7:                            // DREL32
          if(datanow)                           // Oha, nicht im Data-hunk!!!
          {
            Printf("Data-Hunk darf nicht reloziert werden!\n");
            return(0);
          }
          index += 4;
          while(number = getw(index))
            index += (number<<1)+4;
          index += 2;
          if(index%4) index += 2;               // Durch 4 teilbar!
          break;

        case 0x03F2:                            // END
          index += 4;
          numhunk--;
          datanow = 0;                          // Chunk beendet
          break;

        default:                                // Alles andere
          Printf("Unbekannter Hunk %04lx\n",hunk);
          return(0);
      }
    }
  }
  else
  {
    Printf("Keine Executeable\n");
    return(0);
  }

  if(dataindex == 0)
  {
    Printf("Kein Data-Hunk gefunden\n");
    return(0);
  }

  //-- Komprimieren --//
  newlen = Compress(datahunk+16,datalen-16);
  if(newlen == 0)
  {
    Printf("Kompression nicht möglich! (Bereits komprimiert?)\n");
    return(0);
  }

  //-- Abspeichern --//
  if(fh = Open(name,MODE_NEWFILE))
  {
    UBYTE *dataend = datahunk + datalen;
    UBYTE *blockend = block + length;
    ULONG calc = (newlen+11)>>2;        //+4 für Länge +4 für Effizienz +3 für Rundung
    ULONG lencalc = newlen+8;           //+4 für Länge +4 für Effizienz

    Write(fh,block,dataindex+4);        // Bis zum Data-Hunk
    Write(fh,&calc,4);                  // Die neue Länge
    Write(fh,&lencalc,4);               // Ausgeschrieben für PowerPacker
    Write(fh,&efftab[eff],4);           // Effizienzcode für PowerPacker
    Write(fh,datahunk+16,(calc<<2)-8);  // Die Datei
    Write(fh,dataend,blockend-dataend); // Der Rest
    Close(fh);
  }

  return(length-(datalen-(((newlen+11)>>2)<<2)));
}

ULONG FileLen(STRPTR name)
{
  BPTR lock;
  struct FileInfoBlock *fib;
  ULONG length = 0;

  fib = AllocMem(sizeof(struct FileInfoBlock),MEMF_PUBLIC);
  if(fib)
  {
    lock = Lock(name,ACCESS_READ);
    if(lock)
    {
      if(Examine(lock,fib)) length = fib->fib_Size;
      UnLock(lock);
    }
    FreeMem(fib,sizeof(struct FileInfoBlock));
  }
  return(length);
}

APTR LoadFile(STRPTR name, ULONG length)
{
  APTR block;
  BPTR fh;

  block = AllocVec(length,MEMF_PUBLIC);
  if(block)
  {
    if(fh = Open(name,MODE_OLDFILE))
    {
      if(Read(fh,block,length) >= 0)
      {
        Close(fh);
        return(block);
      }
      Close(fh);
    }
    FreeVec(block);
  }
  return(NULL);
}

int main(int argc, char **argv)
{
  ULONG length;
  APTR block;
  struct RDArgs *args;
  static char template[] = "FILE/A,AS/K,E=EFFICIENCY/K/N";
  struct Parameter
  {
    STRPTR file;
    STRPTR as;
    LONG *eff;
  }param = {NULL};

  PPBase  = OpenLibrary("powerpacker.library",35);
  if(PPBase)
  {
    if(args = (struct RDArgs *)ReadArgs(template,(LONG *)&param,NULL))
    {
      if(param.eff && (*param.eff>=CRUN_FAST || *param.eff<=CRUN_BEST))
      {
        eff = *param.eff;
        Printf("Effizienz = %ld (0:FAST 4:BEST)\n",*param.eff);
      }

      length = FileLen(param.file);
      Printf("Encrypte Datei '%s' (%ld Bytes)\n",param.file,length);
      if(length)
      {
        block = LoadFile(param.file,length);
        if(block)
        {
          length = Encrypt((param.as ? param.as : param.file),(UBYTE *)block,length);
          if(length)
          {
            Printf("Neue Länge %ld Bytes\n",length);
          }
          FreeVec(block);
        }
        FreeArgs(args);
      }
    }
    CloseLibrary(PPBase);
  }
  return(0);
}
