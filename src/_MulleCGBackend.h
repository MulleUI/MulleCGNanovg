#ifndef _mulle_cg_backend_h__
#define _mulle_cg_backend_h__

// MEMO: do not include other files in here

// --- GPU backend selection ---
// Exactly one of MULLE_CG_BACKEND_OPENGL, MULLE_CG_BACKEND_D3D11,
// MULLE_CG_BACKEND_METAL must be defined (by CMake or manually).
// Default: D3D11 on Windows, OpenGL everywhere else.

#if !defined( MULLE_CG_BACKEND_OPENGL) && !defined( MULLE_CG_BACKEND_D3D11) && !defined( MULLE_CG_BACKEND_METAL)
# define MULLE_CG_BACKEND_OPENGL
#endif


// --- OpenGL sub-version (only relevant when MULLE_CG_BACKEND_OPENGL) ---

#ifdef MULLE_CG_BACKEND_OPENGL

# define MULLE_CG_GL3_2    1
# define MULLE_CG_GLES2    2
# define MULLE_CG_GLES3    3
# define MULLE_CG_GLES3_2  4

# ifndef MULLE_CG_GLVERSION
#  ifdef __APPLE__
#   define MULLE_CG_GLVERSION   MULLE_CG_GL3_2
#  elif defined( _WIN32) || defined( __MINGW32__)
#   define MULLE_CG_GLVERSION   MULLE_CG_GL3_2
#  else
#   define MULLE_CG_GLVERSION   MULLE_CG_GLES2
#  endif
# endif

# ifdef DEFINE_NANOVG_GL_IMPLEMENTATION
#  if MULLE_CG_GLVERSION == MULLE_CG_GL3_2
#   define NANOVG_GL3_IMPLEMENTATION
#  elif MULLE_CG_GLVERSION == MULLE_CG_GLES2
#   define NANOVG_GLES2_IMPLEMENTATION
#  elif MULLE_CG_GLVERSION == MULLE_CG_GLES3 || MULLE_CG_GLVERSION == MULLE_CG_GLES3_2
#   define NANOVG_GLES3_IMPLEMENTATION
#  endif
# endif

#endif /* MULLE_CG_BACKEND_OPENGL */


// --- D3D11 ---

#ifdef MULLE_CG_BACKEND_D3D11
# ifdef DEFINE_NANOVG_GL_IMPLEMENTATION
#  define NANOVG_D3D11_IMPLEMENTATION
# endif
#endif


// --- Metal ---

#ifdef MULLE_CG_BACKEND_METAL
# ifdef DEFINE_NANOVG_GL_IMPLEMENTATION
#  define NANOVG_MTL_IMPLEMENTATION
# endif
#endif

#endif /* _mulle_cg_backend_h__ */
