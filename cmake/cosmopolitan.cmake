# Distributed under the OSI-approved BSD 3-Clause License.

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Modules")
set(CMAKE_SYSTEM_NAME "Cosmopolitan")

set(COSMO_ROOT "$ENV{COSMO}")

find_program(CMAKE_C_COMPILER NAMES "${COSMO_ROOT}/tool/scripts/cosmocc")
find_program(CMAKE_CXX_COMPILER NAMES "${COSMO_ROOT}/tool/scripts/cosmoc++")
find_program(CMAKE_OBJCOPY NAMES objcopy)

if(NOT COSMO_ROOT)
    message(FATAL_ERROR "COSMO environment variable not set")
endif()

#set(CMAKE_C_FLAGS_INIT "-static -fno-pie -no-pie -nostdlib -nostdinc -isystem \"${COSMO_ROOT}\" -include \"${COSMO_ROOT}/cosmopolitan.h\"")
#string(APPEND CMAKE_C_FLAGS_INIT " -fno-omit-frame-pointer -pg -mnop-mcount -mno-tls-direct-seg-refs")

#set(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,--gc-sections -fuse-ld=bfd -Wl,--gc-sections")
#string(APPEND CMAKE_EXE_LINKER_FLAGS_INIT " -Wl,-T,\"${COSMO_ROOTCOSMO_ROOT}/ape.lds\" \"${COSMO_ROOT}/crt.o\" \"${COSMO_ROOT}/ape-no-modify-self.o\"")

if(NOT _cosmopolitan_add_executable_defined)
    set(_cosmopolitan_add_executable_defined 1)
    define_property(TARGET
        PROPERTY COSMOPOLITAN_DEBUG_SUFFIX
        BRIEF_DOCS "Cosmopolitan suffix"
        FULL_DOCS "Cosmopolitan suffix"
    )

    set(COSMOPOLITAN_DEBUG_SUFFIX_DEFAULT ".dbg")

    function(add_executable TARGET)
        _add_executable(${TARGET} ${ARGN})
        set_propertY(TARGET ${TARGET} PROPERTY SUFFIX ".com")
        set_propertY(TARGET ${TARGET} PROPERTY COSMOPOLITAN_DEBUG_SUFFIX "${COSMOPOLITAN_DEBUG_SUFFIX_DEFAULT}")
        get_property(_target_type TARGET ${TARGET} PROPERTY TYPE)
        get_property(_target_imported TARGET ${TARGET} PROPERTY IMPORTED)
        if(_target_type STREQUAL "EXECUTABLE" AND NOT _target_imported)
            set(cosmo_directory "$<TARGET_FILE_DIR:${TARGET}>")
            set(cosmo_nodebug_file_name "$<TARGET_FILE_NAME:${TARGET}>")
            set(cosmo_debug_file_name "${cosmo_nodebug_file_name}$<TARGET_PROPERTY:${TARGET},COSMOPOLITAN_DEBUG_SUFFIX>")

            set(outfilename "${cosmo_directory}/${cosmo_prefix}${name_out}${cosmo_suffix}")
            add_custom_command(TARGET "${TARGET}" POST_BUILD
                COMMAND "${CMAKE_COMMAND}" ARGS -E rename "${cosmo_nodebug_file_name}" "${cosmo_debug_file_name}"
                COMMAND "${CMAKE_OBJCOPY}" ARGS -S -O binary "${cosmo_debug_file_name}" "${cosmo_nodebug_file_name}"
            )
            set_property(TARGET ${TARGET} APPEND PROPERTY ADDITIONAL_CLEAN_FILES "${cosmo_debug_file_name}")
        endif()
    endfunction()
endif()
