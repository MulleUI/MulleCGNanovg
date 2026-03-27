//
// Copyright (c) <|YEAR|> Nat!, Mulle kybernetiK
//
#import "CGContext+nanovg.h"

#import "import-private.h"

#import <MulleCG/CGContext+DebugPrivate.h>
#import "CGContext+GPU.h"

#include "nanowrap-private.h"
#include <ctype.h>


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation CGContext ( nanovg)

- (void) _initBackend
{
   // if _cgBackend.context is clear, then we are a not a subclass so we
   // init as a real CGContext,
   if( ! _cgBackend.context)
   {
#ifdef DEBUG
      _backendFlags |= NVG_DEBUG;
#endif
      [self _initNanovg:_backendFlags];
      if( ! _cgBackend.context)
         return;  // don't create a gimped layout context if this failed
   }

   [super _initBackend]; // let CGLayoutContext do the rest
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
   assert( _isRendering);

   CGContextRenderLog( "");

   CGContextCheckBackendError( self, "before resumeRender");
   [self _changeRenderGPU:&_currentFrameInfo];

   nvgBeginFrame( _cgBackend.context, _currentFrameInfo.window.frame.size.width,
                       _currentFrameInfo.window.frame.size.height,
                       _currentFrameInfo.window.pixelRatio);
   CGContextCheckBackendError( self, "nvgBeginFrame");
}


- (void) reset
{
   nvgReset( _cgBackend.context);
}


@end

#pragma clang diagnostic pop

// Stub — overridden by CGContextBase(nanovgGL) in MulleCGNanovgGL
@implementation CGContextBase( nanovg)

@end
