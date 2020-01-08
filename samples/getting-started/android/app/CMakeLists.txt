cmake_minimum_required(VERSION 3.16)
project(DemoApp)

message(STATUS "CMakeLists.txt ${ANDROID_ABI} ${CMAKE_BUILD_TYPE}")

set(PROJECT_DIRECTORY "/Users/michaelknoch/dev/flow/smartphone-app/RNPlayerComponent/NativePlayer/UIKit/samples/getting-started/DemoApp")

file(GLOB_RECURSE SOURCE_FILES "${PROJECT_DIRECTORY}/*.swift" "${PROJECT_DIRECTORY}/*.c" "${PROJECT_DIRECTORY}/*.cpp")
set(OUTPUT_LIBS "/Users/michaelknoch/dev/flow/smartphone-app/RNPlayerComponent/NativePlayer/UIKit/samples/getting-started/android/app/src/main/jniLibs/${ANDROID_ABI}/libDemoApp.so")

add_custom_command(
    OUTPUT ${OUTPUT_LIBS}
    COMMAND "/Users/michaelknoch/dev/flow/smartphone-app/RNPlayerComponent/NativePlayer/UIKit/samples/getting-started/go.sh" "${ANDROID_ABI}"
    DEPENDS ${SOURCE_FILES}
    VERBATIM
)

add_custom_target(unusedRandomTarget ALL
    DEPENDS ${OUTPUT_LIBS}
    VERBATIM
)

# Android Studio annoyingly only builds targets created by "add_library".
# As a workaround we create an empty library target and link it to every SwiftPM
# target we define, causing the linked targets to be be built and packaged in the APK.
# As a downside we end up with a libswiftPMBuildDummy.so, but it only adds ~1kb to the APK.
file(WRITE .empty.c "") # we need to build *something*, even if it's an empty file
add_library(swiftPMBuildDummy SHARED .empty.c)
add_dependencies(swiftPMBuildDummy unusedRandomTarget)