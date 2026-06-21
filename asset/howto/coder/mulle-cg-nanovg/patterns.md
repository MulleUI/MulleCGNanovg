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

## Repo-internal paint bridge: implement the NanoVG paint hook

- If you add a new local paint type inside this repo, bridge it through `src/CGPaintable+nanovg-private.h`.
- The local extension point is:

```objc
- (NVGpaint) NVGpaintWithBounds:(CGRect) rect
                   paintOptions:(struct CGPaintOptions *) options
                        context:(CGContext *) context;
```

- Keep this repo-internal. User-facing code should continue to speak in `CGPaintable`/`CGPaint` terms.
