### Overrides cmake/share/PreLibrary.cmake.
### Picked up in preference over the cmake/share version and not clobbered by
### `mulle-sde upgrade`.
###
### Purpose: the NanoVG Metal backend (mulle-nanovg/src/nanovg_mtl.m) is pure
### Apple / Cocoa / Metal Objective-C:
###
###    * #import <Metal/Metal.h>, <QuartzCore/QuartzCore.h>, <simd/simd.h>
###    * @property (nonatomic, strong), id<MTLTexture>, CAMetalLayer*
###    * ARC (__bridge / __bridge_transfer)
###
### mulle-clang / mulle-objc cannot compile this translation unit at all. So on
### Apple we compile just this one file with Apple's own clang (via xcrun),
### with ARC enabled, producing an object file that is linked into the library.
###
### The backend's public header (nanovg_mtl.h) is plain C (void* for the metal
### layer, NVGcontext*, enums), so the mulle-clang compiled callers never see
### Metal Objective-C and stay ABI compatible with this object.
###
### On non-Apple platforms this file contributes nothing: nanovg_mtl.m is not
### added to SOURCES (see cmake/Sources.cmake) and this block is skipped.

# can be included multiple times

if( MULLE_TRACE_INCLUDE)
   message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
endif()

# Preserve the standard PreLibrary behaviour.
include( CompilerDetectionC)
include( CompilerWarningsC)   # after detection, before flags
include( CompilerFlagsC)

include( PreLibraryAuxC OPTIONAL)


if( APPLE)
   set( MULLE_CG_NANOVG_MTL_SRC
      "${CMAKE_CURRENT_SOURCE_DIR}/mulle-nanovg/src/nanovg_mtl.m")

   #
   # 1) Make sure nanovg_mtl.m is not compiled by mulle-clang. It is normally
   #    not added to SOURCES on Apple (cmake/Sources.cmake gates it), but be
   #    defensive in case it slipped in via reflection or another path.
   #    Library.cmake has already copied SOURCES into LIBRARY_SOURCES (the
   #    actual compile input) before including us, so filter both.
   #
   list( REMOVE_ITEM SOURCES        "mulle-nanovg/src/nanovg_mtl.m")
   list( REMOVE_ITEM LIBRARY_SOURCES "mulle-nanovg/src/nanovg_mtl.m")

   #
   # 2) Assemble the flags for the standalone Apple-clang compile. We mirror
   #    what mulle-clang would have used: project include directories,
   #    dependency include and framework directories, the macOS sysroot,
   #    architectures, PIC and the build-type debug/optimization flags. ARC is
   #    required because nanovg_mtl.m uses __bridge / __bridge_transfer.
   #
   set( _MTL_FLAGS
      "-x" "objective-c"
      "-fobjc-arc"
      "-fPIC"
      "-D${LIBRARY_UPCASE_IDENTIFIER}_BUILD"
      # match the craftinfo CPPFLAGS for mulle-nanovg
      "-DNVG_NO_STB_IMAGE_IMPLEMENTATION"
      "-DNVG_NO_STB_IMAGE_RESIZE_IMPLEMENTATION"
   )

   # Project headers (matches the -I flags used by mulle-clang) plus the
   # embedded nanovg headers (nanovg_mtl.m includes "nanovg_mtl.h", "nanovg.h"
   # and mnvg_bitcode/*.h relative to its own directory).
   list( APPEND _MTL_FLAGS
      "-I${CMAKE_CURRENT_SOURCE_DIR}/src/reflect"
      "-I${CMAKE_CURRENT_SOURCE_DIR}/src/generic"
      "-I${CMAKE_CURRENT_SOURCE_DIR}/src"
      "-I${CMAKE_CURRENT_SOURCE_DIR}/mulle-nanovg/src"
   )

   # Dependency headers and frameworks. MULLE_SDK_PATH is a list of sdk roots
   # (e.g. test/dependency, test/addiction). Each may carry a plain include
   # dir and a per-configuration one, plus Frameworks directories.
   foreach( _sdk ${MULLE_SDK_PATH})
      if( IS_DIRECTORY "${_sdk}/include")
         list( APPEND _MTL_FLAGS "-isystem" "${_sdk}/include")
      endif()
      if( CMAKE_BUILD_TYPE AND IS_DIRECTORY "${_sdk}/${CMAKE_BUILD_TYPE}/include")
         list( APPEND _MTL_FLAGS "-isystem" "${_sdk}/${CMAKE_BUILD_TYPE}/include")
      endif()
      if( IS_DIRECTORY "${_sdk}/Frameworks")
         list( APPEND _MTL_FLAGS "-F" "${_sdk}/Frameworks")
      endif()
      if( CMAKE_BUILD_TYPE AND IS_DIRECTORY "${_sdk}/${CMAKE_BUILD_TYPE}/Frameworks")
         list( APPEND _MTL_FLAGS "-F" "${_sdk}/${CMAKE_BUILD_TYPE}/Frameworks")
      endif()
   endforeach()
   unset( _sdk)

   # macOS sysroot.
   if( CMAKE_OSX_SYSROOT)
      list( APPEND _MTL_FLAGS "-isysroot" "${CMAKE_OSX_SYSROOT}")
   endif()

   # Architectures (may be empty, meaning "native").
   foreach( _arch ${CMAKE_OSX_ARCHITECTURES})
      list( APPEND _MTL_FLAGS "-arch" "${_arch}")
   endforeach()
   unset( _arch)

   # Debug / optimization: mirror the build type.
   if( CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "")
      list( APPEND _MTL_FLAGS "-g" "-DDEBUG")
   else()
      list( APPEND _MTL_FLAGS "-O2" "-DNDEBUG")
   endif()

   #
   # 3) Compile with Apple clang via xcrun into an object file inside the
   #    build tree. Use add_custom_command so ninja/make rebuild it when
   #    nanovg_mtl.m (or its headers) change.
   #
   set( _MTL_OBJ "${CMAKE_CURRENT_BINARY_DIR}/nanovg_mtl.standalone.o")

   find_program( MULLE_CG_NANOVG_XCRUN xcrun)
   if( NOT MULLE_CG_NANOVG_XCRUN)
      message( FATAL_ERROR "xcrun not found; required to build nanovg_mtl.m with Apple clang")
   endif()

   add_custom_command(
      OUTPUT  "${_MTL_OBJ}"
      COMMAND "${MULLE_CG_NANOVG_XCRUN}" clang ${_MTL_FLAGS}
              -c "${MULLE_CG_NANOVG_MTL_SRC}"
              -o "${_MTL_OBJ}"
      DEPENDS "${MULLE_CG_NANOVG_MTL_SRC}"
              "${CMAKE_CURRENT_SOURCE_DIR}/mulle-nanovg/src/nanovg_mtl.h"
      COMMENT "Compiling nanovg_mtl.m with Apple clang (isolated from mulle-objc)"
      VERBATIM
   )

   #
   # 4) Hand the object to Library.cmake. It merges
   #    OTHER_<UPCASE>_OBJECT_FILES into ALL_OBJECT_FILES and links them into
   #    the final library. Because the object is a link input of the library
   #    target, CMake automatically makes the above custom command a build
   #    dependency, so the object is produced before the link. Mark it
   #    EXTERNAL so cmake does not try to compile it itself.
   #
   set_source_files_properties( "${_MTL_OBJ}"
      PROPERTIES
         EXTERNAL_OBJECT TRUE
         GENERATED       TRUE
   )
   list( APPEND OTHER_${LIBRARY_UPCASE_IDENTIFIER}_OBJECT_FILES "${_MTL_OBJ}")
endif()
