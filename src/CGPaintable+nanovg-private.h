//
// CGPaintable_nanovg protocol — private to MulleCGNanovg
// Must be included after import-private.h (needs NVGpaint from nanovg.h)
//
#pragma once

#import "import.h"

@protocol CGPaintable_nanovg <CGPaintable>
@optional
- (NVGpaint) NVGpaintWithBounds:(CGRect) rect
                   paintOptions:(struct CGPaintOptions *) options
                        context:(CGContext *) context;
@end
