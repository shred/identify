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

#ifndef _INLINE_IDENTIFY_H
#define _INLINE_IDENTIFY_H

#include <sys/cdefs.h>
#include <inline/stubs.h>

__BEGIN_DECLS

#ifndef BASE_EXT_DECL
#define BASE_EXT_DECL
#define BASE_EXT_DECL0 extern struct Library * IdentifyBase;
#endif
#ifndef BASE_PAR_DECL
#define BASE_PAR_DECL
#define BASE_PAR_DECL0 void
#endif
#ifndef BASE_NAME
#define BASE_NAME IdentifyBase
#endif

BASE_EXT_DECL0

static __inline LONG
IdAlert (BASE_PAR_DECL ULONG code, struct TagItem *taglist)
{
  BASE_EXT_DECL
  register LONG _res __asm("d0");
  register struct Library *a6 __asm("a6") = BASE_NAME;
  register ULONG d0 __asm("d0") = code;
  register struct TagItem * a0 __asm("a0") = taglist;
  __asm __volatile ("jsr a6@(-42)"
  : "=r" (_res)
  : "r" (a6), "r" (a0), "r" (d0)
  : "a0","a1","d0","d1", "memory");
  return _res;
}
#ifndef NO_INLINE_STDARG
#define IdAlertTags(d0, tags...) \
  ({ struct TagItem _tags[] = { tags }; IdAlert ((d0), _tags); })
#endif /* not NO_INLINE_STDARG */

static __inline LONG
IdExpansion (BASE_PAR_DECL struct TagItem *taglist)
{
  BASE_EXT_DECL
  register LONG _res __asm("d0");
  register struct Library *a6 __asm("a6") = BASE_NAME;
  register struct TagItem * a0 __asm("a0") = taglist;
  __asm __volatile ("jsr a6@(-30)"
  : "=r" (_res)
  : "r" (a6), "r" (a0), "r" (d0)
  : "a0","a1","d0","d1", "memory");
  return _res;
}
#ifndef NO_INLINE_STDARG
#define IdExpansionTags(tags...) \
  ({ struct TagItem _tags[] = { tags }; IdExpansion (_tags); })
#endif /* not NO_INLINE_STDARG */

static __inline STRPTR
IdHardware (BASE_PAR_DECL ULONG type, struct TagItem *taglist)
{
  BASE_EXT_DECL
  register STRPTR _res __asm("d0");
  register struct Library *a6 __asm("a6") = BASE_NAME;
  register ULONG d0 __asm("d0") = type;
  register struct TagItem * a0 __asm("a0") = taglist;
  __asm __volatile ("jsr a6@(-36)"
  : "=r" (_res)
  : "r" (a6), "r" (a0), "r" (d0)
  : "a0","a1","d0","d1", "memory");
  return _res;
}
#ifndef NO_INLINE_STDARG
#define IdHardwareTags(d0, tags...) \
  ({ struct TagItem _tags[] = { tags }; IdHardware ((d0), _tags); })
#endif /* not NO_INLINE_STDARG */

static __inline LONG
IdFunction (BASE_PAR_DECL STRPTR name, LONG offset, struct TagItem *taglist)
{
  BASE_EXT_DECL
  register LONG _res __asm("d0");
  register struct Library *a6 __asm("a6") = BASE_NAME;
  register STRPTR a0 __asm("a0") = name;
  register LONG d0 __asm("d0") = offset;
  register struct TagItem * a1 __asm("a1") = taglist;
  __asm __volatile ("jsr a6@(-48)"
  : "=r" (_res)
  : "r" (a6), "r" (a0), "r" (d0)
  : "a0","a1","d0","d1", "memory");
  return _res;
}
#ifndef NO_INLINE_STDARG
#define IdFunctionTags(a0, d0, tags...) \
  ({ struct TagItem _tags[] = { tags }; IdFunction ((a0), (d0), _tags); })
#endif /* not NO_INLINE_STDARG */

static __inline ULONG
IdHardwareNum (BASE_PAR_DECL ULONG type, struct TagItem *taglist)
{
  BASE_EXT_DECL
  register ULONG _res __asm("d0");
  register struct Library *a6 __asm("a6") = BASE_NAME;
  register ULONG d0 __asm("d0") = type;
  register struct TagItem * a0 __asm("a0") = taglist;
  __asm __volatile ("jsr a6@(-54)"
  : "=r" (_res)
  : "r" (a6), "r" (a0), "r" (d0)
  : "a0","a1","d0","d1", "memory");
  return _res;
}
#ifndef NO_INLINE_STDARG
#define IdHardwareNumTags(d0, tags...) \
  ({ struct TagItem _tags[] = { tags }; IdHardwareNum ((d0), _tags); })
#endif /* not NO_INLINE_STDARG */

static __inline void
IdHardwareUpdate (void)
{
  BASE_EXT_DECL
  register struct Library *a6 __asm("a6") = BASE_NAME;
  __asm __volatile ("jsr a6@(-60)"
  : "r" (a6)
  : "memory");
}

static __inline ULONG
IdFormatString (BASE_PAR_DECL STRPTR string, STRPTR buffer, ULONG length, struct TagItem *taglist)
{
  BASE_EXT_DECL
  register ULONG _res __asm("d0");
  register struct Library *a6 __asm("a6") = BASE_NAME;
  register STRPTR a0 __asm("a0") = string;
  register STRPTR a1 __asm("a1") = buffer;
  register ULONG d0 __asm("d0") = length;
  register struct TagItem * a1 __asm("a2") = taglist;
  __asm __volatile ("jsr a6@(-66)"
  : "=r" (_res)
  : "r" (a6), "r" (a0), "r" (d0)
  : "a0","a1","d0","d1", "memory");
  return _res;
}
#ifndef NO_INLINE_STDARG
#define IdFormatStringTags(a0, a1, d0, tags...) \
  ({ struct TagItem _tags[] = { tags }; IdFormatString ((a0), (a1), (d0), _tags); })
#endif /* not NO_INLINE_STDARG */

static __inline ULONG
IdEstimateFormatSize (BASE_PAR_DECL STRPTR string, struct TagItem *taglist)
{
  BASE_EXT_DECL
  register ULONG _res __asm("d0");
  register struct Library *a6 __asm("a6") = BASE_NAME;
  register STRPTR a0 __asm("a0") = string;
  register struct TagItem * a1 __asm("a1") = taglist;
  __asm __volatile ("jsr a6@(-72)"
  : "=r" (_res)
  : "r" (a6), "r" (a0), "r" (d0)
  : "a0","a1","d0","d1", "memory");
  return _res;
}
#ifndef NO_INLINE_STDARG
#define IdEstimateFormatSizeTags(a0, tags...) \
  ({ struct TagItem _tags[] = { tags }; IdEstimateFormatSize ((a0), _tags); })
#endif /* not NO_INLINE_STDARG */


#undef BASE_EXT_DECL
#undef BASE_EXT_DECL0
#undef BASE_PAR_DECL
#undef BASE_PAR_DECL0
#undef BASE_NAME

__END_DECLS

#endif /* _INLINE_IDENTIFY_H */
