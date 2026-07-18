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
find_package(PkgConfig REQUIRED)
pkg_check_modules(FFMPEG REQUIRED IMPORTED_TARGET
    libavformat libavcodec libavutil libswresample
)

# Find KDE Frameworks 6 Kirigami
find_package(KF6Kirigami REQUIRED)

# Find PulseAudio (Linux only - optional for cross-platform)
if(PkgConfig_FOUND)
    pkg_check_modules(PULSEAUDIO libpulse libpulse-simple)
endif()

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
    PRIVATE Qt6::Xml PkgConfig::FFMPEG
)
set_target_properties(freeradio_audioplugin PROPERTIES INSTALL_RPATH "$ORIGIN")

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

install(TARGETS freeradio_audio freeradio_audioplugin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/FreeRadio/Audio
    RUNTIME DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/FreeRadio/Audio
)
install(FILES ${CMAKE_BINARY_DIR}/qml/FreeRadio/Audio/qmldir
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/qt6/qml/FreeRadio/Audio
)

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
        FREERADIO_CMAKE_PATH="${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt"
    )
    add_dependencies(freeradio-qml-import-test freeradio_audioplugin)
    add_test(NAME freeradio-qml-import-test COMMAND freeradio-qml-import-test)
endif()
