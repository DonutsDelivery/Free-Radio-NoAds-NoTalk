cmake_minimum_required(VERSION 3.16)

project(FreeRadioApp VERSION 2.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable Qt's MOC and automatic handling
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find required Qt components
find_package(Qt6 REQUIRED COMPONENTS Core Widgets Qml Quick QuickControls2 DBus Network Xml)
qt_policy(SET QTP0001 NEW)
find_package(PkgConfig QUIET)
set(FREERADIO_AUDIO_CORE_MODE "AUTO" CACHE STRING "Audio core mode: AUTO, REQUIRED, or OFF")
set_property(CACHE FREERADIO_AUDIO_CORE_MODE PROPERTY STRINGS AUTO REQUIRED OFF)
option(FREERADIO_APP_REQUIRES_AUDIO_CORE "Fail configure when the app QML requires FreeRadio.Audio" ON)
set(FREERADIO_FFMPEG_INCLUDE_DIR "" CACHE PATH "FFmpeg include directory for non-pkg-config builds")
set(FREERADIO_AVFORMAT_LIBRARY "" CACHE FILEPATH "Path to libavformat")
set(FREERADIO_AVCODEC_LIBRARY "" CACHE FILEPATH "Path to libavcodec")
set(FREERADIO_AVUTIL_LIBRARY "" CACHE FILEPATH "Path to libavutil")
set(FREERADIO_SWRESAMPLE_LIBRARY "" CACHE FILEPATH "Path to libswresample")

if(NOT FREERADIO_AUDIO_CORE_MODE MATCHES "^(AUTO|REQUIRED|OFF)$")
    message(FATAL_ERROR "FREERADIO_AUDIO_CORE_MODE must be AUTO, REQUIRED, or OFF")
endif()
set(FREERADIO_AUDIO_CORE_AVAILABLE OFF)
set(FREERADIO_FFMPEG_TARGET "")
if(NOT FREERADIO_AUDIO_CORE_MODE STREQUAL "OFF")
    if(FREERADIO_FFMPEG_INCLUDE_DIR AND FREERADIO_AVFORMAT_LIBRARY
       AND FREERADIO_AVCODEC_LIBRARY AND FREERADIO_AVUTIL_LIBRARY
       AND FREERADIO_SWRESAMPLE_LIBRARY)
        add_library(freeradio_ffmpeg INTERFACE)
        target_include_directories(freeradio_ffmpeg INTERFACE ${FREERADIO_FFMPEG_INCLUDE_DIR})
        target_link_libraries(freeradio_ffmpeg INTERFACE
            ${FREERADIO_AVFORMAT_LIBRARY} ${FREERADIO_AVCODEC_LIBRARY}
            ${FREERADIO_AVUTIL_LIBRARY} ${FREERADIO_SWRESAMPLE_LIBRARY}
        )
        set(FREERADIO_FFMPEG_TARGET freeradio_ffmpeg)
        set(FREERADIO_AUDIO_CORE_AVAILABLE ON)
    elseif(PkgConfig_FOUND)
        pkg_check_modules(FFMPEG QUIET IMPORTED_TARGET
            libavformat libavcodec libavutil libswresample
        )
        if(FFMPEG_FOUND)
            set(FREERADIO_FFMPEG_TARGET PkgConfig::FFMPEG)
            set(FREERADIO_AUDIO_CORE_AVAILABLE ON)
        endif()
    endif()
endif()
if((FREERADIO_AUDIO_CORE_MODE STREQUAL "REQUIRED" OR FREERADIO_APP_REQUIRES_AUDIO_CORE)
   AND NOT FREERADIO_AUDIO_CORE_AVAILABLE)
    message(FATAL_ERROR "FreeRadio.Audio is required but FFmpeg was not found. Provide pkg-config metadata or all FREERADIO_*_LIBRARY and FREERADIO_FFMPEG_INCLUDE_DIR cache paths.")
elseif(FREERADIO_AUDIO_CORE_MODE STREQUAL "AUTO" AND NOT FREERADIO_AUDIO_CORE_AVAILABLE)
    message(WARNING "FreeRadio.Audio is unavailable. Current QML may build, but set FREERADIO_APP_REQUIRES_AUDIO_CORE=ON when migrating playback so missing runtime imports fail at configure time.")
endif()

# Find KDE Frameworks 6 Kirigami
find_package(KF6Kirigami REQUIRED)

# Find PulseAudio (Linux only - optional for cross-platform)
if(PkgConfig_FOUND)
    pkg_check_modules(PULSEAUDIO libpulse libpulse-simple)
endif()

if(FREERADIO_AUDIO_CORE_AVAILABLE)
    qt_add_qml_module(freeradio_audio
        SHARED
        URI FreeRadio.Audio
        VERSION 1.0
        OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/FreeRadio/Audio
        SOURCES
            src/audio/AudioEngine.cpp
            src/audio/AudioEngine.h
            src/audio/IcyDemuxer.cpp
            src/audio/IcyDemuxer.h
            src/audio/NetworkBuffer.cpp
            src/audio/NetworkBuffer.h
            src/audio/PcmRingBuffer.h
            src/audio/PlaylistParser.cpp
            src/audio/PlaylistParser.h
            src/audio/SpectrumAnalyzer.cpp
            src/audio/SpectrumAnalyzer.h
    )
    target_include_directories(freeradio_audio PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/src/audio
    )
    target_link_libraries(freeradio_audio
        PUBLIC Qt6::Core Qt6::Network Qt6::Qml
        PRIVATE Qt6::Xml ${FREERADIO_FFMPEG_TARGET}
    )
endif()

# Add executables
set(FREERADIO_SOURCES
    main.cpp
    AudioCapture.cpp
    AudioCapture.h
    SessionMonitor.cpp
    SessionMonitor.h
    resources.qrc
)

# Add Windows icon resource
if(WIN32)
    list(APPEND FREERADIO_SOURCES freeradio.rc)
endif()

add_executable(freeradio ${FREERADIO_SOURCES})

# Optional test executable
if(PULSEAUDIO_FOUND)
    add_executable(test-audio
        test_audio.cpp
        AudioCapture.cpp
        AudioCapture.h
    )
endif()

# Link Qt and Kirigami libraries
target_link_libraries(freeradio PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
    KF6::Kirigami
    freeradio_audio
)
if(FREERADIO_AUDIO_CORE_AVAILABLE)
    add_dependencies(freeradio freeradio_audioplugin)
    target_compile_definitions(freeradio PRIVATE
        FREERADIO_AUDIO_CORE_AVAILABLE
        FREERADIO_BUILD_QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/qml"
    )
endif()

# Optional PulseAudio support
if(PULSEAUDIO_FOUND)
    target_link_libraries(freeradio PRIVATE ${PULSEAUDIO_LIBRARIES})
    target_include_directories(freeradio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(freeradio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER} HAVE_PULSEAUDIO)

    target_link_libraries(test-audio PRIVATE
        Qt6::Core
        ${PULSEAUDIO_LIBRARIES}
    )
    target_include_directories(test-audio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(test-audio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER})
endif()

# Set output directory for QML modules
set_target_properties(freeradio PROPERTIES
    QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml
    # GUI subsystem (no console window) for all builds EXCEPT Debug.
    # Debug builds keep the console so qDebug()/console.log output is visible.
    WIN32_EXECUTABLE $<NOT:$<CONFIG:Debug>>
    MACOSX_BUNDLE TRUE
)

# Installation rules
include(GNUInstallDirs)

install(TARGETS freeradio
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    BUNDLE DESTINATION .
)

install(FILES freeradio.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

install(FILES icons/freeradio.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
)

if(FREERADIO_AUDIO_CORE_AVAILABLE)
    if(APPLE)
        set(FREERADIO_QML_INSTALL_DIR "freeradio.app/Contents/Resources/qml/FreeRadio/Audio")
        set_target_properties(freeradio_audioplugin PROPERTIES INSTALL_RPATH "@loader_path")
    elseif(WIN32)
        set(FREERADIO_QML_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}/qml/FreeRadio/Audio")
    else()
        set(FREERADIO_QML_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml/FreeRadio/Audio")
        set_target_properties(freeradio_audioplugin PROPERTIES INSTALL_RPATH "$ORIGIN")
    endif()
    install(TARGETS freeradio_audio freeradio_audioplugin
        LIBRARY DESTINATION ${FREERADIO_QML_INSTALL_DIR}
        RUNTIME DESTINATION ${FREERADIO_QML_INSTALL_DIR}
    )
    install(FILES ${CMAKE_BINARY_DIR}/qml/FreeRadio/Audio/qmldir
        DESTINATION ${FREERADIO_QML_INSTALL_DIR}
    )
endif()

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    add_executable(freeradio-audio-tests tests/audio/AudioCoreTest.cpp)
    target_link_libraries(freeradio-audio-tests PRIVATE freeradio_audio Qt6::Test Qt6::Network)
    add_test(NAME freeradio-audio-tests COMMAND freeradio-audio-tests)

    add_executable(freeradio-qml-import-test tests/audio/QmlImportTest.cpp)
    target_link_libraries(freeradio-qml-import-test PRIVATE Qt6::Test Qt6::Qml)
    target_compile_definitions(freeradio-qml-import-test PRIVATE
        FREERADIO_QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/qml"
        FREERADIO_UI_PATH="${CMAKE_CURRENT_SOURCE_DIR}/contents/ui"
        FREERADIO_REPOSITORY_PATH="${CMAKE_CURRENT_SOURCE_DIR}/.."
    )
    add_dependencies(freeradio-qml-import-test freeradio_audioplugin)
    add_test(NAME freeradio-qml-import-test COMMAND freeradio-qml-import-test)
    add_test(NAME freeradio-app-qml-import-smoke COMMAND freeradio --audio-qml-smoke)
    set_tests_properties(freeradio-app-qml-import-smoke PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
    )
endif()
