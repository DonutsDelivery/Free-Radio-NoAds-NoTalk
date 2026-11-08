cmake_minimum_required(VERSION 3.16)
project(DonutRadio VERSION 2.0.0)

# The app and the Plasma widget both live in freeradio/. The freeradio-panel and
# freeradio-remote directories are plain plasmoid packages with no CMake project.
add_subdirectory(freeradio)
