//
// Copyright (c) <|YEAR|> Nat!, Mulle kybernetiK
//
#ifndef CGContext_nanovg_h__
#define CGContext_nanovg_h__

// prefer a local CGContext over one in import.h
#ifdef __has_include
# if __has_include( "CGContext.h")
#  import "CGContext.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"

#include <MulleCG/include.h>

// forward declare NVGcontext so we don't pull in nanovg.h publicly
typedef struct NVGcontext NVGcontext;


#import "CGLayoutContext+nanovg.h"

// nanovg backend vtable instances
extern CGFunctionTable          CGNanoVGFunctionTable;
extern CGBackendFunctionTable   CGNanoVGBackendFunctionTable;


//
// NVGcontext accessors — only available in MulleCGNanoVG, not in MulleCG
//
MULLE_C_CONST_RETURN
static inline struct NVGcontext   *CGContextGetNVGContext( CGContextRef self)
{
   assert( CGContextIsActiveInCurrentThread( self));
   return( (struct NVGcontext *) CGContextGetBackendContext( self));
}

MULLE_C_CONST_RETURN
static inline struct NVGcontext   *_CGContextGetNVGContext( CGContextRef self)
{
   return( (struct NVGcontext *) _CGContextGetBackendContext( self));
}

MULLE_C_CONST_RETURN
static inline struct NVGcontext   *CGContextBaseGetNVGContext( CGContextBase *self)
{
   return( (struct NVGcontext *) CGContextBaseGetBackendContext( self));
}

MULLE_C_CONST_RETURN
static inline struct NVGcontext   *_CGContextBaseGetNVGContext( CGContextBase *self)
{
   return( (struct NVGcontext *) _CGContextBaseGetBackendContext( self));
}


@interface CGContext( nanovg)

+ (CGContextNanoVGBackend) nanoVGBackend;
+ (char *) nanoVGBackendUTF8String;

- (char *) nanovgInfoUTF8String;

// called by -init / -finalize
- (void) _initNanoVGWithGraphicsOptions:(UIGraphicsOptions) options;

- (char *) nanovgInfoUTF8String;


@end



@interface CGContextBase( nanovg)

+ (NVGcontext *) createPathContext;

@end


@interface CGLayoutContext ( OpenGL)

- (void) _initializeNanoVG:(NSUInteger) flags;
- (void) _finalizeNanoVG;

@end


@interface CGContext( Errors)

// this is here because nanovg sets the OpenGL version
- (void) assertNoBackendError:(char *) str;

@end


MULLE_CG_GLOBAL
void  _CGContextCheckBackendError( CGContext *ctxt, char *str);

static inline void   CGContextCheckBackendError( CGContext *ctxt, char *str)
{
#ifdef DEBUG
   _CGContextCheckBackendError( ctxt, str);
#endif
}

MULLE_CG_GLOBAL
BOOL   CGContextResetBackendError( CGContext *ctxt);

MULLE_CG_GLOBAL
char   *CGNVGBackendErrorUTF8String( void);
MULLE_CG_GLOBAL
char   *_CGNVGBackendErrorShortUTF8String( void *error);
MULLE_CG_GLOBAL
char   *_CGNVGBackendErrorUTF8String( void *error);


#endif /* CGContext_nanovg_h__ */
