//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//

#import "import.h"

@interface CGLayoutContext( nanovg)

- (void) _initFontBackend;
- (void) _doneFontBackend;

@end


@interface CGLayoutContext( nanovgFuture)

- (void) _initNanovg;
- (void) _doneNanovg;

@end

//
// use these functions, during rendering where we assume _fontContext is not
// suddenly changed by someone
//
MULLE_C_CONST_RETURN
static inline struct NVGcontext   *CGLayoutContextGetNVGContext( CGLayoutContext *self)
{
   if( ! self)
      return( NULL);
   return( (struct NVGcontext *) ((struct{ @defs( CGLayoutContext); } *) self)->_fontContext);
}


MULLE_C_CONST_RETURN
static inline struct NVGcontext   *_CGLayoutContextGetNVGContext( CGLayoutContext *self)
{
   return( (struct NVGcontext *) ((struct{ @defs( CGLayoutContext); } *) self)->_fontContext);
}


