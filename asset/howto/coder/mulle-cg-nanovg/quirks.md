<!-- keywords: mulle-cg-nanovg, quirks, nanovg, CGContext, CGLayoutContext, CGFramebuffer -->
# quirks

## CGContext / backend access

- `CGContextGetNVGContext` and the render helpers in `src/CGContext+nanovg.m` assert that the context is active in the current thread. The unchecked `_CGContextGetNVGContext` variants are for internal code that already proved ownership.
- `suspendRender` calls `nvgEndFrame`; `resumeRender` starts a new frame with the current frame info. Do not treat them as no-op state toggles.
- `flushRender` is weaker than `suspendRender`: it flushes draw calls but does not reset viewport or NanoVG caches.
- `CGContext+nanovg.h` declares `_initAsPathContext`, `+nanoVGBackend`, `+nanoVGBackendUTF8String`, `-nanovgInfoUTF8String`, and `+pathContext` as provided by `+nanovg-gl`. Do not assume those are implemented by the backend-agnostic core alone.

## CGLayoutContext / fonts

- `useFont:` assumes `_defaultFontName` exists when you pass `nil`. In practice, do not call `useFont:nil` unless the layout context already has a real default font.
- `fontWithNameUTF8String:` returns `nil` and logs to stderr for unknown font names. The hardcoded bundled set is in `src/CGLayoutContext+CGFont+nanovg.m`; there is no dynamic fallback to arbitrary names.
- `fontWithCData:` and `fontWithContentsOfFileWithFileRepresentationString:` cache by name in `_fontMap`. Reusing a name reuses the cached `CGFont`.
- The golden outputs in `test/50-layoutcontext/cglayoutcontext.stdout` and `test/50-layoutcontext/singleline.stdout` show negative `minx`/`miny` values. Treat visual bounds as glyph bounds, not as a guaranteed `0,0`-anchored box.
- The multiline output in `test/50-layoutcontext/multiline.stdout` shows wrap rows preserving their own `minx`/`maxx`; row width is not just `strlen * advance`.

## CGFramebuffer / offscreen rendering

- `initWithBitmapSize:...` returns `nil` for zero-sized targets and for backend allocation failures. Do not treat zero-size framebuffers as harmless placeholders.
- The requested texture flags and bitmap size may change after creation. `src/CGFramebuffer+nanovg.m` explicitly re-reads NanoVG's texture info and size, then folds flags like `FLIPY` back into the stored values.
- Do not call `_bindToContext` or `_unbindFromContext` directly from outside the framebuffer/context glue. The public rule in `src/CGFramebuffer+nanovg.h` is to bind through `CGContext bindFramebuffer:`.

## Path / transform bridge

- `CGAffineTransformAs_NVGtransform` and `_NVGtransformAsCGAffineTransform` assume `sizeof( float) == sizeof( CGFloat)`. They are zero-copy casts, not general converters.
- `mvgAddCGPath` in `src/CGPath+nanovg.c` depends on path command order and current-point state. A circle-segment command infers its start angle from the current point; if the path was not moved to a sane point first, the segment is effectively broken.
- `mvgAddCGPath` treats `CGPathFillStyleCommand` as path winding state and does not advance the current point for it. Do not model it as a drawable segment.

## mvg* wrapper specifics (nanowrap-private.h)

- `mvgBoxGradient` fixes the upstream NanoVG behavior: it auto-insets the rect by `feather / 4.0` before forwarding. Do not pre-inset the rect yourself.
- `mvgRadialGradient` has a different parameter order from `nvgRadialGradient`. This repo takes `(circle, outerColor, innerRadius, innerColor)` — the outer circle is a `CACircle`, inner is a scalar radius. Upstream `nvgRadialGradient` takes inner center/radius first, then outer.
- `mvgImagePattern` rotation is around the top-left corner of the rect, not the center. The header comment says "rotation will rarely do what you want it to, so use CGImage instead."
- `mvgFontSize` rounds to 1/10 pt granularity (min 1 pt, max 2044 pt). The comment says "FreeType is like 1/64 rez, but nanovg is only 1/10".
- `mvgClearType` and `mvgTextBackgroundColor` must be called _after_ `mvgTextColor` — the header explicitly warns about ordering.
- `mvgRoundedRect` and `mvgRoundedRectVarying` accept negative corner radii and negative insets.
- `mvgArc` short-circuits to `mvgMoveTo` when rotation is near zero — no actual arc segment is added.
- `mvgTextBreakLines` has two code paths: if `rows` is NULL or `textRowSize >= sizeof(NVGtextRow)` it converts in-place; otherwise it alloca-copies, converts, and copies back.
- `mvgTextMetrics` returns positive `ascender`/`descender` (via `fabsf`), unlike upstream NanoVG which returns negative descender.

## Texture management

- `deleteTextureID:` only queues the deletion. The actual `nvgDeleteImage` call happens later in `deleteTextureIDs`. This is a thread-safety measure: when a `CGImage` is reaped by an autorelease pool, the context may not be active on that thread.
- `forgetTextureID:` calls `nvgForgetImageTexture`, not `nvgDeleteImage`. Use it for shared texture IDs that should not be destroyed.
- `textureIDWithGPUTexture:bitmapSize:textureFlags:` supports MSAA textures via `NVG_TEXTURE_MSAA` when `NVG_IMAGE_MSAA` is set in flags.

## Drawing conveniences

- `CGContextFillCircleWithGradientColors` and `CGContextStrokeCircleWithGradientColors` use radial gradients internally. The parameter order is `(outerColor, innerColor)` — outer color first.
- `CGContextTLAdjustmentForVisualBounds` returns a `CGPoint` adjustment. It is the only function in this header that takes a `CGLayoutContext *` instead of `CGContext *`.

## Backend selection

- `_MulleCGBackend.h` expects exactly one of `MULLE_CG_BACKEND_OPENGL`, `MULLE_CG_BACKEND_D3D11`, or `MULLE_CG_BACKEND_METAL`. If none is set, the default is OpenGL.
- On non-Apple, non-Windows OpenGL builds, `MULLE_CG_GLVERSION` defaults to `MULLE_CG_GLES2`, not desktop GL 3. Do not quietly write code that assumes GL 3 symbols are always present.
