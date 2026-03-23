//
// CGColor <-> NVGcolor zero-cost conversion.
// Used only inside nanovg-specific/ — never exposed in public headers.
//
// Both structs are layout-identical: union { float rgba[4]; struct { float r,g,b,a; }; }
//
#ifndef CGColor_NVGcolor_h__
#define CGColor_NVGcolor_h__

#include <string.h>

static inline NVGcolor   CGColorToNVGColor( CGColor c)
{
   NVGcolor   result;
   memcpy( &result, &c, sizeof( result));
   return( result);
}

static inline CGColor   NVGColorToCGColor( NVGcolor c)
{
   CGColor   result;
   memcpy( &result, &c, sizeof( result));
   return( result);
}

#endif
