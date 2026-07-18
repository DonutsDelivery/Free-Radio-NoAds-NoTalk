cmake_minimum_required(VERSION 3.21)

project(FreeRadioApp VERSION 2.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(ANDROID)
    set(QT_ANDROID_ABIS "arm64-v8a;x86_64" CACHE STRING
        "Android ABIs packaged by Free Radio" FORCE)
endif()

set(FREERADIO_QT_COMPONENTS Core Gui Qml Quick QuickControls2 Network Xml)
if(NOT ANDROID)
    list(APPEND FREERADIO_QT_COMPONENTS Widgets DBus)
endif()
find_package(Qt6 REQUIRED COMPONENTS ${FREERADIO_QT_COMPONENTS})
qt_policy(SET QTP0001 NEW)
if(NOT ANDROID)
    find_package(KF6Kirigami REQUIRED)
endif()

# Production builds fail closed: the custom in-process engine and pinned FFmpeg
# ABI are mandatory on every platform.
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../cmake")
find_package(FreeRadioFFmpeg 8.0.3 EXACT REQUIRED)
find_package(PkgConfig QUIET)

if(UNIX AND NOT APPLE AND NOT ANDROID AND PkgConfig_FOUND)
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
    PRIVATE Qt6::Xml FreeRadio::FFmpeg
)

# miniaudio links directly to each platform's native output APIs.
if(ANDROID)
    foreach(_library IN ITEMS android log OpenSLES)
        find_library(FREERADIO_${_library}_LIBRARY ${_library})
        if(NOT FREERADIO_${_library}_LIBRARY)
            message(FATAL_ERROR "Android platform library '${_library}' required by miniaudio was not found")
        endif()
        target_link_libraries(freeradio_audio PRIVATE ${FREERADIO_${_library}_LIBRARY})
    endforeach()
    target_link_libraries(freeradio_audio PRIVATE ${CMAKE_DL_LIBS})
elseif(WIN32)
    target_link_libraries(freeradio_audio PRIVATE ole32 winmm)
elseif(APPLE)
    foreach(_framework IN ITEMS CoreAudio AudioToolbox CoreFoundation)
        string(TOUPPER "${_framework}" _framework_upper)
        find_library(FREERADIO_${_framework_upper}_FRAMEWORK ${_framework})
        if(NOT FREERADIO_${_framework_upper}_FRAMEWORK)
            message(FATAL_ERROR "Apple framework '${_framework}' required by miniaudio was not found")
        endif()
        target_link_libraries(freeradio_audio PRIVATE ${FREERADIO_${_framework_upper}_FRAMEWORK})
    endforeach()
elseif(UNIX)
    find_package(Threads REQUIRED)
    target_link_libraries(freeradio_audio PRIVATE Threads::Threads ${CMAKE_DL_LIBS} m)
endif()

set(FREERADIO_SOURCES
    main.cpp
    AndroidMediaIntegration.cpp
    AndroidMediaIntegration.h
    AudioCapture.cpp
    AudioCapture.h
    SessionMonitor.cpp
    SessionMonitor.h
    resources.qrc
)
if(WIN32)
    list(APPEND FREERADIO_SOURCES freeradio.rc)
endif()

if(ANDROID)
    qt_add_executable(freeradio MANUAL_FINALIZATION ${FREERADIO_SOURCES})
else()
    add_executable(freeradio ${FREERADIO_SOURCES})
endif()

if(PULSEAUDIO_FOUND)
    add_executable(test-audio test_audio.cpp AudioCapture.cpp AudioCapture.h)
endif()

target_link_libraries(freeradio PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 freeradio_audio
)
if(NOT ANDROID)
    target_link_libraries(freeradio PRIVATE Qt6::Widgets Qt6::DBus KF6::Kirigami)
endif()
add_dependencies(freeradio freeradio_audioplugin)
target_compile_definitions(freeradio PRIVATE
    FREERADIO_AUDIO_CORE_AVAILABLE
    FREERADIO_BUILD_QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/qml"
)
if(ANDROID)
    set_property(TARGET freeradio PROPERTY QT_ANDROID_EXTRA_LIBS
        "${FREERADIO_AVFORMAT_LIBRARY};${FREERADIO_AVCODEC_LIBRARY};${FREERADIO_AVUTIL_LIBRARY};${FREERADIO_SWRESAMPLE_LIBRARY}")
endif()

if(PULSEAUDIO_FOUND)
    target_link_libraries(freeradio PRIVATE ${PULSEAUDIO_LIBRARIES})
    target_include_directories(freeradio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(freeradio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER} HAVE_PULSEAUDIO)
    target_link_libraries(test-audio PRIVATE Qt6::Core ${PULSEAUDIO_LIBRARIES})
    target_include_directories(test-audio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(test-audio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER})
endif()

set_target_properties(freeradio PROPERTIES
    QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml
    WIN32_EXECUTABLE $<NOT:$<CONFIG:Debug>>
    MACOSX_BUNDLE TRUE
)

if(ANDROID)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    set(FREERADIO_ANDROID_PACKAGE_DIR "${CMAKE_CURRENT_BINARY_DIR}/android-package")
    file(REMOVE_RECURSE "${FREERADIO_ANDROID_PACKAGE_DIR}")
    file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/android/" DESTINATION "${FREERADIO_ANDROID_PACKAGE_DIR}")
    execute_process(
        COMMAND "${Python3_EXECUTABLE}"
                "${CMAKE_CURRENT_SOURCE_DIR}/android/generate_network_security_config.py"
                --output "${FREERADIO_ANDROID_PACKAGE_DIR}/res/xml/network_security_config.xml"
                "${CMAKE_CURRENT_SOURCE_DIR}/catalog/radiodata.json"
        RESULT_VARIABLE FREERADIO_NETWORK_POLICY_RESULT
        OUTPUT_VARIABLE FREERADIO_NETWORK_POLICY_OUTPUT
        ERROR_VARIABLE FREERADIO_NETWORK_POLICY_ERROR
    )
    if(NOT FREERADIO_NETWORK_POLICY_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to generate Android network policy: ${FREERADIO_NETWORK_POLICY_ERROR}")
    endif()
    message(STATUS "${FREERADIO_NETWORK_POLICY_OUTPUT}")

    set_target_properties(freeradio PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${FREERADIO_ANDROID_PACKAGE_DIR}"
        QT_ANDROID_PACKAGE_NAME "org.freeradio.app"
        QT_ANDROID_MIN_SDK_VERSION 26
        QT_ANDROID_TARGET_SDK_VERSION 35
        QT_ANDROID_VERSION_CODE 20000
        QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
    )
    qt_finalize_executable(freeradio)
endif()

include(GNUInstallDirs)
install(TARGETS freeradio
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    BUNDLE DESTINATION .
)
if(NOT ANDROID)
    install(FILES freeradio.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    install(FILES icons/freeradio.svg DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
endif()

if(ANDROID)
    set(FREERADIO_QML_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml/FreeRadio/Audio")
elseif(APPLE)
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
install(FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/../LICENSES/FFmpeg-LGPL-2.1-or-later.txt
    ${CMAKE_CURRENT_SOURCE_DIR}/../LICENSES/FFmpeg-NOTICE.txt
    DESTINATION ${CMAKE_INSTALL_DATADIR}/licenses/freeradio
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
        FREERADIO_REPOSITORY_PATH="${CMAKE_CURRENT_SOURCE_DIR}/.."
    )
    add_dependencies(freeradio-qml-import-test freeradio_audioplugin)
    add_test(NAME freeradio-qml-import-test COMMAND freeradio-qml-import-test)
    add_test(NAME freeradio-app-qml-import-smoke COMMAND freeradio --audio-qml-smoke)
    set_tests_properties(freeradio-app-qml-import-smoke PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endif()
