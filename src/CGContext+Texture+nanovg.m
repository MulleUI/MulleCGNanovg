//
//  CGContext+Texture+nanovg.m
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

#import "CGContext+Texture.h"
#import "CGContext+GPUFuture.h"
#import "CGContext+nanovg.h"


@implementation CGContext( Texture)


- (CGTextureID) textureIDWithRGBABytes:(void *) bytes
                            bitmapSize:(CGPixelSize) size
                          textureFlags:(NSUInteger) textureFlags
{
   CGTextureID   textureID;

   textureID = nvgCreateImageRGBA( _cgBackend.context,
                                   (int) size.width,
                                   (int) size.height,
                                   (int) textureFlags,
                                   bytes);
   return( textureID);
}


- (CGTextureID) textureIDWithFileCData:(struct mulle_data) fileCData
                          textureFlags:(NSUInteger) textureFlags
{
   CGTextureID   textureID;

   textureID = nvgCreateImageMem( _cgBackend.context,
                                  textureFlags,
                                  fileCData.bytes,
                                  (int) fileCData.length);
   return( textureID);
}


- (CGTextureID) textureIDWithContentsOfFileUTF8String:(char *) filename
                                      textureFlags:(NSUInteger) textureFlags
{
   CGTextureID   textureID;

   textureID = nvgCreateImage( _cgBackend.context, filename, textureFlags);
   return( textureID);
}


- (CGTextureID) textureIDWithGPUTexture:(CGGPUTextureID) gpuTexture
                             bitmapSize:(CGPixelSize) size
                           textureFlags:(NSUInteger) textureFlags
{
   CGTextureID   textureID;
   int           textureType;

   textureType = NVG_TEXTURE_RGBA;
#ifdef NVG_TEXTURE_MSAA
   if( textureFlags & NVG_IMAGE_MSAA)
      textureType = NVG_TEXTURE_MSAA;
#endif
   textureID = nvgCreateImageTexture( _cgBackend.context,
                                      size.width,
                                      size.height,
                                      textureFlags,
                                      textureType,
                                      gpuTexture);
   return( textureID);
}


- (void) deleteTextureIDs
{
   void   *textureID;

   mulle__pointerarray_for( &_deletedTextureIDs, textureID)
   {
      if( _debuggingFlags & 0x2)
         MulleUILog( "release nvgImageId %td", (CGTextureID) textureID);
      nvgDeleteImage( _cgBackend.context, (int) (CGTextureID) textureID);
      CGContextCheckBackendError( self, "after nvgDeleteImage");
   }

   _mulle__pointerarray_reset( &_deletedTextureIDs);
}


//
// When a CGImage gets reaped by an NSAutoreleasePool the context may not
// be activated and it could be tricky to ascertain, that it isn't in use
// by another thread. So we queue these delete requests up
// TODO: may need to lock this... ?
- (void) deleteTextureID:(CGTextureID) textureID
{
   if( _debuggingFlags & 0x2)
      MulleUILog( "queuing release of nvgImageId %td", (CGTextureID) textureID);
   _mulle__pointerarray_add( &_deletedTextureIDs,
                             (void *) textureID,
                             MulleObjCInstanceGetAllocator( self));
}


// used by shared textureIDs
- (void) forgetTextureID:(CGTextureID) textureID
{
   if( _debuggingFlags & 0x2)
      MulleUILog( "forgetting nvgImageId %td", (CGTextureID) textureID);
   nvgForgetImageTexture( _cgBackend.context, textureID);
   CGContextCheckBackendError( self, "after nvgForgetImageTexture");
}


- (void) deleteGPUFramebuffers
{
   CGGPUFramebuffer   *gpuFramebuffer;

   // no callbacks in the locked code so no need to copy, we need a second
   // lock here to not deadlock in CGImage finalize
   mulle_thread_mutex_do( _deletedGPUFramebuffersLock)
   {
      mulle__pointerarray_for( &_deletedGPUFramebuffers, gpuFramebuffer)
      {
         assert( ! _mulle_atomic_pointer_read( &_drawnRenderedFramebuffer)
                 || gpuFramebuffer != [(id) _mulle_atomic_pointer_read( &_drawnRenderedFramebuffer) gpuFramebuffer]);
         assert( ! _mulle_atomic_pointer_read( &_scratchRenderedFramebuffer)
                 || gpuFramebuffer != [(id) _mulle_atomic_pointer_read( &_scratchRenderedFramebuffer) gpuFramebuffer]);

         if( _debuggingFlags & 0x2)
            MulleUILog( "release framebuffer %p", gpuFramebuffer);
         CGContextBFN(self)->deleteFramebuffer( _cgBackend.context, gpuFramebuffer);
         CGContextCheckBackendError( self, "after nvgluDeleteFramebuffer");
      }

      _mulle__pointerarray_reset( &_deletedGPUFramebuffers);
   }
}


//
// When a CGImage gets reaped by an NSAutoreleasePool the context may not
// be activated and it could be tricky to ascertain, that it isn't in use
// by another thread. So we queue these delete requests up
//
- (void) deleteGPUFramebuffer:(CGGPUFramebuffer *) gpuFramebuffer
{
   if( _debuggingFlags & 0x2)
      MulleUILog( "queuing release of GPU framebuffer %p", gpuFramebuffer);

   mulle_thread_mutex_do( _deletedGPUFramebuffersLock)
   {
      _mulle__pointerarray_add( &_deletedGPUFramebuffers,
                                gpuFramebuffer,
                                MulleObjCInstanceGetAllocator( self));
   }
}


- (CGGPUTextureID) gpuTextureForTextureID:(CGTextureID) textureID
{
   NVGcontext       *vg;
   CGGPUTextureID   gpuTexture;

   vg = CGContextGetNVGContext( self);
   nvgImageTextureInfo( vg, textureID, NULL, NULL, &gpuTexture);
   return( gpuTexture);
}


- (void) setRGBABytes:(void *) bytes
         forTextureID:(CGTextureID) textureID
{
   assert( CGContextIsActiveInCurrentThread( self));

   nvgUpdateImage( CGContextGetNVGContext( self), textureID, bytes);
}


- (CGPixelSize) bitmapSizeForTextureID:(CGTextureID) textureID
{
   int   w, h;

   nvgImageSize( CGContextGetNVGContext( self), textureID, &w, &h);
   return( CGPixelSizeMake( w, h));
}

@end
