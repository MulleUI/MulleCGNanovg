<!-- keywords: mulle-cg-nanovg, debugger, patterns, CGContext, CGLayoutContext, CGFramebuffer, CGPaintable -->
# patterns

## Crash in render glue: prove thread and frame ownership first

- `CGContextGetNVGContext` is the checked entry point. If a stacktrace lands there, confirm the context is active in the current thread before looking for deeper NanoVG bugs.
- If you need backend inspection in the middle of a frame, use the real frame boundary pair:

```objc
NVGcontext   *vg;

vg = CGContextGetNVGContext( context);
[context suspendRender];
/* inspect backend state here */
[context resumeRender];
```

- `flushRender` is only a draw flush. Use it for trace/debug output, not for state handoff.
- `-setTraceFile:` in `src/CGContext+nanovg.m` is the local hook when you need NanoVG trace output from a live context.

## Text/layout mismatch: reduce to a named font and the golden outputs

- Reproduce with the bundled names from `src/CGLayoutContext+CGFont+nanovg.m`: `sans`, `sans-bold`, `sans-italic`, `mono`, `symbols`, `symbols2`, `icons`.
- Minimal local shape:

```objc
CGFont   *font;

font = [layout fontWithNameUTF8String:"sans"];
[layout useFont:font];
```

- Compare the result against `test/50-layoutcontext/cglayoutcontext.stdout`, `test/50-layoutcontext/singleline.stdout`, and `test/50-layoutcontext/multiline.stdout`.
- If wrapping is wrong, also check `test/01-nogl/breaklines.stdout`, `test/01-nogl/breaklines-tricky.stdout`, and `test/01-nogl/breaklines-tricky2.stdout`.

## Offscreen bugs: save and restore framebuffer and render info as a pair

- The repo-local happy path is the one in `src/CGFramebuffer+nanovg.m`:

```objc
struct CGContextFramebuffer   oldFramebuffer;
struct CGFrameInfo            frameInfo;
struct CGFrameInfo            oldFrameInfo;

frameInfo      = CGFrameInfoFBMake( bitmapSize, 1.0, 1.0);
oldFramebuffer = [context bindFramebuffer:CGContextFramebufferMakeWithFramebuffer( framebuffer)];
oldFrameInfo   = [context bindRender:&frameInfo];
{
   /* draw into framebuffer */
}
[context bindRender:&oldFrameInfo];
[context bindFramebuffer:oldFramebuffer];
```

- If a bug only appears after offscreen work, inspect both values. Restoring just the framebuffer is not enough in this repo.
- `CGFramebuffer` has private `_bind*` methods, but debug user-facing code at the `CGContext bindFramebuffer:` layer first.

## Path bridge bugs: keep the evidence in CG types until the last step

- When a broken stroke/fill only appears after bridging, reduce to:

```objc
NVGcontext   *vg;

vg = CGContextGetNVGContext( context);
mvgBeginPath( vg);
mvgAddCGPath( vg, path);
```

- If transforms or scissor state look suspicious, inspect `src/CGAffineTransform+nanovg.h` and `src/nanovg+UTF8String.h` before rewriting conversion code. The bridge is intentionally thin.

## Repo-internal paint bugs: debug the private hook, not the public paint object

- Only use this path when the stack is already inside local paint conversion.
- The local extension point is:

```objc
- (NVGpaint) NVGpaintWithBounds:(CGRect) rect
                   paintOptions:(struct CGPaintOptions *) options
                        context:(CGContext *) context;
```

- If a paint object renders correctly in higher-level `CGPaintable` code but breaks only in NanoVG output, inspect this hook in `src/CGPaintable+nanovg-private.h`.
