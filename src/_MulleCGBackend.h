//
//  _MulleCGBackend.h
//  MulleCGNanovg
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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
