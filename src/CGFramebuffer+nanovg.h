#import "import.h"

struct CGFrameInfo;


@interface CGFramebuffer( nanovg)

- (instancetype) initWithBitmapSize:(CGPixelSize) size
                       textureFlags:(NSUInteger) textureFlags
                     nameUTF8String:(char *) nameUTF8String
                            context:(CGContext *) context;

// Use CGContext bindFramebuffer: to bind/unbind a layer, don't call directly
- (void) _bindToContext;
- (void) _unbindFromContext;

@end

