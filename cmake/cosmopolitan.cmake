# Distributed under the OSI-approved BSD 3-Clause License.

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Modules")
set(CMAKE_SYSTEM_NAME "Cosmopolitan")

find_program(CMAKE_C_COMPILER NAMES gcc)
find_program(CMAKE_OBJCOPY NAMES objcopy)

set(COSMOPOLITAN_ROOT "$ENV{COSMOPOLITAN_ROOT}")

if(NOT COSMOPOLITAN_ROOT)
    message(FATAL_ERROR "COSMOPOLITAN_ROOT not set")
endif()

set(CMAKE_C_FLAGS_INIT "-static -fno-pie -no-pie -nostdlib -nostdinc -isystem \"${COSMOPOLITAN_ROOT}\" -include \"${COSMOPOLITAN_ROOT}/cosmopolitan.h\"")
string(APPEND CMAKE_C_FLAGS_INIT " -fno-omit-frame-pointer -pg -mnop-mcount -mno-tls-direct-seg-refs")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,--gc-sections -fuse-ld=bfd -Wl,--gc-sections")
string(APPEND CMAKE_EXE_LINKER_FLAGS_INIT " -Wl,-T,\"${COSMOPOLITAN_ROOT}/ape.lds\" \"${COSMOPOLITAN_ROOT}/crt.o\" \"${COSMOPOLITAN_ROOT}/ape-no-modify-self.o\"")

if(NOT _cosmopolitan_add_executable_defined)
    set(_cosmopolitan_add_executable_defined 1)
    define_property(TARGET
        PROPERTY COSMOPOLITAN_OUTPUT_NAME
        BRIEF_DOCS "Cosmopolitan output"
        FULL_DOCS "Cosmopolitan output"
    )

    function(add_executable TARGET)
        _add_executable(${TARGET} ${ARGN})
        set(cosmo_prop "$<TARGET_PROPERTY:${TARGET},COSMOPOLITAN_OUTPUT_NAME>")
        set(cosmo_prop_not_defined "$<STREQUAL:${cosmo_prop},>")
        set(cosmo_out "$<TARGET_FILE_DIR:${TARGET}>/$<TARGET_FILE_PREFIX:${TARGET}>${cosmo_prop}$<TARGET_FILE_SUFFIX:${TARGET}>")
        set(normal_out "$<TARGET_FILE:${TARGET}>")
        set(outfilename "$<IF:${cosmo_prop_not_defined},${normal_out},${cosmo_out}>")
        add_custom_command(TARGET "${TARGET}" POST_BUILD
            COMMAND "${CMAKE_OBJCOPY}" -S -O binary "$<TARGET_FILE:${TARGET}>" "${outfilename}"

        )
    endfunction()
endif()
