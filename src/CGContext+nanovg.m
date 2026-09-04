//
//  CGContext+nanovg.m
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
#import "import-private.h"

#import "CGContext+nanovg.h"
#import "CGContext+GPUFuture.h"

#import <MulleCG/CGContext+DebugPrivate.h>
#include "nanowrap-private.h"

#include <ctype.h>


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"


@implementation CGContext ( nanovg)

- (void) _setNVGContext:(NVGcontext *) nvg
         functionTable:(CGFunctionTable *) functions
  backendFunctionTable:(CGBackendFunctionTable *) backendFunctions
{
   _cgBackend.context             = nvg;
   if( functions)
      _cgBackend.functions        = *functions;
   if( backendFunctions)
      _cgBackend.backendFunctions = *backendFunctions;
}


- (void) _initGraphicsBackend
{
   if( ! _cgBackend.context && _backend != UIGraphicsBackendNone)
   {
#ifdef DEBUG
      _cgBackend.flags |= NVG_DEBUG;
#endif
      [self _initNanovg];
   }

   _cgBackend.functions = CGNanoVGFunctionTable;

   // _initFontBackend is called by CGLayoutContext after super init
}


// flushes drawings doesn't reset glViewport or reset internal caches
- (void) flushRender
{
   assert( CGContextIsActiveInCurrentThread( self));

   CGContextRenderLog( "");

   // if there are no draw commands, this does nothing
   nvgFlushFrame( _cgBackend.context);
}


- (void) suspendRender
{
   assert( CGContextIsActiveInCurrentThread( self));

   CGContextRenderLog( "");
   CGContextCheckBackendError( self, "before nvgEndFrame");

   nvgEndFrame( _cgBackend.context);

   CGContextCheckBackendError( self, "nvgEndFrame");
}


- (void) changeRender:(struct CGFrameInfo *) info
{
   assert( CGContextIsActiveInCurrentThread( self));
   assert( info);

   CGContextRenderLog( "%s", CGFrameInfoUTF8String( info));
   _currentFrameInfo = *info;
   // wasn't initialized before so ignore
   if( _currentFrameInfo.window.pixelRatio == 0.0)
      return;

   assert( _isRendering);

   CGContextCheckBackendError( self, "before nvgChangeFrame");

   nvgChangeFrame( _cgBackend.context, _currentFrameInfo.window.frame.size.width,
                        _currentFrameInfo.window.frame.size.height,
                        _currentFrameInfo.window.pixelRatio);
   CGContextCheckBackendError( self, "nvgChangeFrame");

   [self _changeRenderGPU:&_currentFrameInfo];
}


- (void) resumeRender
{
   CGFloat   width;
   CGFloat   height;

   assert( _isRendering);

   CGContextRenderLog( "");

   CGContextCheckBackendError( self, "before resumeRender");

   if( _viewport.size.width == -1)
   {
      [self _changeRenderGPU:&_currentFrameInfo];
      width  = _currentFrameInfo.window.frame.size.width;
      height = _currentFrameInfo.window.frame.size.height;
   }
   else
   {
      [self setViewport:_viewport];
      width  = (CGFloat) _viewport.size.width / _currentFrameInfo.window.pixelRatio;
      height = (CGFloat) _viewport.size.height / _currentFrameInfo.window.pixelRatio;
   }

   nvgBeginFrame( _cgBackend.context, width, height,
                       _currentFrameInfo.window.pixelRatio);
   CGContextCheckBackendError( self, "nvgBeginFrame");
}


- (void) reset
{
   nvgReset( _cgBackend.context);
}


- (FILE *) setTraceFile:(FILE *) file
{
   return( nvgTrace( (struct NVGcontext *) _cgBackend.context, file));
}

@end

#pragma clang diagnostic pop
