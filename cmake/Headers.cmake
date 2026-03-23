if( MULLE_TRACE_INCLUDE)
   message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

include( _Headers OPTIONAL)

include( ResolveSymlinks OPTIONAL)

function( ResolveFileSymlinksIfNeeded listname outputname)
   unset( list)
   if( RESOLVE_INSTALLABLE_HEADER_SYMLINKS)
      foreach( TMP_HEADER ${${listname}})
         file( REAL_PATH "${TMP_HEADER}" TMP_RESOLVED_HEADER)
         list( APPEND list "${TMP_RESOLVED_HEADER}")
      endforeach()
      message( STATUS "Resolved symlinks of ${outputname}=${list}")
   else()
      set( list ${${listname}})
   endif()
   set( ${outputname} ${list} PARENT_SCOPE)
endfunction()

set( TMP_HEADERS ${PUBLIC_HEADERS}
                 ${PUBLIC_GENERIC_HEADERS}
                 ${PUBLIC_GENERATED_HEADERS}
)
ResolveFileSymlinksIfNeeded( TMP_HEADERS INSTALL_PUBLIC_HEADERS)

set( TMP_HEADERS ${PRIVATE_HEADERS})
if( TMP_HEADERS)
   list( REMOVE_ITEM TMP_HEADERS "include-private.h")
endif()
ResolveFileSymlinksIfNeeded( TMP_HEADERS INSTALL_PRIVATE_HEADERS)

# Install mulle-nanovg headers
file( GLOB MULLE_NANOVG_HEADERS
   "${CMAKE_CURRENT_SOURCE_DIR}/mulle-nanovg/src/*.h"
)
install( FILES ${MULLE_NANOVG_HEADERS}
   DESTINATION "include/mulle-nanovg"
)

list( APPEND INCLUDE_DIRS
   mulle-nanovg/src
   mulle-nanovg
   ${CMAKE_CURRENT_SOURCE_DIR}
)

# Allow bare #include "CGImage.h" etc. to find MulleCG headers
if( DEPENDENCY_DIR)
   if( MULLE_SDK_SUBDIR)
      set( _TMP_MULLECG_INCDIR "${DEPENDENCY_DIR}/${MULLE_SDK_SUBDIR}/include/MulleCG")
   else()
      set( _TMP_MULLECG_INCDIR "${DEPENDENCY_DIR}/include/MulleCG")
   endif()
   if( IS_DIRECTORY "${_TMP_MULLECG_INCDIR}")
      list( APPEND INCLUDE_DIRS "${_TMP_MULLECG_INCDIR}")
   endif()
   # fallback
   if( IS_DIRECTORY "${DEPENDENCY_DIR}/include/MulleCG")
      list( APPEND INCLUDE_DIRS "${DEPENDENCY_DIR}/include/MulleCG")
   endif()
endif()
