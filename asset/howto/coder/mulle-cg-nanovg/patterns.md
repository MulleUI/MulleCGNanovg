<!-- keywords: mulle-cg-nanovg, patterns, CGContext, CGLayoutContext, CGFramebuffer, CGPaintable -->
# patterns

## Render code: stay on the context thread, then drop to NanoVG

- `test/10-first/cgcontext.m` shows the minimal context bootstrap shape: create `CGContext` with an `UIOSGraphicsContext` and keep work on that active thread.
- In live render code, prefer the checked accessor:

```objc
NVGcontext   *vg;

vg = CGContextGetNVGContext( context);
```

- If you need direct backend work in the middle of a frame, use:

```objc
[context suspendRender];
/* direct backend work */
[context resumeRender];
```

`flushRender` only flushes queued NanoVG work; it does not replace the suspend/resume pair.

## Text/layout code: use the local font backend, not raw NanoVG font setup

- `src/CGLayoutContext+nanovg.m` sets `CGNanoVGFontFunctionTable` and lazily creates a font-only backend for standalone layout contexts.
- `src/CGLayoutContext+CGFont+nanovg.m` hardcodes the bundled names `sans`, `sans-bold`, `sans-italic`, `mono`, `symbols`, `symbols2`, and `icons`.
- Happy path:

```objc
CGFont   *font;

font = [layout fontWithNameUTF8String:"sans"];
[layout useFont:font];
```

- When you add a new font source, keep the existing cache shape: load by stable `nameUTF8String`, reuse `_fontMap`, then call `useFont:` so NanoVG gets the canonical face name.
- Local default behavior: bundled named fonts automatically get the emoji fallback font attached in `src/CGLayoutContext+CGFont+nanovg.m`.

## Offscreen rendering: bind framebuffer and render info as a pair

- Follow the shape in `src/CGFramebuffer+nanovg.m` when rendering into a framebuffer:

```objc
struct CGContextFramebuffer   oldFramebuffer;
struct CGFrameInfo            frameInfo;
struct CGFrameInfo            oldFrameInfo;

frameInfo    = CGFrameInfoFBMake( bitmapSize, 1.0, 1.0);
oldFramebuffer = [context bindFramebuffer:CGContextFramebufferMakeWithFramebuffer( framebuffer)];
oldFrameInfo = [context bindRender:&frameInfo];
{
   /* draw into framebuffer */
}
[context bindRender:&oldFrameInfo];
[context bindFramebuffer:oldFramebuffer];
```

- For image-backed framebuffer initialization, keep the current pattern: create the framebuffer from the image size, bind it, draw the image through `UIGraphicsDrawing`, then restore the old bindings.

## Path/transform bridge: keep geometry in CG types until the last step

- The function table in `src/CGFunctionTable+nanovg.m` is intentionally thin; it forwards `CGContext` operations to the `mvg*` wrappers instead of hand-rolling conversions.
- For explicit path bridging:

```objc
NVGcontext   *vg;

vg = CGContextGetNVGContext( context);
mvgBeginPath( vg);
mvgAddCGPath( vg, path);
mvgFill( vg);
```

- For transform/debug glue, reuse the local helpers instead of rebuilding arrays by hand:
  - `CGAffineTransformAs_NVGtransform`
  - `_NVGtransformAsCGAffineTransform`
  - `NVGscissorUTF8String`

## Drawing conveniences: use CGContext shorthand for common primitives

- `src/CGContext+DrawingConveniences.h` provides one-liners for common fill/stroke operations:

```objc
CGContextFillWithColor( context, color);
CGContextFillRectWithColor( context, rect, color);
CGContextFillRoundedRectWithColor( context, rect, cornerRadius, color);
CGContextFillCircleWithColor( context, circle, color);
CGContextStrokeWithColor( context, strokeWidth, color);
CGContextStrokeRectWithColor( context, rect, strokeWidth, color);
CGContextStrokeLineWithColor( context, start, end, strokeWidth, color);
```

- Text conveniences:

```objc
CGContextTextInRect( context, s, length, rect, contentMode, options);
CGContextFormatInRect( context, rect, contentMode, options, format, ...);
CGContextFormat( context, point, format, ...);
```

- Gradient fills:

```objc
CGContextFillCircleWithGradientColors( context, circle, outerColor, innerColor);
```

- These all go through the `CGContext` drawing path, not raw NanoVG.

## Texture management: create, update, delete via CGContext

- Create textures from raw bytes, file data, or file path:

```objc
CGTextureID   tid;

tid = [context textureIDWithRGBABytes:bytes
                           bitmapSize:bitmapSize
                         textureFlags:flags];

tid = [context textureIDWithContentsOfFileUTF8String:"path.png"
                                 textureFlags:flags];

tid = [context textureIDWithFileCData:fileCData
                         textureFlags:flags];
```

- Update and query:

```objc
[context setRGBABytes:bytes forTextureID:tid];
bitmapSize = [context bitmapSizeForTextureID:tid];
gpuTexture = [context gpuTextureForTextureID:tid];
```

- Deletion is queued for thread safety. Call `deleteTextureID:` to queue, then `deleteTextureIDs` to flush the deferred list. Do not call `nvgDeleteImage` directly.

## mvg* wrapper API: direct NanoVG with Mulle CG types

- `src/nanowrap-private.h` wraps nearly every `nvg*` function into an `mvg*` variant that accepts `CGPoint`, `CGRect`, `CGColor`, `CACircle`, `CARotation`, `CGVector`, and `CGAffineTransform` instead of raw floats.
- Use these when you need fine-grained NanoVG control through the CG type system:

```objc
mvgBeginPath( vg);
mvgMoveTo( vg, CGPointMake( 10, 10));
mvgLineTo( vg, CGPointMake( 100, 10));
mvgRoundedRect( vg, CGRectMake( 0, 0, 100, 50), 8);
mvgCircle( vg, CACircleMake( 50, 50, 30));
mvgFill( vg);
```

- Gradient/mvg* paints use CG types directly:

```objc
NVGpaint   paint;

paint = mvgLinearGradient( vg,
             CGPointMake( 0, 0), color1,
             CGPointMake( 100, 0), color2);
mvgFillPaint( vg, paint);
```

- Transform helpers:

```objc
mvgTranslate( vg, CGPointMake( 10, 20));
mvgRotate( vg, CARotationMake( M_PI_4));
mvgScale( vg, CGVectorMake( 1.5, 1.5));
mvgTransform( vg, &someAffineTransform);
```

- The `_beginFrame`/`_endFrame` and other vtables in `src/CGFunctionTable+nanovg.m` forward every call through these `mvg*` wrappers.

## Color bridge: zero-cost CGColor ↔ NVGcolor

- `src/CGColor+NVGcolor-private.h` provides `memcpy`-based conversion. Both structs have identical `float rgba[4]` layout:

```c
NVGcolor   nvgColor;
CGColor    cgColor;

nvgColor = CGColorToNVGColor( cgColor);
cgColor  = NVGColorToCGColor( nvgColor);
```

- The `mvg*` wrappers call these automatically. You only need the helpers when speaking `nvg*` directly.

## Repo-internal paint bridge: implement the NanoVG paint hook

- If you add a new local paint type inside this repo, bridge it through `src/CGPaintable+nanovg-private.h`.
- The local extension point is:

```objc
- (NVGpaint) NVGpaintWithBounds:(CGRect) rect
                   paintOptions:(struct CGPaintOptions *) options
                        context:(CGContext *) context;
```

- Keep this repo-internal. User-facing code should continue to speak in `CGPaintable`/`CGPaint` terms.
