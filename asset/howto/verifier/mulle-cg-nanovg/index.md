<!-- keywords: tracing, backend, fonts, framebuffer, layout, glyphs, paths -->
# mulle-cg-nanovg

Use this when user code already reproduces in the NanoVG bridge: live `CGContext` rendering, standalone `CGLayoutContext` text/layout, offscreen `CGFramebuffer` work, or the thin path/paint adapters in this repo.

## Understand first

```bash
mulle-sde howto show debug
mulle-sde api apropos CGContext
mulle-sde api apropos CGLayoutContext
mulle-sde api apropos CGFramebuffer
mulle-sde code search setTraceFile
mulle-sde code search fontWithNameUTF8String
mulle-sde code search bindFramebuffer
mulle-sde code search CGContextCheckBackendError
```

## Local references

- `asset/howto/debugger/mulle-cg-nanovg/index.md`
- `asset/howto/debugger/mulle-cg-nanovg/patterns.md`
- `asset/howto/debugger/mulle-cg-nanovg/quirks.md`
- `src/CGContext+nanovg.h`
- `src/CGContext+nanovg.m`
- `src/CGLayoutContext+nanovg.h`
- `src/CGLayoutContext+CGFont+nanovg.m`
- `src/CGFramebuffer+nanovg.h`
- `src/CGFramebuffer+nanovg.m`
- `src/CGAffineTransform+nanovg.h`
- `src/CGPath+nanovg.h`
- `src/CGPath+nanovg.c`
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

| When user code fails in... | Start here | Local verifier rule |
| --- | --- | --- |
| backend/context glue | `src/CGContext+nanovg.h`, `src/CGContext+nanovg.m` | `CGContextGetNVGContext` asserts current-thread ownership; `suspendRender`/`resumeRender` are real frame boundaries, not cheap toggles |
| text metrics, wrapping, missing glyphs | `src/CGLayoutContext+CGFont+nanovg.m`, `test/50-layoutcontext/cglayoutcontext.stdout` | only fixed bundled font names exist here; lookup failures print to `stderr`; fallback emoji coverage is attached automatically |
| offscreen rendering | `src/CGFramebuffer+nanovg.h`, `src/CGFramebuffer+nanovg.m` | bind through `CGContext`, and restore framebuffer binding and frame info as a pair |
| path conversion | `src/CGPath+nanovg.c`, `src/CGAffineTransform+nanovg.h` | `mvgAddCGPath` depends on command order/current point; transform helpers are casts, not conversions |
| repo-local paint conversion | `src/CGPaintable+nanovg-private.h` | debug this only if the stack is already inside `NVGpaintWithBounds:paintOptions:context:` |
| backend selection / platform mismatch | `src/_MulleCGBackend.h` | default backend is OpenGL when nothing is selected; non-Apple/non-Windows OpenGL defaults to `MULLE_CG_GLES2` |

## Local workflow delta

- There is no demo app here. The smallest live bootstrap path is `test/10-first/cgcontext.m`.
- `src/CGContext+nanovg.m` has a local NanoVG trace hook: `-setTraceFile:`. `src/CGContext+nanovg.h` also exposes `-nanovgInfoUTF8String`, but the header marks it as provided by `+nanovg-gl`, so treat it as backend-specific.
- Backend diagnostics are debug-biased in this repo: `src/CGContext+nanovg.h` only runs `CGContextCheckBackendError` in `DEBUG`, and `src/CGContext+nanovg.m` adds `NVG_DEBUG` only in debug builds. A release-only failure can move when you switch builds.
- For layout regressions, trust the stdout contracts over eyeballing pixels. `test/50-layoutcontext/cglayoutcontext.stdout` and `test/50-layoutcontext/singleline.stdout` show that negative `minx`/`miny` are normal; `test/50-layoutcontext/multiline.stdout` and `test/01-nogl/*.stdout` define the wrapping shape.
- `fontWithNameUTF8String:` only knows the bundled names `sans`, `sans-bold`, `sans-italic`, `mono`, `symbols`, `symbols2`, and `icons`. Unknown names and missing defaults are reported on `stderr`.

## Verify/report

- Report the first failing surface: `CGContext`, `CGLayoutContext`, `CGFramebuffer`, path bridge, paint bridge, or backend selection.
- Say whether the failure is debug-only, release-only, or both.
- For text/layout issues, include the exact differing lines from the matching stdout file.
- For offscreen corruption, say whether both framebuffer binding and frame info were restored.
