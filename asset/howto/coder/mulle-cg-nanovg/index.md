<!-- keywords: mulle-cg-nanovg, nanovg, CGContext, CGLayoutContext, CGFramebuffer, CGPath -->
# mulle-cg-nanovg

Use this when you touch the NanoVG bridge itself: live render contexts, font/layout backend code, offscreen framebuffers, or the thin path/transform helpers in this repo.

## Understand first

```bash
mulle-sde api cat MulleCG
mulle-sde api apropos CGContext
mulle-sde api apropos CGLayoutContext
mulle-sde api apropos CGFramebuffer
mulle-sde code search CGContextGetNVGContext
mulle-sde code search mvgAddCGPath
mulle-sde code grep "bindFramebuffer"
```

## Local references

- `src/CGContext+nanovg.h`
- `src/CGContext+nanovg.m`
- `src/CGFramebuffer+nanovg.h`
- `src/CGFramebuffer+nanovg.m`
- `src/CGLayoutContext+nanovg.h`
- `src/CGLayoutContext+nanovg.m`
- `src/CGLayoutContext+CGFont+nanovg.m`
- `src/CGAffineTransform+nanovg.h`
- `src/CGPath+nanovg.h`
- `src/CGPath+nanovg.c`
- `src/nanovg+UTF8String.h`
- `src/CGPaintable+nanovg-private.h`
- `src/_MulleCGBackend.h`
- `test/10-first/cgcontext.m`
- `test/01-nogl/breaklines.stdout`
- `test/01-nogl/breaklines-tricky.stdout`
- `test/01-nogl/breaklines-tricky2.stdout`
- `test/50-layoutcontext/cglayoutcontext.stdout`
- `test/50-layoutcontext/singleline.stdout`
- `test/50-layoutcontext/multiline.stdout`

## Main local surfaces

| When you are changing... | Start here | Local rule |
| --- | --- | --- |
| live rendering or backend escapes | `src/CGContext+nanovg.h`, `src/CGContext+nanovg.m` | only grab `NVGcontext *` from the active render thread; use `suspendRender`/`resumeRender` around direct backend work |
| font loading, selection, metrics, wrapping | `src/CGLayoutContext+nanovg.h`, `src/CGLayoutContext+nanovg.m`, `src/CGLayoutContext+CGFont+nanovg.m` | standalone layout contexts create a font-only NanoVG backend; bundled font names are hardcoded here |
| offscreen rendering | `src/CGFramebuffer+nanovg.h`, `src/CGFramebuffer+nanovg.m` | bind through `CGContext`, not through the framebuffer's private `_bind*` methods |
| raw NanoVG bridge glue | `src/CGAffineTransform+nanovg.h`, `src/CGPath+nanovg.h`, `src/nanovg+UTF8String.h` | helpers assume NanoVG-compatible float layout and CoreGraphics path command ordering |

## Local workflow delta

- `CGContext` owns the live NanoVG backend. Debug builds enable `NVG_DEBUG` in `_initGraphicsBackend`.
- `CGLayoutContext` is also a backend owner. If `_fontContext` already exists it reuses it; otherwise it creates its own font-only backend in `src/CGLayoutContext+nanovg.m`.
- `CGFramebuffer` is context-tied GPU state. Offscreen code in this repo always saves and restores both framebuffer binding and frame info.
- There is no demo app here. The concrete usage anchors are the bootstrap smoke test in `test/10-first/cgcontext.m` and the text golden outputs in `test/01-nogl` and `test/50-layoutcontext`.

## Verify/report

- Use `mulle-sde test run test/10-first/cgcontext.m` for the basic context bootstrap path.
- For text/layout changes, treat `test/01-nogl/*.stdout` and `test/50-layoutcontext/*.stdout` as the local contract for bounds, visual bounds, and wrapping shape.
