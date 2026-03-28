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

// MULLE__NANOVG_GL_GLOBAL may not be defined yet if nanovg_gl.h hasn't been included
#ifndef MULLE__NANOVG_GL_GLOBAL
# ifdef MULLE__NANOVG_GL_BUILD
#  if defined( _WIN32)
#   define MULLE__NANOVG_GL_GLOBAL    extern __declspec( dllexport)
#  else
#   define MULLE__NANOVG_GL_GLOBAL    extern
#  endif
# else
#  if defined( _WIN32) && !defined( MULLE__NANOVG_GL_INCLUDE_STATIC)
#   define MULLE__NANOVG_GL_GLOBAL    extern __declspec( dllimport)
#  else
#   define MULLE__NANOVG_GL_GLOBAL    extern
#  endif
# endif
#endif


#import "CGLayoutContext+nanovg.h"

// nanovg backend vtable instances
MULLE_CG_NANOVG_GLOBAL CGFunctionTable          CGNanoVGFunctionTable;
// defined in MulleCGNanovgGL, not MulleCGNanovg
MULLE__NANOVG_GL_GLOBAL CGBackendFunctionTable   CGNanoVGBackendFunctionTable;


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


@interface CGContext( nanovg)

- (instancetype) _initAsPathContext;
- (void) _setNVGContext:(NVGcontext *) nvg
         functionTable:(CGFunctionTable *) functions
  backendFunctionTable:(CGBackendFunctionTable *) backendFunctions;

+ (CGContextNanoVGBackend) nanoVGBackend;
+ (char *) nanoVGBackendUTF8String;

- (char *) nanovgInfoUTF8String;

@end



@interface CGContextBase( nanovg)

+ (CGContext *) createPathContext;

@end


@interface CGLayoutContext ( OpenGL)

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


#endif /* CGContext_nanovg_h__ */
