//
//  CGContext+GPUFuture.h
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
#ifdef __has_include
# if __has_include( "CGContext.h")
#  import "CGContext.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"

@class CGImage;


// Backend-neutral framebuffer clear bit flags
typedef NS_OPTIONS( NSUInteger,  CGFramebufferClearFlags)
{
   CGFramebufferClearColorBit   = 0x1,
   CGFramebufferClearDepthBit   = 0x2,
   CGFramebufferClearStencilBit = 0x4
};


typedef NS_ENUM( NSUInteger, CGContextFramebufferMode)
{
   CGContextFramebufferModeDefault = 0,
   CGContextFramebufferModeRead    = 1,
   CGContextFramebufferModeWrite   = 2,
   CGContextFramebufferModeDraw    = 2  // synonym
};



@interface CGContext( GPUFuture) <MulleObjCFuture>


// call this after beginRender, if you don't want to redraw the whole
// framebuffer, set clearFramebufferBits to taste. Uses backgroundColor
// to clear..
//
- (void) clearFramebufferBits:(NSUInteger) bits
                        color:(CGColor) color;

// acquire bits value for above call. If you can avoid clearing the color
// pixels, set flag to NO
- (NSUInteger) framebufferBitsWithColorBit:(BOOL) flag;

- (void) bindGPUFramebuffer:(void *) framebuffer;
- (void) bindDefaultGPUFramebuffer;

- (void) bindImage:(CGImage *) image
     toTextureUnit:(NSUInteger) index;
- (void) barrier;

// drawings should have completed...
- (struct CGBitmap) framebufferBitmap;

// private for CGContext+nanovg.m
- (void) _changeRenderGPU:(struct CGFrameInfo *) info;

@end


