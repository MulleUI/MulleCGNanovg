if( MULLE_TRACE_INCLUDE)
   message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

include( _Sources OPTIONAL)

# mulle-nanovg embedded sources (platform-aware)
#
# Core NanoVG and the trace helpers are portable C and build everywhere.
# The GPU backends are gated to their platform:
#   - nanovg_d3d11.c : Windows only
#   - nanovg_mtl.m   : Apple only, and it is *not* added here. It is pure
#                      Apple/Cocoa/Metal Objective-C (ARC, @property strong,
#                      id<MTLTexture>, __bridge) which mulle-clang cannot
#                      compile. It is built with the system compiler and
#                      linked in via cmake/PreLibrary.cmake instead.
#
list( APPEND SOURCES
   mulle-nanovg/src/nanovg.c
   mulle-nanovg/src/nanovg-trace-functions.c
)

if( WIN32)
   list( APPEND SOURCES
      mulle-nanovg/src/nanovg_d3d11.c
   )
endif()

# NOTE: mulle-nanovg/src/nanovg_mtl.m (Apple/Metal backend) is compiled by the
#       system clang in cmake/PreLibrary.cmake on APPLE and must NOT be added
#       to SOURCES here.
