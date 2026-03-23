//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#ifndef CGLayoutContext_nanovg_h__
#define CGLayoutContext_nanovg_h__
#ifdef __has_include
# if __has_include( "CGLayoutContext.h")
#  import "CGLayoutContext.h"
# endif
#endif

#import "import.h"

@interface CGLayoutContext( nanovg)

- (instancetype) initWithOSGraphicsContext:(id <UIOSGraphicsContext>) context
                            nameUTF8String:(char *) nameUTF8String;
@end


//
// use these functions, during rendering where we assume _cgBackend.context is not
// suddenly changed by someone
//
MULLE_C_CONST_RETURN
static inline struct NVGcontext   *CGLayoutContextGetNVGContext( CGLayoutContext *self)
{
   if( ! self)
      return( NULL);
   return( (struct NVGcontext *) ((struct{ @defs( CGLayoutContext); } *) self)->_cgBackend.context);
}


MULLE_C_CONST_RETURN
static inline struct NVGcontext   *_CGLayoutContextGetNVGContext( CGLayoutContext *self)
{
   return( (struct NVGcontext *) ((struct{ @defs( CGLayoutContext); } *) self)->_cgBackend.context);
}


#endif /* CGLayoutContext_nanovg_h__ */
