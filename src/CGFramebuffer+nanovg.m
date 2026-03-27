#import "CGFramebuffer+nanovg.h"

#import "CGContext.h"
#import "CGContext+Drawing.h"
#import <MulleCG/CGContext+DebugPrivate.h>
#import "CGContext+GPU.h"
#import "CGContext+nanovg.h"
#import <MulleCG/CGContext+CGFramebuffer.h>
#import <MulleCG/CGImage+DebugPrivate.h>

#import "import-private.h"


@implementation CGFramebuffer( nanovg)

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
   _gpuFramebuffer = CGContextBFN(context)->createFramebuffer( vg,
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
- (void) didBeginFBRenderWithBitmapSize:(CGPixelSize) bitmapSize
                        devicePixelRatio:(CGFloat) ratio
{
   struct NVGcontext   *vg;

   vg = CGContextGetNVGContext( _context);
   nvgBeginFrame( vg, bitmapSize.width, bitmapSize.height, ratio);
}


- (void) willeEndFBRender:(struct CGFramebufferRenderInfo *) memo
{
}


- (struct CGBitmap) RGBABytesBitmap:(struct mulle_allocator *) allocator
{
   return( [_context RGBABytesBitmapOfImage:self
                                  allocator:allocator]);
}

@end

