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
