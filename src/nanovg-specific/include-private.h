#pragma once

// Pull in the base MulleCG private headers
#ifdef __has_include
# if __has_include( "../generic/include-private.h")
#  include "../generic/include-private.h"
# endif
#endif

// Backend selection and GPU/nanovg headers — only needed in nanovg-specific/
#include "_MulleCGBackend.h"

// ---- OpenGL ----
#ifdef MULLE_CG_BACKEND_OPENGL

# ifdef __APPLE__
#  define GL_GLEXT_PROTOTYPES
#  define GL_SILENCE_DEPRECATION
#  if defined( MULLE_CG_USE_APPLE_MACROS)
#   define MULLE_CG_HAVE_DEPRECATED_OPENGL 1
#   include <OpenGL/OpenGL.h>
#   include <OpenGL/CGLMacro.h>
#  else
#   if defined( MULLE_CG_USE_APPLE_GL)
#    define MULLE_CG_HAVE_DEPRECATED_OPENGL 1
#    include <OpenGL/gl.h>
#   endif
#   if defined( MULLE_CG_USE_APPLE_GL_EXT)
#    include <OpenGL/glext.h>
#   endif
#   if defined( MULLE_CG_USE_APPLE_GL3) || (! defined( MULLE_CG_USE_APPLE_GL) && ! defined( MULLE_CG_USE_APPLE_GL_EXT))
#    define MULLE_CG_HAVE_MODERN_OPENGL 1
#    include <OpenGL/gl3.h>
#   endif
#  endif
# else
#  if MULLE_CG_GLVERSION == MULLE_CG_GL3_2
#   define GL_GLEXT_PROTOTYPES
#   define MULLE_CG_HAVE_MODERN_OPENGL 1
#   include <GL/gl.h>
#   include <GL/glext.h>
#  elif MULLE_CG_GLVERSION == MULLE_CG_GLES2
#   define GL_GLEXT_PROTOTYPES
#   define MULLE_CG_HAVE_MODERN_OPENGL 1
#   include <GLES2/gl2.h>
#   include <GLES2/gl2ext.h>
#  elif MULLE_CG_GLVERSION == MULLE_CG_GLES3 || MULLE_CG_GLVERSION == MULLE_CG_GLES3_2
#   define GL_GLEXT_PROTOTYPES
#   define MULLE_CG_HAVE_MODERN_OPENGL 1
#   include <GLES3/gl3.h>
#   include <GLES3/gl3ext.h>
#   ifndef GL_MULTISAMPLE
#    define GL_MULTISAMPLE 0x809D
#   endif
#  endif
# endif

# include <mulle-nanovg/nanovg.h>
# include <mulle-nanovg/nanovg_gl.h>
# include <mulle-nanovg/nanovg_gl_utils.h>

// ---- D3D11 ----
#elif defined( MULLE_CG_BACKEND_D3D11)

# include <mulle-nanovg/nanovg.h>
# include <mulle-nanovg/nanovg_d3d11.h>

// ---- Metal ----
#elif defined( MULLE_CG_BACKEND_METAL)

# include <mulle-nanovg/nanovg.h>
# include <mulle-nanovg/nanovg_mtl.h>

#endif /* backend */

#include "nanovg-backend-private.h"
#include "microvg/nanowrap-private.h"
