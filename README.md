# MulleCGNanovg

Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

#### 🛰️ MulleCGNanovg is the nanovg rendering backend for MulleCG

MulleCGNanovg is the nanovg rendering backend for MulleCG. It implements the
`CGFunctionTable` and `CGFontFunctionTable` by dispatching all drawing and text
operations to nanovg. This is the default backend used by MulleUI.

The actual OpenGL (or other GPU API) binding is not here — that lives in a
separate library like MulleCGNanovgGL.



| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleCGNanovg.svg) [![Build Status](https://github.com/MulleUI/MulleCGNanovg/workflows/CI/badge.svg)](//github.com/MulleUI/MulleCGNanovg/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleCGNanovg](https://deepwiki.com/MulleUI/MulleCGNanovg)




## Documentation & Guides

* [API Summary](asset/dox/api/toc)
* [Coder Guide](asset/howto/coder/mulle-cg-nanovg)
* [Debugger Guide](asset/howto/debugger/mulle-cg-nanovg)
* [Verifier Guide](asset/howto/verifier/mulle-cg-nanovg)




### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleCGNanovg to your project:

``` sh
mulle-sde add github:MulleUI/MulleCGNanovg
```

To only add the sources of MulleCGNanovg with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleCGNanovg
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleCGNanovg and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleCGNanovg/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [Mullmulle-domain fatal error: empty URL given
eCG](https://github.com/MulleUI/MulleCG)             | Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.
| [mulle-freetype](https://github.com/MulleUI/mulle-freetype)             | Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.
| [# mulle-nanovg is embedded into MulleCG and not shared](https://github.com/MulleUI/mulle-freetype)             | Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleCGNanovg/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleCGNanovg/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleCGNanovg** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  



