# Locate the exact FFmpeg build supported by Free Radio.
#
# Providers are deliberately explicit; this module never searches arbitrary library
# paths or downloads dependencies while configuring the application.
#
#   FREERADIO_FFMPEG_PROVIDER=PKGCONFIG (default on desktop)
#   FREERADIO_FFMPEG_PROVIDER=EXPLICIT  (required for Android/package staging)
#
# EXPLICIT requires FREERADIO_FFMPEG_INCLUDE_DIR and all four
# FREERADIO_*_LIBRARY cache entries below.

include_guard(GLOBAL)
include(FindPackageHandleStandardArgs)

set(FREERADIO_FFMPEG_VERSION_REQUIRED "8.0.3")
set(FREERADIO_FFMPEG_PROVIDER "PKGCONFIG" CACHE STRING
    "FFmpeg provider: PKGCONFIG or EXPLICIT")
set_property(CACHE FREERADIO_FFMPEG_PROVIDER PROPERTY STRINGS PKGCONFIG EXPLICIT)
string(TOUPPER "${FREERADIO_FFMPEG_PROVIDER}" _fr_ffmpeg_provider)
if(NOT _fr_ffmpeg_provider MATCHES "^(PKGCONFIG|EXPLICIT)$")
    message(FATAL_ERROR
        "FREERADIO_FFMPEG_PROVIDER must be PKGCONFIG or EXPLICIT (got '${FREERADIO_FFMPEG_PROVIDER}')")
endif()

set(FREERADIO_FFMPEG_INCLUDE_DIR "" CACHE PATH "Directory containing FFmpeg headers")
set(FREERADIO_AVFORMAT_LIBRARY "" CACHE FILEPATH "Exact path to libavformat")
set(FREERADIO_AVCODEC_LIBRARY "" CACHE FILEPATH "Exact path to libavcodec")
set(FREERADIO_AVUTIL_LIBRARY "" CACHE FILEPATH "Exact path to libavutil")
set(FREERADIO_SWRESAMPLE_LIBRARY "" CACHE FILEPATH "Exact path to libswresample")

function(_fr_ffmpeg_read_version include_dir output)
    set(_version_header "${include_dir}/libavutil/ffversion.h")
    if(NOT EXISTS "${_version_header}")
        message(FATAL_ERROR
            "FFmpeg version header not found: ${_version_header}. Free Radio requires FFmpeg ${FREERADIO_FFMPEG_VERSION_REQUIRED} exactly.")
    endif()
    file(STRINGS "${_version_header}" _version_line
        REGEX "^[ \t]*#define[ \t]+FFMPEG_VERSION[ \t]+\"")
    if(NOT _version_line)
        message(FATAL_ERROR "Could not read FFMPEG_VERSION from ${_version_header}")
    endif()
    string(REGEX MATCH "FFMPEG_VERSION[ \t]+\"([^\"]+)\"" _match "${_version_line}")
    set(_version "${CMAKE_MATCH_1}")
    if(NOT _version STREQUAL FREERADIO_FFMPEG_VERSION_REQUIRED)
        message(FATAL_ERROR
            "Unsupported FFmpeg version '${_version}' in ${_version_header}; exact version ${FREERADIO_FFMPEG_VERSION_REQUIRED} is required")
    endif()
    set(${output} "${_version}" PARENT_SCOPE)
endfunction()

function(_fr_ffmpeg_check_header_major include_dir component expected)
    string(TOUPPER "${component}" _component_upper)
    set(_header "${include_dir}/lib${component}/version_major.h")
    if(NOT EXISTS "${_header}")
        set(_header "${include_dir}/lib${component}/version.h")
    endif()
    if(NOT EXISTS "${_header}")
        message(FATAL_ERROR "Missing FFmpeg component version header for lib${component}")
    endif()
    file(STRINGS "${_header}" _major_line
        REGEX "^[ \t]*#define[ \t]+LIB${_component_upper}_VERSION_MAJOR[ \t]+[0-9]+")
    string(REGEX MATCH "[0-9]+$" _major "${_major_line}")
    if(NOT _major STREQUAL "${expected}")
        message(FATAL_ERROR
            "lib${component} ABI major is '${_major}', expected '${expected}' for FFmpeg ${FREERADIO_FFMPEG_VERSION_REQUIRED}")
    endif()
endfunction()

function(_fr_ffmpeg_validate_headers include_dir)
    _fr_ffmpeg_read_version("${include_dir}" _version)
    _fr_ffmpeg_check_header_major("${include_dir}" avformat 62)
    _fr_ffmpeg_check_header_major("${include_dir}" avcodec 62)
    _fr_ffmpeg_check_header_major("${include_dir}" avutil 60)
    _fr_ffmpeg_check_header_major("${include_dir}" swresample 6)
    set(FreeRadioFFmpeg_VERSION "${_version}" PARENT_SCOPE)
endfunction()

if(_fr_ffmpeg_provider STREQUAL "PKGCONFIG")
    if(ANDROID)
        message(FATAL_ERROR
            "Android must use FREERADIO_FFMPEG_PROVIDER=EXPLICIT so host pkg-config libraries cannot leak into the APK")
    endif()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(FR_AVFORMAT REQUIRED IMPORTED_TARGET libavformat)
    pkg_check_modules(FR_AVCODEC REQUIRED IMPORTED_TARGET libavcodec)
    pkg_check_modules(FR_AVUTIL REQUIRED IMPORTED_TARGET libavutil)
    pkg_check_modules(FR_SWRESAMPLE REQUIRED IMPORTED_TARGET libswresample)

    set(_fr_include_candidates ${FR_AVUTIL_INCLUDE_DIRS} ${FR_AVFORMAT_INCLUDE_DIRS})
    list(REMOVE_DUPLICATES _fr_include_candidates)
    set(_fr_version_include "")
    foreach(_include IN LISTS _fr_include_candidates)
        if(EXISTS "${_include}/libavutil/ffversion.h")
            set(_fr_version_include "${_include}")
            break()
        endif()
    endforeach()
    if(NOT _fr_version_include)
        message(FATAL_ERROR "pkg-config did not provide headers containing libavutil/ffversion.h")
    endif()
    _fr_ffmpeg_validate_headers("${_fr_version_include}")

    foreach(_component IN ITEMS avformat avcodec avutil swresample)
        string(TOUPPER "${_component}" _upper)
        if(_component STREQUAL "swresample")
            set(_pkg_target PkgConfig::FR_SWRESAMPLE)
        else()
            set(_pkg_target PkgConfig::FR_${_upper})
        endif()
        add_library(FreeRadio::${_component} INTERFACE IMPORTED)
        set_property(TARGET FreeRadio::${_component} PROPERTY
            INTERFACE_LINK_LIBRARIES ${_pkg_target})
    endforeach()
else()
    set(_fr_explicit_values
        FREERADIO_FFMPEG_INCLUDE_DIR
        FREERADIO_AVFORMAT_LIBRARY
        FREERADIO_AVCODEC_LIBRARY
        FREERADIO_AVUTIL_LIBRARY
        FREERADIO_SWRESAMPLE_LIBRARY)
    foreach(_variable IN LISTS _fr_explicit_values)
        if(NOT ${_variable})
            message(FATAL_ERROR "${_variable} is required for the EXPLICIT FFmpeg provider")
        endif()
        if(NOT IS_ABSOLUTE "${${_variable}}")
            message(FATAL_ERROR "${_variable} must be an absolute path: ${${_variable}}")
        endif()
        if(NOT EXISTS "${${_variable}}")
            message(FATAL_ERROR "${_variable} does not exist: ${${_variable}}")
        endif()
    endforeach()
    _fr_ffmpeg_validate_headers("${FREERADIO_FFMPEG_INCLUDE_DIR}")

    foreach(_component IN ITEMS avformat avcodec avutil swresample)
        string(TOUPPER "${_component}" _upper)
        set(_location "${FREERADIO_${_upper}_LIBRARY}")
        if(ANDROID)
            get_filename_component(_filename "${_location}" NAME)
            if(NOT _filename STREQUAL "lib${_component}.so")
                message(FATAL_ERROR
                    "Android FFmpeg libraries must have unversioned names/SONAME staging; expected lib${_component}.so, got ${_filename}")
            endif()
        endif()
        add_library(FreeRadio::${_component} SHARED IMPORTED)
        set_target_properties(FreeRadio::${_component} PROPERTIES
            IMPORTED_LOCATION "${_location}"
            INTERFACE_INCLUDE_DIRECTORIES "${FREERADIO_FFMPEG_INCLUDE_DIR}")
    endforeach()
endif()

add_library(FreeRadio::FFmpeg INTERFACE IMPORTED)
set_property(TARGET FreeRadio::FFmpeg PROPERTY INTERFACE_LINK_LIBRARIES
    "FreeRadio::avformat;FreeRadio::avcodec;FreeRadio::avutil;FreeRadio::swresample")

set(FreeRadioFFmpeg_PROVIDER "${_fr_ffmpeg_provider}")
set(FreeRadioFFmpeg_FOUND TRUE)
find_package_handle_standard_args(FreeRadioFFmpeg
    REQUIRED_VARS FreeRadioFFmpeg_FOUND
    VERSION_VAR FreeRadioFFmpeg_VERSION
    REASON_FAILURE_MESSAGE "Install/provision exact LGPL FFmpeg ${FREERADIO_FFMPEG_VERSION_REQUIRED}")
