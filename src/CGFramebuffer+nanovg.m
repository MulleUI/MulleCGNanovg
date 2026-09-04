//
//  CGFramebuffer+nanovg.m
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

#import "CGFramebuffer+nanovg.h"
#import "CGContext+Drawing.h"
#import "CGContext+GPUFuture.h"
#import "CGContext+nanovg.h"
#import <MulleCG/CGImage+DebugPrivate.h>
#import <MulleCG/CGContext+DebugPrivate.h>


@implementation CGFramebuffer( nanovg)

@dependency CGFramebuffer( CGLayerRender);

- (instancetype) initWithBitmapSize:(CGPixelSize) bitmapSize
                       textureFlags:(NSUInteger) textureFlags
                     nameUTF8String:(char *) nameUTF8String
                            context:(CGContext *) context
{
   NVGcontext   *vg;
   NSInteger    textureID;
   int          w, h;
   int          imageFlags;

   assert( context && [context isKindOfClass:[CGContext class]]);

   if( bitmapSize.width == 0 || bitmapSize.height == 0)
   {
      [self release];
      return( nil);
   }

   vg              = CGContextGetNVGContext( context);
   _gpuFramebuffer = CGContextBFN( context)->createFramebuffer( vg,
                                                                bitmapSize.width,
                                                                bitmapSize.height,
                                                                textureFlags);
   if( ! _gpuFramebuffer)
   {
      [self release];
      return( nil);
   }

   textureID = CGContextBFN(context)->framebufferTextureID( vg, _gpuFramebuffer);
   if( textureID == -1)
   {
      CGContextBFN(context)->deleteFramebuffer( vg, _gpuFramebuffer);
      _gpuFramebuffer = NULL;
      [self release];
      return( nil);
   }

   // MEMO: nanovg adds some flags, so get em 
   nvgImageTextureInfo( vg, textureID, &imageFlags, NULL, NULL);
   // for completeness check if nanovg did some adaptations
   nvgImageSize( vg, textureID, &w, &h);

   textureFlags     |= imageFlags; // get FLIPY bit for example
   bitmapSize.width  = w;
   bitmapSize.height = h;

   //
   // Image is dependent on the graphics context, and can't live without it
   // TextureImage is threfore retained by the context and not the other way
   // (how long does the context live though)
   //

   CGImageLog( "create framebuffer %p with textureID %td (GPU: %p)",
                     _gpuFramebuffer,
                     textureID,
                     [context gpuTextureForImageID:textureID]);

   return( [self initWithTextureID:textureID
                        bitmapSize:bitmapSize
                      textureFlags:textureFlags
                    nameUTF8String:nameUTF8String
                           context:context]);
}


- (instancetype) initWithImage:(CGImage *) image
                  textureFlags:(NSUInteger) textureFlags
                nameUTF8String:(char *) nameUTF8String
                       context:(CGContext *) context
{
   CGPixelSize                   bitmapSize;
   struct CGContextFramebuffer   old;
   struct CGFrameInfo            frameInfo;
   struct CGFrameInfo            oldFrameInfo;
   CGRect                        rect;

   assert( [image context] == context);
   assert( [context conformsToProtocol:@protocol(UIGraphicsDrawing)]);

   bitmapSize = [image bitmapSize];
   self = [self initWithBitmapSize:bitmapSize
                      textureFlags:textureFlags
                    nameUTF8String:nameUTF8String
                           context:context];
   if( ! self)
      return( self);

   frameInfo    = CGFrameInfoFBMake( bitmapSize, 1.0, 1.0);
   old          = [context bindFramebuffer:CGContextFramebufferMakeWithFramebuffer( self)];
   oldFrameInfo = [context bindRender:&frameInfo];
   {
      rect = CGRectMake( 0.0f, 0.0f, bitmapSize.width, bitmapSize.height);
      [(id <UIGraphicsDrawing>) context drawRect:rect
                                          image:image
                                          scale:1.0];
   }
   [context bindRender:&oldFrameInfo];
   [context bindFramebuffer:old];

   return( self);
}


- (void) _bindToContext
{
   assert( CGContextIsActiveInCurrentThread( _context));

   _CGContextRenderLog( _context, "->%p", _gpuFramebuffer);

   CGContextBFN(_context)->bindFramebuffer( CGContextVG(_context), _gpuFramebuffer);
   CGContextCheckBackendError( _context, "nvgluBindFramebuffer");
}


- (void) _unbindFromContext
{
   assert( CGContextIsActiveInCurrentThread( _context));

   _CGContextRenderLog( _context, "%p->NULL", _gpuFramebuffer);

   CGContextBFN(_context)->bindFramebuffer( CGContextVG(_context), NULL);
   CGContextCheckBackendError( _context, "nvgluBindFramebuffer");
   [self setInitializedFramebuffer:YES];
}


// hacky shit
- (void) _didBeginFBRenderWithBitmapSize:(CGPixelSize) bitmapSize
                        devicePixelRatio:(CGFloat) ratio
{
   struct NVGcontext   *vg;

   vg = CGContextGetNVGContext( _context);
   nvgBeginFrame( vg, bitmapSize.width, bitmapSize.height, ratio);
}

@end

