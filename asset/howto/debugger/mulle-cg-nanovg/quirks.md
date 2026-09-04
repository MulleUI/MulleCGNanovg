<!-- keywords: mulle-cg-nanovg, debugger, quirks, nanovg, CGContext, CGLayoutContext, CGFramebuffer -->
# quirks

## CGContext / backend access

- `CGContextGetNVGContext` asserts `CGContextIsActiveInCurrentThread( self)`. If the stack stops there, debug ownership first, not NanoVG internals first.
- `_CGContextGetNVGContext` skips that check. Treat it as repo-internal escape hatch code.
- `suspendRender` calls `nvgEndFrame`, and `resumeRender` calls `nvgBeginFrame` with `_currentFrameInfo`. They are not cheap no-op toggles.
- `flushRender` does not reset viewport or NanoVG caches.
- `CGContextCheckBackendError` only checks in `DEBUG`. Release-only failures can slip past those guards.
- `_initGraphicsBackend` adds `NVG_DEBUG` only in debug builds.
- `CGContext+nanovg.h` marks `_initAsPathContext`, `+nanoVGBackend`, `+nanoVGBackendUTF8String`, `-nanovgInfoUTF8String`, and `+pathContext` as provided by `+nanovg-gl`; do not assume the backend-agnostic core implements them by itself.

## CGLayoutContext / fonts

- `CGLayoutContext` can either reuse a pre-set `_fontContext` or allocate its own font-only NanoVG backend. Debug lifetime bugs with that split in mind.
- `useFont:` asserts `_defaultFontName`; `useFont:nil` is only safe after a real default font exists.
- `fontWithNameUTF8String:` has a fixed bundled name set and writes failures to stderr. There is no dynamic fallback to arbitrary family names.
- `fontWithCData:` and `fontWithContentsOfFileWithFileRepresentationString:` cache by `nameUTF8String`. Reusing a name can hide changed bytes or a different file.
- `fontWithNameUTF8String:` attaches the `fallback` emoji font when it successfully creates a bundled font, so glyph coverage and metrics are not just the primary face.
- `test/50-layoutcontext/cglayoutcontext.stdout` and `test/50-layoutcontext/singleline.stdout` show negative `minx`/`miny`. Visual bounds are not guaranteed to start at `0,0`.
- `test/50-layoutcontext/multiline.stdout` shows per-row `minx`/`maxx` changes. Wrapped row width is not just character count times advance.

## CGFramebuffer / offscreen rendering

- `initWithBitmapSize:...` returns `nil` for zero-sized targets and backend allocation failures.
- `initWithImage:...` assumes `[image context] == context` and a `UIGraphicsDrawing` context.
- The stored bitmap size and texture flags can change after creation because `src/CGFramebuffer+nanovg.m` re-reads NanoVG texture info and folds flags like `FLIPY` back in.
- `_bindToContext` and `_unbindFromContext` assert current-thread ownership and are not the public debugging entry points.
- Offscreen corruption is often a bad restore pair: this repo saves both framebuffer binding and frame info, then restores both.

## Path / transform bridge

- `CGAffineTransformAs_NVGtransform` and `_NVGtransformAsCGAffineTransform` assume `sizeof( float) == sizeof( CGFloat)`. They are casts, not conversions.
- `mvgAddCGPath` depends on path command order and current-point state.
- A `CGPathCircleSegmentCommand` infers its start angle from the current point. If the path never moved to a sane point first, the arc is effectively broken.
- `CGPathFillStyleCommand` only updates NanoVG winding state; it is not a drawable segment and does not advance the current point.

## Repo-internal paint bridge

- `CGPaintable_nanovg` is private to this repo and its hook is optional.
- If the stack never enters `src/CGPaintable+nanovg-private.h`-style code, do not debug user-facing paint bugs there first.

## Backend selection

- `_MulleCGBackend.h` expects exactly one of `MULLE_CG_BACKEND_OPENGL`, `MULLE_CG_BACKEND_D3D11`, or `MULLE_CG_BACKEND_METAL`.
- If nothing is selected, this repo defaults to OpenGL.
- On non-Apple, non-Windows OpenGL builds, `MULLE_CG_GLVERSION` defaults to `MULLE_CG_GLES2`, not desktop GL 3.
