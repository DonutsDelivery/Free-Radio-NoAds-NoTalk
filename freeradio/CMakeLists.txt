cmake_minimum_required(VERSION 3.16)

project(DonutRadio VERSION 2.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable Qt's MOC and automatic handling
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find required Qt components
find_package(Qt6 REQUIRED COMPONENTS Core Widgets Qml Quick QuickControls2 Multimedia DBus)

# Find KDE Frameworks 6 Kirigami
find_package(KF6Kirigami REQUIRED)

# Find PulseAudio (Linux only - optional for cross-platform)
find_package(PkgConfig)
if(PkgConfig_FOUND)
    pkg_check_modules(PULSEAUDIO libpulse libpulse-simple)
endif()

# Add executables
set(DONUTRADIO_SOURCES
    main.cpp
    AudioCapture.cpp
    AudioCapture.h
    SessionMonitor.cpp
    SessionMonitor.h
    resources.qrc
)

# Add Windows icon resource
if(WIN32)
    list(APPEND DONUTRADIO_SOURCES donutradio.rc)
endif()

add_executable(donutradio ${DONUTRADIO_SOURCES})

# Optional test executable
if(PULSEAUDIO_FOUND)
    add_executable(test-audio
        test_audio.cpp
        AudioCapture.cpp
        AudioCapture.h
    )
endif()

# Link Qt and Kirigami libraries
target_link_libraries(donutradio PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::DBus
    KF6::Kirigami
)

# Optional PulseAudio support
if(PULSEAUDIO_FOUND)
    target_link_libraries(donutradio PRIVATE ${PULSEAUDIO_LIBRARIES})
    target_include_directories(donutradio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(donutradio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER} HAVE_PULSEAUDIO)

    target_link_libraries(test-audio PRIVATE
        Qt6::Core
        Qt6::Multimedia
        ${PULSEAUDIO_LIBRARIES}
    )
    target_include_directories(test-audio PRIVATE ${PULSEAUDIO_INCLUDE_DIRS})
    target_compile_definitions(test-audio PRIVATE ${PULSEAUDIO_CFLAGS_OTHER})
endif()

# Set output directory for QML modules
set_target_properties(donutradio PROPERTIES
    QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml
    # GUI subsystem (no console window) for all builds EXCEPT Debug.
    # Debug builds keep the console so qDebug()/console.log output is visible.
    WIN32_EXECUTABLE $<NOT:$<CONFIG:Debug>>
    MACOSX_BUNDLE TRUE
)

# Installation rules
include(GNUInstallDirs)

set(DONUTRADIO_APP_ID online.donutsdelivery.DonutRadio)
set(DONUTRADIO_PLASMOID_ID online.donutsdelivery.donutradio)

install(TARGETS donutradio
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    BUNDLE DESTINATION .
)

if(NOT WIN32 AND NOT APPLE)
    install(FILES ${DONUTRADIO_APP_ID}.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
    )

    install(FILES ${DONUTRADIO_APP_ID}.metainfo.xml
        DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo
    )

    # Icon theme tree: scalable SVG plus 16 to 512 px PNGs, all named after the app ID.
    install(DIRECTORY icons/hicolor
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons
    )

    # The Plasma widget shares the QML sources with the app. Turn this off for
    # AppImage staging, where a plasmoid directory would be dead weight.
    option(DONUTRADIO_INSTALL_PLASMOID "Install the Plasma 6 widget" ON)
    if(DONUTRADIO_INSTALL_PLASMOID)
        install(FILES metadata.json
            DESTINATION ${CMAKE_INSTALL_DATADIR}/plasma/plasmoids/${DONUTRADIO_PLASMOID_ID}
        )
        install(DIRECTORY contents
            DESTINATION ${CMAKE_INSTALL_DATADIR}/plasma/plasmoids/${DONUTRADIO_PLASMOID_ID}
            PATTERN "*.backup" EXCLUDE
        )
    endif()
endif()
