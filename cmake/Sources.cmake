if( MULLE_TRACE_INCLUDE)
   message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

include( _Sources OPTIONAL)

# mulle-nanovg embedded sources
list( APPEND SOURCES
   mulle-nanovg/src/mulle-nanovg.c
   mulle-nanovg/src/nanovg.c
   mulle-nanovg/src/nanovg_d3d11.c
   mulle-nanovg/src/nanovg_mtl.m
   mulle-nanovg/src/nanovg-trace-functions.c
)

# Phase 6: CAOpenGLLayer is in MulleUIOS, not here
# gpu/ backend selection
if( NOT DEFINED MULLE_CG_BACKEND OR MULLE_CG_BACKEND STREQUAL "OPENGL")
   list( APPEND SOURCES
      src/gpu/CGContext+GPU-opengl.m
      src/gpu/CGContext+GPUShader-opengl.m
      src/gpu/CGFramebuffer+GPU-opengl.m
   )
endif()

if( MULLE_CG_BACKEND STREQUAL "D3D11")
   list( APPEND SOURCES
      src/gpu/CGContext+GPU-d3d11.m
      src/gpu/CGFramebuffer+GPU-d3d11.m
   )
endif()
