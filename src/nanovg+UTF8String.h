#ifndef nanovg_utf8string_h__
#define nanovg_utf8string_h__

#include "include.h"

#include "CGAffineTransform+nanovg.h"

#ifdef __has_include
# if __has_include( <MulleUIBase/CGAffineTransform+UTF8String.h>)
#  include <MulleUIBase/CGAffineTransform+UTF8String.h>
# endif
#endif


char   *NVGscissorUTF8String( _NVGtransform value);

static inline char   *_NVGtransformUTF8String( _NVGtransform xform)
{
   return( CGAffineTransformUTF8String( _NVGtransformAsCGAffineTransform( xform)));
}

#endif
