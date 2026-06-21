<!-- keywords: mulle-cg-nanovg, debugger, nanovg, CGContext, CGLayoutContext, CGFramebuffer, CGPath -->
# mulle-cg-nanovg

Use this when a crash, assert, or rendering mismatch lands in the NanoVG bridge: live `CGContext` rendering, standalone `CGLayoutContext` font/layout code, offscreen `CGFramebuffer` code, or the thin path/transform helpers in this repo.

## Understand first

```bash
mulle-sde howto show debug
mulle-sde api apropos CGContext
mulle-sde api apropos CGLayoutContext
mulle-sde api apropos CGFramebuffer
mulle-sde code search CGContextGetNVGContext
mulle-sde code search fontWithNameUTF8String
mulle-sde code search bindFramebuffer
mulle-sde code search mvgAddCGPath
```

## Local references

- `.mulle/share/howto/debug.md`
- `src/CGContext+nanovg.h`
- `src/CGContext+nanovg.m`
- `src/CGFramebuffer+nanovg.h`
- `src/CGFramebuffer+nanovg.m`
- `src/CGLayoutContext+nanovg.h`
- `src/CGLayoutContext+nanovg.m`
- `src/CGLayoutContext+CGFont+nanovg.m`
- `src/CGPaintable+nanovg-private.h`
- `src/CGPath+nanovg.h`
- `src/CGPath+nanovg.c`
- `src/CGAffineTransform+nanovg.h`
- `src/nanovg+UTF8String.h`
- `src/nanowrap-private.h`
- `src/_MulleCGBackend.h`
- `test/10-first/cgcontext.m`
- `test/01-nogl/breaklines.stdout`
- `test/01-nogl/breaklines-tricky.stdout`
- `test/01-nogl/breaklines-tricky2.stdout`
- `test/50-layoutcontext/cglayoutcontext.stdout`
- `test/50-layoutcontext/singleline.stdout`
- `test/50-layoutcontext/multiline.stdout`

## Main local surfaces

| When the first bad frame is in... | Start here | Local rule |
| --- | --- | --- |
| live render / backend glue | `src/CGContext+nanovg.h`, `src/CGContext+nanovg.m` | `CGContextGetNVGContext` asserts current-thread ownership; `suspendRender`/`resumeRender` really end/begin NanoVG frames |
| text metrics, wrapping, missing glyphs | `src/CGLayoutContext+nanovg.m`, `src/CGLayoutContext+CGFont+nanovg.m`, `test/50-layoutcontext/cglayoutcontext.stdout` | standalone layout contexts own a font-only backend; bundled font names are fixed and unknown names log to stderr |
| offscreen / FBO corruption | `src/CGFramebuffer+nanovg.h`, `src/CGFramebuffer+nanovg.m` | bind through `CGContext`, and always restore framebuffer and render info together |
| path conversion weirdness | `src/CGPath+nanovg.c`, `src/CGAffineTransform+nanovg.h` | `mvgAddCGPath` depends on current-point state; transform helpers are zero-copy casts |
| repo-internal paint bridge bugs | `src/CGPaintable+nanovg-private.h` | the NanoVG paint hook is private to this repo; debug it only when the stack is already inside local paint conversion |

## Local workflow delta

- Start with the shared crash workflow in `.mulle/share/howto/debug.md`, then map the first repo frame to one of the surfaces above.
- There is no app demo here. The smallest context bootstrap reproducer is `test/10-first/cgcontext.m`.
- For layout regressions, trust `test/01-nogl/breaklines.stdout`, `test/01-nogl/breaklines-tricky.stdout`, `test/01-nogl/breaklines-tricky2.stdout`, `test/50-layoutcontext/cglayoutcontext.stdout`, `test/50-layoutcontext/singleline.stdout`, and `test/50-layoutcontext/multiline.stdout` over eyeballing text width; this repo treats those files as the shape contract.
- Backend state bugs usually cross one of two boundaries: `suspendRender`/`resumeRender` in `src/CGContext+nanovg.m`, or framebuffer bind/restore in `src/CGFramebuffer+nanovg.m`.
- Backend checks are debug-biased here: `CGContextCheckBackendError` only fires in `DEBUG`, and `_initGraphicsBackend` adds `NVG_DEBUG` only in debug builds.

## Verify/report

- Re-run the smallest reproducer for the family you touched, then report the first repo frame that changed.
- For text/layout issues, quote the exact changed lines from the matching stdout file in `test/01-nogl` or `test/50-layoutcontext`.
