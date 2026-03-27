//
// CGPaintable_nanovg protocol — private to MulleCGNanovg
//
#pragma once

#import "CGPaintable.h"
#include <mulle-nanovg/nanovg.h>

@protocol CGPaintable_nanovg <CGPaintable>
@optional
- (NVGpaint) NVGpaintWithBounds:(CGRect) rect
                   paintOptions:(struct CGPaintOptions *) options
                        context:(CGContext *) context;
@end
