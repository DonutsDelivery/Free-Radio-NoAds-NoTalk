cmake_minimum_required(VERSION 3.18)
project(FreeradioPlugin LANGUAGES C CXX)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Qml Network)
find_package(PkgConfig REQUIRED)

# Enable automoc for Qt meta-object system
set(CMAKE_AUTOMOC ON)

# Find FFmpeg libraries for codec support
pkg_check_modules(FFMPEG REQUIRED libavformat libavcodec libavutil libswresample)

# Create the plugin library
add_library(freeradio_plugin SHARED 
    AudioEngine.cpp
    AudioEngine.h
)

target_include_directories(freeradio_plugin PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${FFMPEG_INCLUDE_DIRS}
)

target_link_libraries(freeradio_plugin PRIVATE 
    Qt6::Core 
    Qt6::Qml 
    Qt6::Network
    ${FFMPEG_LIBRARIES}
)

# Enable FFmpeg support in miniaudio
target_compile_definitions(freeradio_plugin PRIVATE
    MA_ENABLE_FFMPEG=1
    ${FFMPEG_CFLAGS_OTHER}
)

# Set up QML module
qt_add_qml_module(freeradio_plugin
    URI Freeradio
    VERSION 1.0
)

# Install to appropriate location
if(NOT DEFINED QML_INSTALL_DIR)
    set(QML_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/lib/qt6/qml)
endif()

install(TARGETS freeradio_plugin 
    DESTINATION ${QML_INSTALL_DIR}/Freeradio)

# Install qmldir file
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/qmldir 
    DESTINATION ${QML_INSTALL_DIR}/Freeradio)