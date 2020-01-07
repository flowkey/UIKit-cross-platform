cmake_minimum_required(VERSION 3.16.2)
project(DemoApp)

message(STATUS "BUILDING ${ANDROID_ABI} ${CMAKE_BUILD_TYPE}")

set(PROJECT_DIRECTORY "/Users/michaelknoch/dev/flow/smartphone-app/RNPlayerComponent/NativePlayer/UIKit/samples/getting-started/DemoApp")
set(PRODUCT_NAME "lol")

file(GLOB_RECURSE SOURCE_FILES "${PROJECT_DIRECTORY}/*.swift" "${PROJECT_DIRECTORY}/*.c" "${PROJECT_DIRECTORY}/*.cpp")

message("YOLLO")
message(STATUS "${SOURCE_FILES}")

add_custom_command(
    OUTPUT ./android/app/src/main/jniLibs/x86_64/libDemoApp.so
    COMMAND "../../go.sh" "${ANDROID_ABI}"
    DEPENDS ${SOURCE_FILES}
    WORKING_DIRECTORY ${PROJECT_DIRECTORY}
    COMMENT "Compiling ${PRODUCT_NAME}. If this worked before and you now get an error saying 'xyz.swift was not found', run 'Build->Refresh Linked C++ Projects' in Android Studio." # or run CMake again
    VERBATIM
)

message(STATUS "DONE")