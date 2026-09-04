//
//  CGContext+nanovg.h
//  MulleCGNanovg
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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

+ (CGContext *) pathContext;

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

