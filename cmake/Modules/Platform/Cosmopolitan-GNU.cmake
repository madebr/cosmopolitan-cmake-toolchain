# Distributed under the OSI-approved BSD 3-Clause License.

# This module is shared by multiple languages; use include blocker.
if(__COSMOPOLITAN_GNU)
  return()
endif()
set(__COSMOPOLITAN_GNU 1)

set(CMAKE_IMPORT_LIBRARY_PREFIX "lib")
#set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
#set(CMAKE_SHARED_MODULE_PREFIX  "lib")
set(CMAKE_STATIC_LIBRARY_PREFIX "lib")

set(CMAKE_EXECUTABLE_SUFFIX     ".com")
#set(CMAKE_IMPORT_LIBRARY_SUFFIX ".dll.a")
#set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")
#set(CMAKE_SHARED_MODULE_SUFFIX  ".dll")
set(CMAKE_STATIC_LIBRARY_SUFFIX ".a")

set(CMAKE_FIND_LIBRARY_PREFIXES "lib")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
set(CMAKE_C_STANDARD_LIBRARIES_INIT "${COSMOPOLITAN_ROOT}/cosmopolitan.a")

set(CMAKE_LIBRARY_PATH_FLAG "-L")
set(CMAKE_LINK_LIBRARY_FLAG "-l")
set(CMAKE_LINK_LIBRARY_SUFFIX "")

# Check if GNU ld is too old to support @FILE syntax.
set(__COSMOPOLITAN_GNU_LD_RESPONSE 1)
execute_process(COMMAND ld -v OUTPUT_VARIABLE _help ERROR_VARIABLE _help)
if("${_help}" MATCHES "GNU ld .* 2\\.1[1-6]")
  set(__COSMOPOLITAN_GNU_LD_RESPONSE 0)
endif()


# Features for LINK_LIBRARY generator expression
## check linker capabilities
if(NOT DEFINED _CMAKE_LINKER_PUSHPOP_STATE_SUPPORTED)
  execute_process(COMMAND "${CMAKE_LINKER}" --help
                  OUTPUT_VARIABLE __linker_help
                  ERROR_VARIABLE __linker_help)
  if(__linker_help MATCHES "--push-state" AND __linker_help MATCHES "--pop-state")
    set(_CMAKE_LINKER_PUSHPOP_STATE_SUPPORTED TRUE CACHE INTERNAL "linker supports push/pop state")
  else()
    set(_CMAKE_LINKER_PUSHPOP_STATE_SUPPORTED FALSE CACHE INTERNAL "linker supports push/pop state")
  endif()
  unset(__linker_help)
endif()
## WHOLE_ARCHIVE: Force loading all members of an archive
if(_CMAKE_LINKER_PUSHPOP_STATE_SUPPORTED)
  set(CMAKE_LINK_LIBRARY_USING_WHOLE_ARCHIVE "LINKER:--push-state,--whole-archive"
                                             "<LINK_ITEM>"
                                             "LINKER:--pop-state")
else()
  set(CMAKE_LINK_LIBRARY_USING_WHOLE_ARCHIVE "LINKER:--whole-archive"
                                             "<LINK_ITEM>"
                                             "LINKER:--no-whole-archive")
endif()
set(CMAKE_LINK_LIBRARY_USING_WHOLE_ARCHIVE_SUPPORTED TRUE)

# Features for LINK_GROUP generator expression
## RESCAN: request the linker to rescan static libraries until there is
## no pending undefined symbols
set(CMAKE_LINK_GROUP_USING_RESCAN "LINKER:--start-group" "LINKER:--end-group")
set(CMAKE_LINK_GROUP_USING_RESCAN_SUPPORTED TRUE)


macro(__cosmopolitan_compiler_gnu lang)

  # Create archiving rules to support large object file lists for static libraries.
  set(CMAKE_${lang}_ARCHIVE_CREATE "<CMAKE_AR> qc <TARGET> <LINK_FLAGS> <OBJECTS>")
  set(CMAKE_${lang}_ARCHIVE_APPEND "<CMAKE_AR> q <TARGET> <LINK_FLAGS> <OBJECTS>")
  set(CMAKE_${lang}_ARCHIVE_FINISH "<CMAKE_RANLIB> <TARGET>")

  # Initialize C link type selection flags.  These flags are used when
  # building a shared library, shared module, or executable that links
  # to other libraries to select whether to use the static or shared
  # versions of the libraries.
  foreach(type SHARED_LIBRARY SHARED_MODULE EXE)
    set(CMAKE_${type}_LINK_STATIC_${lang}_FLAGS "-Wl,-Bstatic")
    set(CMAKE_${type}_LINK_DYNAMIC_${lang}_FLAGS "-Wl,-Bdynamic")
  endforeach()

  # No -fPIC for Cosmopolitan
  set(CMAKE_${lang}_COMPILE_OPTIONS_PIC "")
  set(CMAKE_${lang}_COMPILE_OPTIONS_PIE "")
  set(_CMAKE_${lang}_PIE_MAY_BE_SUPPORTED_BY_LINKER NO)
  set(CMAKE_${lang}_LINK_OPTIONS_PIE "")
  set(CMAKE_${lang}_LINK_OPTIONS_NO_PIE "")
  set(CMAKE_SHARED_LIBRARY_${lang}_FLAGS "")

  set(CMAKE_${lang}_USE_RESPONSE_FILE_FOR_OBJECTS ${__COSMOPOLITAN_GNU_LD_RESPONSE})
  set(CMAKE_${lang}_USE_RESPONSE_FILE_FOR_LIBRARIES ${__COSMOPOLITAN_GNU_LD_RESPONSE})
  set(CMAKE_${lang}_USE_RESPONSE_FILE_FOR_INCLUDES 1)

  # We prefer "@" for response files but it is not supported by gcc 3.
  execute_process(COMMAND ${CMAKE_${lang}_COMPILER} --version OUTPUT_VARIABLE _ver ERROR_VARIABLE _ver)
  if("${_ver}" MATCHES "\\(GCC\\) 3\\.")
    if("${lang}" STREQUAL "Fortran")
      # The GNU Fortran compiler reports an error:
      #   no input files; unwilling to write output files
      # when the response file is passed with "-Wl,@".
      set(CMAKE_Fortran_USE_RESPONSE_FILE_FOR_OBJECTS 0)
    else()
      # Use "-Wl,@" to pass the response file to the linker.
      set(CMAKE_${lang}_RESPONSE_FILE_LINK_FLAG "-Wl,@")
    endif()
    # The GNU 3.x compilers do not support response files (only linkers).
    set(CMAKE_${lang}_USE_RESPONSE_FILE_FOR_INCLUDES 0)
    # Link libraries are generated only for the front-end.
    set(CMAKE_${lang}_USE_RESPONSE_FILE_FOR_LIBRARIES 0)
  else()
    # Use "@" to pass the response file to the front-end.
    set(CMAKE_${lang}_RESPONSE_FILE_LINK_FLAG "@")
  endif()

  # Binary link rules.
  set(CMAKE_${lang}_CREATE_SHARED_MODULE
    "<CMAKE_${lang}_COMPILER> <CMAKE_SHARED_MODULE_${lang}_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_MODULE_CREATE_${lang}_FLAGS> -o <TARGET> ${CMAKE_GNULD_IMAGE_VERSION} <OBJECTS> <LINK_LIBRARIES>")
  set(CMAKE_${lang}_CREATE_SHARED_LIBRARY
    "<CMAKE_${lang}_COMPILER> <CMAKE_SHARED_LIBRARY_${lang}_FLAGS> <LANGUAGE_COMPILE_FLAGS> <LINK_FLAGS> <CMAKE_SHARED_LIBRARY_CREATE_${lang}_FLAGS> -o <TARGET> ${CMAKE_GNULD_IMAGE_VERSION} <OBJECTS> <LINK_LIBRARIES>")
  set(CMAKE_${lang}_LINK_EXECUTABLE
    "<CMAKE_${lang}_COMPILER> <FLAGS> <CMAKE_${lang}_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> ${CMAKE_GNULD_IMAGE_VERSION} <LINK_LIBRARIES>")
#  set(CMAKE_${lang}_LINK_EXECUTABLE
#    "<CMAKE_${lang}_COMPILER> <FLAGS> <CMAKE_${lang}_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET>.int ${CMAKE_GNULD_IMAGE_VERSION} <LINK_LIBRARIES> && ${CMAKE_OBJCOPY} -S -O binary <TARGET>.int <TARGET>")

  # Support very long lists of object files.
  # TODO: check for which gcc versions this is still needed, not needed for gcc >= 4.4.
  # Ninja generator doesn't support this work around.
  if("${CMAKE_${lang}_RESPONSE_FILE_LINK_FLAG}" STREQUAL "@" AND NOT CMAKE_GENERATOR MATCHES "Ninja")
    foreach(rule CREATE_SHARED_MODULE CREATE_SHARED_LIBRARY LINK_EXECUTABLE)
      # The gcc/collect2/ld toolchain does not use response files
      # internally so we cannot pass long object lists.  Instead pass
      # the object file list in a response file to the archiver to put
      # them in a temporary archive.  Hand the archive to the linker.
      string(REPLACE "<OBJECTS>" "-Wl,--whole-archive <OBJECT_DIR>/objects.a -Wl,--no-whole-archive"
        CMAKE_${lang}_${rule} "${CMAKE_${lang}_${rule}}")
      set(CMAKE_${lang}_${rule}
        "<CMAKE_COMMAND> -E rm -f <OBJECT_DIR>/objects.a"
        "<CMAKE_AR> qc <OBJECT_DIR>/objects.a <OBJECTS>"
        "${CMAKE_${lang}_${rule}}"
        )
    endforeach()
  endif()
endmacro()


macro(__cosmopolitan_compiler_gnu_abi lang)
endmacro()
