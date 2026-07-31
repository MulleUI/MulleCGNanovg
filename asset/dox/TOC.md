# MulleCGNanovg Library Documentation for AI
<!-- Keywords: nanovg, cgcontext, gpu, rendering, vector-graphics, text -->
## 1. Introduction & Purpose

MulleCGNanovg is an Objective-C / C library that provides a **CGContext-backed
rendering backend** powered by the NanoVG vector graphics engine. It bridges
the MulleCG high-level graphics API (CGContext, CGLayoutContext, CGFramebuffer)
to multiple GPU backends including **OpenGL (GL3/GLES2/GLES3)**, **Metal**,
**Direct3D 11**, and **Vulkan** via the embedded `mulle-nanovg` fork.

Key features at a high level:
- Zero-cost CG-to-NVG type conversions (color, transform, paths)
- GPU framebuffer, shader, and texture management
- Convenience drawing functions (rects, circles, lines, gradients, text)
- Font rendering via FreeType with ClearType support
- Text layout, glyph positioning, line breaking, and attributed text
- Debug tracing of NVG command sequences

## 2. Key Concepts & Design Philosophy

- **Backend abstraction via `_MulleCGBackend.h`:** Compile-time selection of
  GPU backend (`MULLE_CG_BACKEND_OPENGL`, `MULLE_CG_BACKEND_D3D11`,
  `MULLE_CG_BACKEND_METAL`) with OpenGL sub-version granularity (GL3.2,
  GLES2, GLES3, GLES3.2).

- **"Wrap, don't re-implement":** The private `nanowrap-private.h` creates
  `mvg*` inline wrappers around raw `nvg*` functions, adapting them to accept
  MulleCG types (CGPoint, CGRect, CGColor, CGAffineTransform) instead of raw
  floats. This gives the CG layer a native-feeling API without duplicating
  the nanovg implementation. Angles passed as `CARotation` and `CAAngle`
  (not radians).

- **No-alloc/factory pattern:** Objective-C instances are created with
  `initWith...` + `autorelease` or `+instance`/`+create*` factory methods.
  Never use bare `alloc`/`init` outside of `-init` and `-dealloc`.

- **Three NVGcontext types:** `NVG_FULL_CONTEXT` (full rendering), `NVG_PATH_CONTEXT`
  (path-only, no GL dependency), `NVG_FONT_CONTEXT` (font-only). Path contexts
  can precompile tessellations and copy them to full contexts via `nvgCopyPath`.

- **Function tables for polymorphic dispatch:** `CGFunctionTable` and
  `CGFontFunctionTable` globals (`CGNanoVGFunctionTable`, `CGNanoVGFontFunctionTable`)
  provide the backend vtable that CGContext uses for rendering operations.

## 3. Core API & Data Structures

### 3.1. `CGContext+nanovg.h` — NVG Context Access & Error Checking

**Global function tables (public, for backend setup):**
- `CGFunctionTable CGNanoVGFunctionTable` — render function table for nanovg backends.
- `CGFontFunctionTable CGNanoVGFontFunctionTable` — font function table for nanovg.

**NVG context accessors (all `static inline`):**
- `struct NVGcontext *CGContextGetNVGContext(CGContextRef self)` — thread-safe accessor; asserts `CGContextIsActiveInCurrentThread`.
- `struct NVGcontext *_CGContextGetNVGContext(CGContextRef self)` — unsafe (no thread check).
- `struct NVGcontext *CGContextBaseGetNVGContext(CGContextBase *self)` — unsafe, no thread check.
- `struct NVGcontext *_CGContextBaseGetNVGContext(CGContextBase *self)` — unsafe, no thread check.

**`@interface CGContext(nanovgFuture) <MulleObjCFuture>`:**
- `- (instancetype) _initAsPathContext;`
- `+ (CGContextNanoVGBackend) nanoVGBackend;`
- `+ (char *) nanoVGBackendUTF8String;`
- `- (char *) nanovgInfoUTF8String;`

**`@interface CGContext(nanovg)`:**
- `- (void) _setNVGContext:(NVGcontext *) nvg functionTable:(CGFunctionTable *) functions backendFunctionTable:(CGBackendFunctionTable *) backendFunctions;`

**`@interface CGContext(Errors)`:**
- `- (void) assertNoBackendError:(char *) str;`

**`@interface CGContext(BackendErrors)`:**
- `- (void) _checkBackendError:(char *) str;`
- `- (BOOL) resetBackendError;`

**Convenience static inline:**
- `void CGContextCheckBackendError(CGContext *ctxt, char *str)` — calls `_checkBackendError:` in DEBUG only.
- `BOOL CGContextResetBackendError(CGContext *ctxt)` — returns `[ctxt resetBackendError]`.

### 3.2. `CGLayoutContext+nanovg.h` — Font Backend in Layout Context

**`@interface CGLayoutContext(nanovg)`:**
- `- (void) _initFontBackend;`
- `- (void) _doneFontBackend;`

**`@interface CGLayoutContext(nanovgFuture)`:**
- `- (void) _initNanovg;` — initializes the NVG context (partial/partial-context modes).
- `- (void) _doneNanovg;` — tears down the NVG context.

**Static inline accessors:**
- `struct NVGcontext *CGLayoutContextGetNVGContext(CGLayoutContext *self)` — NULL-safe accessor via `_fontContext` ivar.
- `struct NVGcontext *_CGLayoutContextGetNVGContext(CGLayoutContext *self)` — unsafe variant.

### 3.3. `CGFramebuffer+nanovg.h` — Bitmap-Backed Textures

**`@interface CGFramebuffer(nanovg)`:**
- `- (instancetype) initWithBitmapSize:(CGPixelSize) size textureFlags:(NSUInteger) textureFlags nameUTF8String:(char *) nameUTF8String context:(CGContext *) context;`
- `- (void) _bindToContext;` — called indirectly via `CGContext bindFramebuffer:`.
- `- (void) _unbindFromContext;` — called indirectly via `CGContext unbindFramebuffer:`.

### 3.4. `CGPath+nanovg.h` — CGPath to NVG Path Conversion

- `void mvgAddCGPath(struct NVGcontext *nvg, CGPath *path);` — Tessellates and emits a CGPath into the NVG context as a compatible path.

### 3.5. `CGAffineTransform+nanovg.h` — Transform Casting

- `typedef float _NVGtransform[6];`

**Static inline zero-cost casts (assert `sizeof(float) == sizeof(CGFloat)`):**
- `float *CGAffineTransformAs_NVGtransform(CGAffineTransform *xform)` — returns `&xform->a`.
- `CGAffineTransform *_NVGtransformAsCGAffineTransform(_NVGtransform xform)` — casts `float[6]` to `CGAffineTransform*`.

### 3.6. `CGContext+DrawingConveniences.h` — High-Level Drawing Helpers

**Solid fill/stroke with color (no path construction needed):**
- `void CGContextFillWithColor(CGContext *context, CGColor color);`
- `void CGContextStrokeWithColor(CGContext *context, CGFloat strokeWidth, CGColor color);`
- `void CGContextStrokeLineHWithColor(CGContext *context, CGPoint p, CGFloat w, CGFloat strokeWidth, CGColor color);`
- `void CGContextStrokeLineVWithColor(CGContext *context, CGPoint p, CGFloat h, CGFloat strokeWidth, CGColor color);`
- `void CGContextFillRoundedRectWithColor(CGContext *context, CGRect rect, CGFloat cornerRadius, CGColor color);`
- `void CGContextFillRectWithColor(CGContext *context, CGRect rect, CGColor color);`
- `void CGContextFillCircleWithColor(CGContext *context, CACircle circle, CGColor color);`
- `void CGContextStrokeRoundedRectWithColor(CGContext *context, CGRect rect, CGFloat cornerRadius, CGFloat strokeWidth, CGColor color);`
- `void CGContextStrokeInsideOfRoundedRectWithColor(CGContext *context, CGRect rect, CGFloat cornerRadius, CGFloat strokeWidth, CGColor color);`
- `void CGContextStrokeRectWithColor(CGContext *context, CGRect rect, CGFloat strokeWidth, CGColor color);`
- `void CGContextStrokeInsideOfRectWithColor(CGContext *context, CGRect rect, CGFloat strokeWidth, CGColor color);`
- `void CGContextStrokeLineWithColor(CGContext *context, CGPoint start, CGPoint end, CGFloat strokeWidth, CGColor color);`
- `void CGContextStrokeCircleWithColor(CGContext *context, CACircle circle, CGFloat strokeWidth, CGColor color);`

**Gradient helpers:**
- `void CGContextFillCircleWithGradientColors(CGContext *context, CACircle circle, CGColor outerColor, CGColor innerColor);`
- `void CGContextStrokeCircleWithGradientColors(CGContext *context, CACircle circle, CGColor outerColor, CGColor innerColor, CGFloat strokeWidth);`

**Text conveniences:**
- `void CGContextFormatInRect(CGContext *context, CGRect rect, CGContentMode contentMode, CGTextOptions options, char *format, ...);`
- `void CGContextFormat(CGContext *context, CGPoint point, char *format, ...);`
- `CGPoint CGContextTLAdjustmentForVisualBounds(CGLayoutContext *context, char *s, size_t length, int alignment, CGTextOptions options);`
- `void CGContextFillRoundedShadow(CGContext *context, CGRect rect, CGFloat cornerRadius, struct CGShadow *shadow);`
- `void CGContextTextInRect(CGContext *context, char *s, size_t length, CGRect rect, CGContentMode contentMode, CGTextOptions options);`
- `struct CGTextBoundsInfo CGContextTextBoundsOptions(CGContext *context, char *s, size_t length, CGRect rect, CGContentMode contentMode, CGTextOptions options);`
- `void CGContextExtendedAlignedText(CGContext *context, char *s, size_t length, CGPoint origin, int alignment, CGTextOptions options);`
- `void CGContext_ExtendedAlignedText(CGContext *context, char *s, size_t length, CGPoint origin, int alignment, CGTextOptions options);`

### 3.7. `nanovg+UTF8String.h` — Debug/String Conversion

- `char *NVGscissorUTF8String(_NVGtransform value);` — declared global, converts scissor transform to UTF8 string.
- `static inline char *_NVGtransformUTF8String(_NVGtransform xform)` — calls `CGAffineTransformUTF8String` on the cast transform.

### 3.8. `src/gpu/CGContext+GPUFuture.h` — GPU Framebuffer & Texture Operations (Future API)

Provides framebuffer clear, bind, and texture binding via `<MulleObjCFuture>` protocol.

- `typedef NS_OPTIONS(NSUInteger, CGFramebufferClearFlags)` — `CGFramebufferClearColorBit`, `CGFramebufferClearDepthBit`, `CGFramebufferClearStencilBit`.
- `typedef NS_ENUM(NSUInteger, CGContextFramebufferMode)` — `CGContextFramebufferModeDefault`, `CGContextFramebufferModeRead`, `CGContextFramebufferModeWrite` (synonym `CGContextFramebufferModeDraw`).

**`@interface CGContext(GPUFuture) <MulleObjCFuture>`:**
- `- (void) clearFramebufferBits:(NSUInteger) bits color:(CGColor) color;` — call after beginRender to clear framebuffer with backgroundColor.
- `- (NSUInteger) framebufferBitsWithColorBit:(BOOL) flag;` — acquire bits mask; pass NO if you can skip the color clear.
- `- (void) bindGPUFramebuffer:(void *) framebuffer;`
- `- (void) bindDefaultGPUFramebuffer;`
- `- (void) bindImage:(CGImage *) image toTextureUnit:(NSUInteger) index;`
- `- (void) barrier;`
- `- (struct CGBitmap) framebufferBitmap;` — read back after drawing completes.
- `- (void) _changeRenderGPU:(struct CGFrameInfo *) info;` — private.

### 3.9. `gpu/CGContext+GPUShader.h` — GPU Shader Management (Public)

Public header for GPU shader compilation, use, and deletion. The `_` prefix on methods indicates internal/backend methods.

**`@interface CGContext(GPUShader)`:**
- `- (CGShaderID) _compileShaderWithShaderSources:(struct CGShaderUTF8Sources *) source;` — returns 0 on error.
- `- (void) _useShader:(CGShaderID) shaderID;`
- `- (void) _deleteShader:(CGShaderID) shaderID;`
- `- (char *) shaderHeaderUTF8String;` — GPU-specific shader preamble (e.g. `#version`).

A private `@interface CGContext(GPUShaderFuture) <MulleObjCFuture>` (in `src/gpu/CGContext+GPUShader.h`) mirrors these methods for the future protocol.

### 3.10. `gpu/CGFramebuffer+GPU.h` — GPU Framebuffer Stub

Stub category `@interface CGFramebuffer(OpenGL)` with no methods declared; reserved for future GPU framebuffer operations.

### 3.11. `_MulleCGBackend.h` — Backend Selection Macros

Defines compile-time backend selection. Exactly one of these must be set:
- `MULLE_CG_BACKEND_OPENGL` (default if none set)
- `MULLE_CG_BACKEND_D3D11`
- `MULLE_CG_BACKEND_METAL`

OpenGL sub-versions:
- `MULLE_CG_GL3_2` (Apple/Windows desktop default)
- `MULLE_CG_GLES2` (Linux/embedded default)
- `MULLE_CG_GLES3`
- `MULLE_CG_GLES3_2`

When `DEFINE_NANOVG_GL_IMPLEMENTATION` is set, the corresponding implementation macro is defined (`NANOVG_GL3_IMPLEMENTATION`, `NANOVG_GLES2_IMPLEMENTATION`, `NANOVG_GLES3_IMPLEMENTATION`, `NANOVG_D3D11_IMPLEMENTATION`, `NANOVG_MTL_IMPLEMENTATION`).

### 3.12. `nanowrap-private.h` — Private: MulleCG-Typed NVG Wrappers (mvg*)

Private header (not public API). Defines the **mvg*** inline functions that map nanovg operations to MulleCG types. Key groups:

**Type aliases:**
- `typedef NSInteger CGTextureID;`
- `typedef NSUInteger CGShaderID;` (0 = invalid)
- `typedef NSInteger CGFontID;` (-1 = `CGFontIDInvalid`)
- `struct CGTextBoundsInfo { CGRect bounds; float size; };`

**NVG init flags:** `NVG_ANTIALIAS`, `NVG_STENCIL_STROKES`, `NVG_DEBUG`, `NVG_PATH_ONLY`, `NVG_FONT_ONLY`, `NVG_CLEARTYPE`, `NVG_MSAA`, `NVG_NO_DRAWING`.

**Frame management:** `mvgBeginFrame(vg, CGSize, CGFloat)`, `mvgCancelFrame(vg)`, `mvgEndFrame(vg)`.

**State:** `mvgSave`, `mvgRestore`, `mvgReset`.

**Render style:** `mvgShapeAntiAlias`, `mvgStrokeColor`/`mvgFillColor` (accept CGColor), `mvgStrokePaint`/`mvgFillPaint`, `mvgMiterLimit`, `mvgStrokeWidth`, `mvgLineCap`, `mvgLineJoin`, `mvgGlobalAlpha`, `mvgBezierTessellation`, `mvgGlobalCompositeOperation`, `mvgGlobalCompositeBlendFunc`, `mvgGlobalCompositeBlendFuncSeparate`.

**Transforms:** `mvgResetTransform`, `mvgTransform(vg, CGAffineTransform*)`, `mvgTranslate(vg, CGPoint)`, `mvgRotate(vg, CARotation)`, `mvgSkewX`/`mvgSkewY(vg, CAAngle)`, `mvgScale(vg, CGVector)`, `mvgCurrentTransform(vg)` returns `CGAffineTransform`.

**Images:** `mvgCreateImage(vg, char*, NSUInteger)`, `mvgCreateImageMem`, `mvgCreateImageRGBA`, `mvgUpdateImage`, `mvgImageSize` returns `CGPixelSize`, `mvgDeleteImage`.

**Paints:** `mvgLinearGradient(vg, CGPoint, CGColor, CGPoint, CGColor)`, `mvgBoxGradient(vg, CGRect, CGFloat, CGColor, CGFloat feather, CGColor)`, `mvgRadialGradient(vg, CACircle, CGColor outer, CGFloat innerRadius, CGColor inner)`, `mvgImagePattern`.

**Scissor:** `mvgScissor(vg, CGRect)`, `mvgIntersectScissor`, `mvgResetScissor`.

**Paths:** `mvgBeginPath`, `mvgMoveTo`, `mvgLineTo`, `mvgBezierTo`, `mvgQuadTo`, `mvgArcTo`, `mvgClosePath`, `mvgPathWinding(vg, CGPathFillStyle)`, `mvgArc(vg, CACircle, CAAngle, CARotation)`, `mvgRect(vg, CGRect)`, `mvgRoundedRect(vg, CGRect, CGFloat r)`, `mvgRoundedRectVarying(vg, CGRect, MulleCornerInsets)`, `mvgEllipse`, `mvgCircle`, `mvgFill`, `mvgStroke`.

**Text/fonts:** `mvgCreateFont`, `mvgCreateFontMem`, `mvgFindFont`, `mvgAddFallbackFontId`/`mvgAddFallbackFont`, `mvgResetFallbackFontsId`/`mvgResetFallbackFonts`, `mvgFontSize(vg, CGFloat)` returns computed (rounded to 1/10) size, `mvgFontBlur`, `mvgTextLetterSpacing`, `mvgTextLineHeight`, `mvgTextAlign(vg, CGCombinedTextAlign)`, `mvgFontFaceId`/`mvgFontFace`, `mvgText(vg, CGPoint, char*, size_t)` returns `CGFloat`, `mvgTextBox`, `mvgClearType`, `mvgTextColor`, `mvgTextBackgroundColor`, `mvgTextBounds` returns `CGTextBoundsInfo`, `mvgTextVisualBounds` returns `CGRect`, `mvgTextBoxBounds`, `mvgTextGlyphPositions`, `mvgTextBreakLines`, `mvgCreateInternal`/`mvgDeleteInternal`.

**CGColor<->NVGcolor conversion (via `CGColor+NVGcolor-private.h`):**
- `static inline NVGcolor CGColorToNVGColor(CGColor c)` — `memcpy`-based (both are `union { float rgba[4]; struct { float r,g,b,a; }; }`).
- `static inline CGColor NVGColorToCGColor(NVGcolor c)` — reverse `memcpy`.

**CGPaintable_nanovg protocol (via `CGPaintable+nanovg-private.h`):**
- `@protocol CGPaintable_nanovg <CGPaintable>`
  `- (NVGpaint) NVGpaintWithBounds:(CGRect) rect paintOptions:(struct CGPaintOptions *) options context:(CGContext *) context;`

### 3.13. `mulle-nanovg` — Embedded NanoVG Fork

The `mulle-nanovg/` directory contains a fork of [NanoVG](https://github.com/memononen/nanovg) with significant enhancements:

- **Unified header** (`mulle-nanovg.h`): Includes `nanovg.h` core + conditionally includes backends based on preprocessor defines.
- **Backends:** `nanovg_gl.h` (GL3, GLES2, GLES3), `nanovg_rlgl.h` (raylib rlgl abstraction), `nanovg_d3d11.h` (DX11), `nanovg_mtl.h` (Metal), `nanovg_vk.h` (Vulkan).
- **Framebuffer support:** `nanovg-framebuffer.h` — opaque `typedef void* NVGframebuffer`.
- **Additional functions vs upstream nanovg:**
  - `nvgClearType` / `nvgTextColor` / `nvgTextBackgroundColor` — ClearType rendering.
  - `nvgChangeFrame` / `nvgFlushFrame` — partial frame management for FBO mixing.
  - `nvgPrecompilePath` / `nvgCopyPath` — precompile path tessellation in `NVG_PATH_CONTEXT` and copy to `NVG_FULL_CONTEXT`.
  - `nvgGetFontHandle` — access backing `FT_Face` or `stbtt_fontinfo`.
  - `nvgCreateImageTexture` / `nvgImageTextureInfo` / `nvgForgetImageTexture` — low-level texture handle sharing.
  - `nvgTextVisualBounds` — "black ink" bounding box (returns 6 floats: xmin, ymin, xmax, ymax, ytop, ybot).
  - `nvgTextVisualMetrics` — bitmap-level font metrics.
  - `nvgTextMetricsWithGap` — includes line gap parameter.
  - `nvgAttributedText` — per-run color/font/size via `NVGtextAttribute` structs.
  - `nvgGetScissor` / `nvgSetScissor` — scissor introspection.
  - `nvgBezierTessellation` — switch between subdivision and AFD tessellation.
  - `nvgTrace` / `nvgTraceName` / `nvgTraceComment` — command tracing for debugging.
  - `nvgCreateFontAtIndex` / `nvgCreateFontMemAtIndex` — load specific face from TTC.
  - `nvgSetEmojiFontId` / `nvgSetEmojiFont` — emoji font support.

## 4. Performance Characteristics

- **Path tessellation:** The nanovg engine tessellates paths into triangles on the CPU each frame. Tessellation algorithm is selectable (`NVG_TESS_SUBDIVISION` default, `NVG_TESS_AFD` for better performance). `nvgPrecompilePath` allows moving tessellation to a `NVG_PATH_CONTEXT` and copying via `nvgCopyPath`, amortizing cost across frames for static paths.

- **Font atlas:** Font glyphs are cached in a texture atlas built on demand during `nvgBeginFrame`/`nvgEndFrame`. Creating many unique glyphs in a single frame triggers atlas rebuild. Font size is rounded to 1/10 point resolution (1pt–2044pt range).

- **Zero-cost type conversions:** `CGColorToNVGColor` and `CGAffineTransform ↔ _NVGtransform` are identity casts via `memcpy` or pointer casting — no arithmetic overhead.

- **Not thread-safe:** The NVGcontext is not thread-safe. CGContext enforces single-thread access via `CGContextIsActiveInCurrentThread`. External locking is required for multi-threaded sharing of a single context.

- **Stencil buffer required:** The GPU rendering target must have a stencil buffer (used for path filling and stroke overlap handling). MSAA is supported via `NVG_MSAA` flag.

## 5. AI Usage Recommendations & Patterns

- **Lifecycle:** Always create contexts with proper factory/lifecycle patterns. CGContext is created via `[[[CGContext alloc] initWithOSGraphicsContext:...] autorelease]` or `+[CGContextBase createPathContext]`. Use `CGLayoutContext`'s `_initFontBackend`/`_initNanovg` and corresponding `_done*` methods for font-specific setup.

- **Drawing flow:** Call `mvgBeginFrame` → draw calls → `mvgEndFrame` (or `mvgCancelFrame` to abort). Between frames, the font texture cache persists; texture memory is released on `mvgEndFrame`.

- **State management:** Use `mvgSave`/`mvgRestore` scoped pairs to isolate transform, style, and scissor changes. `mvgReset` clears state without affecting the stack.

- **Prefer `mvg*` wrappers over raw `nvg*`:** The private `nanowrap-private.h` wrappers use MulleCG types (CGRect, CGColor, CGAffineTransform) and enforce conventions (e.g., `mvgRoundedFontSize` rounding, `mvgBoxGradient` auto-adjusts rect for feather bleed, `mvgRadialGradient` reorders params to outer-first-then-inner).

- **Do not access `_`-prefixed ivars and functions directly** unless you are inside the MulleCGNanovg library itself. Use the public accessor functions.

- **Color conversion:** CGColor and NVGcolor are layout-compatible (`union { float rgba[4]; ... }`). Use `CGColorToNVGColor` / `NVGColorToCGColor` rather than manual field copying.

- **Error checking:** Use `CGContextCheckBackendError` (DEBUG-only) and `CGContextResetBackendError` to detect OpenGL/GPU errors. `assertNoBackendError:` is available for unconditional checks.

- **Font naming:** Font parameters in `char *` carrying UTF8 strings should use property names ending in `UTF8String` per project conventions (e.g., `nameUTF8String`). Same convention applies to `nanoVGBackendUTF8String`, `nanovgInfoUTF8String`, `shaderHeaderUTF8String`.

- **ObjC conventions:** No blocks, no dot-syntax, no `__bridge`, no `nullable`, no generics, no `atomic`/`weak`/`strong`, no `@import`. Use `BOOL` not `bool`. Properties accessed via `[self property]`/`[self setProperty:]`.

## 6. Integration Examples

### Example 1: Creating a CGContext with NVG Backend

```c
// Assumes an OS graphics context (e.g., GLFW window) implementing UIOSGraphicsContext
CGContext       *context;
FakeOSContext   *fake;

@autoreleasepool
{
   fake    = [FakeOSContext instance];
   context = [[[CGContext alloc] initWithOSGraphicsContext:fake
                                                   shareID:0
                                                   options:0] autorelease];

   // After init, CGContext has a fully initialized nanovg backend.
   // The NVG context pointer is accessible via:
   // struct NVGcontext *nvg = CGContextGetNVGContext( context);
}
```

### Example 2: Drawing Shapes with Convenience Functions

```c
CGContext   *context = /* ... */;

// Fill a rounded rect with a gradient
CGContextFillRoundedRectWithColor( context,
                                   CGRectMake( 10, 10, 200, 100),
                                   8.0,
                                   CGColorMakeGenericRGB( 0.2, 0.4, 0.8, 1.0));

// Stroke a circle
CGContextStrokeCircleWithColor( context,
                                CACircleMake( CGPointMake( 150, 150), 50.0),
                                2.0,
                                CGColorMakeGenericRGB( 1.0, 0.0, 0.0, 1.0));

// Fill a circle with a radial gradient
CGContextFillCircleWithGradientColors( context,
                                       CACircleMake( CGPointMake( 300, 150), 50.0),
                                       CGColorMakeGenericRGB( 0.0, 0.0, 0.8, 1.0),  // outer
                                       CGColorMakeGenericRGB( 0.8, 0.8, 1.0, 1.0)); // inner
```

### Example 3: Text Layout with Line Breaking

```c
CGLayoutContext   *layoutContext = /* ... */;
NVGcontext        *nvg           = CGLayoutContextGetNVGContext( layoutContext);
char              *s             = "VfL Bochum 1848 vs. Werder Bremen";
size_t            length         = strlen( s);
CGFloat           breakRowWidth  = 100.0;
NSUInteger        maxRows        = 32;
NSUInteger        count;

// Call once with rows=NULL to count lines
count = mvgTextBreakLines( nvg, s, length, breakRowWidth, NULL, 0, 0);

// Allocate and fill
struct UITextRow   rows[ count];
count = mvgTextBreakLines( nvg, s, length, breakRowWidth, rows, count, sizeof( struct UITextRow));

// Render each row
for( i = 0; i < count; i++)
{
   char   *start  = &s[ rows[ i].range.location];
   size_t len     = rows[ i].range.length;
   mvgText( nvg, CGPointMake( x, y + i * lineHeight), start, len);
}
```

### Example 4: Using the mvg* Wrapper API Directly

```c
NVGcontext   *nvg = CGContextGetNVGContext( context);

mvgBeginFrame( nvg, CGSizeMake( 640, 480), 2.0);  // HiDPI

mvgSave( nvg);
{
   mvgTranslate( nvg, CGPointMake( 100, 100));
   mvgRotate( nvg, CARotationMakeWithDegrees( 45));

   mvgBeginPath( nvg);
   mvgRoundedRect( nvg, CGRectMake( 0, 0, 200, 100), 8.0);
   mvgFillColor( nvg, CGColorMakeGenericRGB( 0.2, 0.6, 0.2, 0.8));
   mvgFill( nvg);
   mvgStrokeColor( nvg, CGColorMakeGenericRGB( 0.0, 0.0, 0.0, 1.0));
   mvgStrokeWidth( nvg, 2.0);
   mvgStroke( nvg);
}
mvgRestore( nvg);

mvgEndFrame( nvg);
```

## 7. Dependencies

Direct `mulle-sde` library dependencies:

- **MulleCG** — Core CG graphics abstraction layer (CGContext, CGLayoutContext, CGFramebuffer, CGPath, CGColor, etc.)
- **mulle-freetype** — FreeType font rendering library (marked `no-actual-build`, `no-header`)
- **mulle-nanovg** — Embedded NanoVG fork (marked `no-build`, `no-header`, `no-link`, `no-public`; compiled directly into this library)
- **mulle-objc-list** — Objective-C list utility (marked `no-header`, `no-link`)
- **GL** (Linux) / **opengl32** (Windows) — Platform GPU libraries
- **harfbuzz** — Text shaping library
- **png** — libpng for image loading
- **z** — zlib compression
