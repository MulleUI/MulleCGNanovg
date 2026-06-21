//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local CGContext over one in import.h
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


