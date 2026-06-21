//
// Copyright (c) <|YEAR|> Nat!, Mulle kybernetiK
//
// we want "import.h" always anyway
#import "import.h"

// forward declare NVGcontext so we don't pull in nanovg.h publicly
typedef struct NVGcontext NVGcontext;


#import "CGLayoutContext+nanovg.h"

// nanovg backend vtable instances
MULLE_CG_NANOVG_GLOBAL
CGFunctionTable          CGNanoVGFunctionTable;

MULLE_CG_NANOVG_GLOBAL
CGFontFunctionTable      CGNanoVGFontFunctionTable;


//
// NVGcontext accessors — only available in MulleCGNanovg, not in MulleCG
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


// provided by +nanovg-gl
@interface CGContext( nanovgFuture) < MulleObjCFuture>

- (instancetype) _initAsPathContext;
+ (CGContextNanoVGBackend) nanoVGBackend;
+ (char *) nanoVGBackendUTF8String;
- (char *) nanovgInfoUTF8String;

@end


@interface CGContext( nanovg)

- (void) _setNVGContext:(NVGcontext *) nvg
         functionTable:(CGFunctionTable *) functions
  backendFunctionTable:(CGBackendFunctionTable *) backendFunctions;

@end


// provided by +nanovg-gl
@interface CGContextBase( nanovgFuture) < MulleObjCFuture>

+ (CGContext *) createPathContext;

@end


@interface CGContext( Errors)

// this is here because nanovg sets the OpenGL version
- (void) assertNoBackendError:(char *) str;

@end


@interface CGContext( BackendErrors)

- (void) _checkBackendError:(char *) str;
- (BOOL) resetBackendError;

@end


static inline void   CGContextCheckBackendError( CGContext *ctxt, char *str)
{
#ifdef DEBUG
   [ctxt _checkBackendError:str];
#endif
}

static inline BOOL   CGContextResetBackendError( CGContext *ctxt)
{
   return( [ctxt resetBackendError]);
}

