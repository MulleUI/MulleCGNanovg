#ifndef nanovg_utf8string_h__
#define nanovg_utf8string_h__

#import "import.h"
#include "CGAffineTransform+nanovg.h"


MULLE_CG_NANOVG_GLOBAL
char   *NVGscissorUTF8String( _NVGtransform value);

static inline char   *_NVGtransformUTF8String( _NVGtransform xform)
{
   return( CGAffineTransformUTF8String( _NVGtransformAsCGAffineTransform( xform)));
}

#endif
