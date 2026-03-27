//
// CGImage+nanovg.m
// MulleCGNanovg
//
#import <MulleCG/CGImage.h>
#import <MulleCG/CGContext+Render.h>
#import <MulleCG/CGDrawable.h>
#import <MulleCG/CGContext+Drawing.h>

#import "import-private.h"

// declared in CGDrawable.m but not in the header
CGPoint  CGRectGetOriginToTexturePointForRotationAndExtent( CGRect rect,
                                                            CGPoint texturePoint,
                                                            CARotation rotation,
                                                            CGSize extent);


@implementation CGImage( nanovg)

- (struct CGBitmap) RGBABytesBitmap:(struct mulle_allocator *) allocator
{
   return( [[self context] RGBABytesBitmapOfImage:self
                                        allocator:allocator]);
}


- (void) drawRect:(CGRect) rect
          options:(CGDrawableOptions *) options
          context:(CGContext *) context
{
   CGTextureID   textureID;
   CGSize        size;
   CGSize        extent;
   CGRect        patternRect;
   CGPoint       texturePoint;

   if( ! context)
      return;

   if( ! options)
      options = &CGDrawableOptionsDefault;

   // CGImage IS the texture — no need to call cgImageWithContext:textureFlags:
   textureID = [self textureID];
   if( textureID == CGTextureIDInvalid)
      return;

   size = [self size];

   if( options->flags.flip & CGFlipHorizontally)
   {
      rect.origin.x   += rect.size.width;
      rect.size.width  = -rect.size.width;
      size.width       = -size.width;
   }
   if( options->flags.flip & CGFlipVertically)
   {
      rect.origin.y    += rect.size.height;
      rect.size.height  = -rect.size.height;
      size.height       = -size.height;
   }

   extent = rect.size;
   if( options->scale == CGScaleNone || (options->flags.repeat & CGRepeatHorizontally))
      extent.width = size.width;
   if( options->scale == CGScaleNone || (options->flags.repeat & CGRepeatVertically))
      extent.height = size.height;

   texturePoint.x     = 0.5;
   texturePoint.y     = 0.5;
   patternRect.origin = CGRectGetOriginToTexturePointForRotationAndExtent( rect,
                                                                           texturePoint,
                                                                           options->rotation,
                                                                           extent);
   patternRect.size   = extent;

   CGContextBeginPath( context);
   CGContextRoundedRectVarying( context, rect, options->cornerInsets);
   CGContextSetFillImagePattern( context, textureID, patternRect,
                                 options->rotation, options->alpha);
   CGContextFill( context);
}

@end
