### 0.0.1


* new mulle-sde config projects style
* fix for multi-window

feature: add trace-comment support and harden font handling in nanovg backend

* introduce traceComment callback in CGNanoVGFunctionTable so backends can emit NVG trace comments
* make font lookup and layout fall back to `_defaultFontName` and emit clearer error/assertion when no font name is available


feature: expose NanoVG backend APIs and convenience helpers

* Expose NVGcontext accessors so callers can retrieve the underlying NanoVG context from CGContext/CGContextBase
* Add CGContext nanovg API surface for setting backend contexts, querying backend info, and creating path contexts
* Add CGFramebuffer initializer for bitmap-backed textures with bind/unbind helpers
* Add affine/transform conversion and UTF8-string helpers for NanoVG transforms and scissor output









feature: add CGContextCopyPath via copyPath function table entry




* `CGContext(nanovg)._initBackend:` calls `_initNanovg` then [super `_initBackend]`
  so CGLayoutContext skips `NVG_FONT_ONLY` for full CGContext
* remove nanovgBackend/nanoVGBackendUTF8String/supportsAntiAliasing/nanovgInfoUTF8String
  (moved back to MulleCGNanovgGL where `NANOVG_GL3_IMPLEMENTATION` etc. are defined)
* setTraceFile: stays here (nvgTrace is in mulle-nanovg, not GL-specific)


* CGContext(nanovg): `_initBackend` was wrong here, only CGLayoutContext needs it
* CGLayoutContext+nanovg.m: remove CGLayoutContextUseFontWithNameUTF8String (moved to MulleCG)
* test sourcetree: add MulleCGNanovgGL dependency (needed for `_initNanovg)`



* +supportsAntiAliasing, +nanoVGBackend, +nanoVGBackendUTF8String
* -nanovgInfoUTF8String, -setTraceFile: — all nvg, no GL


* remove resolveMultiSampleImage: and CGContext(BackendErrors) stubs
* remove willeEndFBRender: and RGBABytesBitmap: from CGFramebuffer+nanovg
* remove CGImage+nanovg.m (RGBABytesBitmap: and drawRect:options:context:)


* remove CGLayoutContext-impl.m (no nanovg deps, belongs in MulleCG)
* flatten nanovg-specific/ subdirectory into src/
* add D3D11 GPU files (CGContext+GPU-d3d11.m, CGFramebuffer+GPU-d3d11.m)
* update reflect files for new layout

feature: initial commit — nanovg rendering backend for MulleCG

* nanovg-based CGContext rendering backend (OpenGL GL3/GLES2/GLES3, D3D11)
* backend selection via `MULLE_CG_BACKEND` cmake variable (default: OpenGL)
* D3D11 backend support: nvgCreateD3D11 init/finalize, backendDevicePointer protocol
* gpu/ backend-specific files: OpenGL GPU context, shader, framebuffer
* font rendering via FreeType with NotoSans, NotoSansMono, NotoEmoji, entypo
* CGPath tessellation via nanovg path engine
* CGPaintable protocol for gradient, image, blended paint rendering
* CGLayoutContext text layout with cursor, selection, tab stops
