# MulleCGNanovg Split Plan

Split `MulleCGNanovg` into two repos:

- **MulleCGNanovg** — backend-agnostic nanovg core (keeps this name/repo)
- **MulleCGNanoVG_GL** — OpenGL-specific layer (new repo)

The motivation: `sdl-d3d11` and future Metal/Vulkan backends need to depend on
the nanovg core without pulling in OpenGL code. Currently all GL symbols are
mixed into the same library, causing compile errors when building without GL headers.

---

## What stays in MulleCGNanovg

Everything that does NOT reference GL types (`GLenum`, `GLint`, `GL_*`) or
OpenGL-specific nanovg APIs (`mnvg*`, `nanovg_gl*`, `NVG_CLEARTYPE`, `NVG_MSAA`,
`NVG_NO_DRAWING`).

### Files that stay (no changes needed)

```
src/generic/                        (all files)
src/_MulleCGBackend.h
src/MulleCGNanovg.h / .m
src/nanovg-specific/CGAffineTransform+nanovg.h
src/nanovg-specific/CGBackend+nanovg.h
src/nanovg-specific/CGColor+NVGcolor-private.h
src/nanovg-specific/CGContext+Drawing.h
src/nanovg-specific/CGContext+DrawingConveniences.h
src/nanovg-specific/CGContext+nanovg.h
src/nanovg-specific/CGContext+nanovgTexture.m   (no GL refs)
src/nanovg-specific/CGFramebuffer+nanovg.h / .m (no GL refs)
src/nanovg-specific/CGFunctionTable+nanovg.m    (no GL refs)
src/nanovg-specific/CGLayoutContext+CGFont+nanovg.m (no GL refs)
src/nanovg-specific/CGLayoutContext-impl.m      (no GL refs)
src/nanovg-specific/CGLayoutContext+nanovg.h / .m (no GL refs)
src/nanovg-specific/CGPaintable.h
src/nanovg-specific/CGPaintable+nanovg-private.h
src/nanovg-specific/CGPaint+Drawing.h
src/nanovg-specific/CGPath+nanovg.h
src/nanovg-specific/nanovg+UTF8String.h / .m
src/nanovg-specific/microvg/nanowrap-private.h
mulle-nanovg/src/mulle-nanovg.c
mulle-nanovg/src/nanovg.c
mulle-nanovg/src/nanovg_d3d11.c
mulle-nanovg/src/nanovg_mtl.m
mulle-nanovg/src/nanovg-trace-functions.c
```

### Files that need splitting

**`src/nanovg-specific/CGContext+nanovg.m`** — contains 4 `@implementation` blocks:

| Category | GL-dependent? | Destination |
|----------|--------------|-------------|
| `CGLayoutContext(OpenGL)` | YES — entire category | MulleCGNanoVG_GL |
| `CGContext(Errors)` | YES — entire category | MulleCGNanoVG_GL |
| `CGContextBase(nanovg)` | PARTIALLY — `_framebufferBits = GL_COLOR_BUFFER_BIT` (line ~427) and GL texture readback methods (~640, ~677, ~794) | Split: move GL methods to MulleCGNanoVG_GL |
| `CGContext(nanovg)` | PARTIALLY — `NVG_CLEARTYPE`, `NVG_MSAA`, `NVG_NO_DRAWING` flags (~305, ~397, ~404) and `GL_COLOR_BUFFER_BIT` (~427) | Split: move GL-specific init flags to MulleCGNanoVG_GL |

Suggested split for `CGContext+nanovg.m`:
- Keep in MulleCGNanovg: `CGContextBase(nanovg)` and `CGContext(nanovg)` with GL-specific
  methods/lines removed or stubbed
- Move to MulleCGNanoVG_GL: `CGLayoutContext(OpenGL)`, `CGContext(Errors)`, and the
  GL-specific methods from `CGContextBase(nanovg)` / `CGContext(nanovg)`

**`src/nanovg-specific/nanovg-backend-private.h`** — contains GL include guards.
Move to MulleCGNanoVG_GL.

**`src/nanovg-specific/include-private.h`** — includes `nanovg_gl.h` and `nanovg_gl_utils.h`.
Split: keep the non-GL parts in MulleCGNanovg, move GL includes to MulleCGNanoVG_GL.

---

## What moves to MulleCGNanoVG_GL (new repo)

```
src/gpu/CGContext+GPU.h              (shared header — keep copy in both, or factor out)
src/gpu/CGContext+GPU-opengl.m
src/gpu/CGContext+GPUShader.h
src/gpu/CGContext+GPUShader-opengl.m
src/gpu/CGFramebuffer+GPU.h
src/gpu/CGFramebuffer+GPU-opengl.m
src/nanovg-specific/CGBackendFunctionTable+nanovg.m   (entirely GL: mnvg* calls)
src/nanovg-specific/CGContext(Errors) category        (from CGContext+nanovg.m)
src/nanovg-specific/CGLayoutContext(OpenGL) category  (from CGContext+nanovg.m)
src/nanovg-specific/nanovg-backend-private.h
```

The D3D11 gpu stubs (`CGContext+GPU-d3d11.m`, `CGFramebuffer+GPU-d3d11.m`) stay in
MulleCGNanovg (or move to a future MulleCGNanoVG_D3D11 repo).

---

## Sourcetree changes in MulleUIOS

| Config | Dependencies |
|--------|-------------|
| `glfw` | MulleCGNanovg + MulleCGNanoVG_GL + MulleGLFW |
| `sdl` | MulleCGNanovg + MulleCGNanoVG_GL + MulleSDL |
| `sdl-d3d11` | MulleCGNanovg + MulleSDL (no MulleCGNanoVG_GL) |

The `craftinfo/MulleCGNanovg-craftinfo.d3d11` and `MULLE_CG_BACKEND` cmake variable
mechanism can be removed once the split is done — the dependency graph replaces it.

---

## Steps

1. Create new repo `MulleCGNanoVG_GL` with the same mulle-sde project structure as
   `MulleCGNanovg` (Library type).

2. Move the GL files listed above into `MulleCGNanoVG_GL/src/`.

3. Split `CGContext+nanovg.m`:
   - Extract `CGLayoutContext(OpenGL)` and `CGContext(Errors)` into
     `MulleCGNanoVG_GL/src/CGContext+nanovg-gl.m`
   - Extract GL-specific methods from `CGContextBase(nanovg)` and `CGContext(nanovg)`
     into the same file (as additional categories or extensions of those categories)
   - What remains in `MulleCGNanovg/src/nanovg-specific/CGContext+nanovg.m` should
     compile cleanly without any GL headers

4. Add `MulleCGNanovg` as a dependency of `MulleCGNanoVG_GL` in its sourcetree.

5. Update `MulleUIOS` sourcetree configs:
   - `glfw` and `sdl`: add `MulleCGNanoVG_GL`
   - `sdl-d3d11`: only `MulleCGNanovg` (no GL)
   - Remove `craftinfo/MulleCGNanovg-craftinfo.d3d11` (no longer needed)

6. Remove `MULLE_CG_BACKEND` cmake variable machinery from `MulleCGNanovg/CMakeLists.txt`
   and `Sources.cmake` — no longer needed.

7. Revert the `#ifdef MULLE_CG_BACKEND_OPENGL` guards added to the opengl `.m` files
   (they were a workaround for the split not existing yet).

8. Run `test-backend-configs.sh all` and verify all configs pass.

---

## Notes

- `NVG_CLEARTYPE`, `NVG_MSAA`, `NVG_NO_DRAWING` are nanovg GL flags defined in
  `nanovg_gl.h`. If `CGContext(nanovg)` needs to reference them, either:
  - Move those methods to MulleCGNanoVG_GL, or
  - Define equivalent backend-agnostic flags in MulleCGNanovg and map them in MulleCGNanoVG_GL
- The `mulle-nanovg` submodule (embedded nanovg C sources) stays in MulleCGNanovg.
  MulleCGNanoVG_GL links against it transitively via MulleCGNanovg.
- `nanovg_d3d11.c` and `nanovg_mtl.m` are already in the mulle-nanovg submodule —
  they stay there and are compiled as part of MulleCGNanovg core (they're C files
  with their own include guards).
