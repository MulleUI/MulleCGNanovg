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

