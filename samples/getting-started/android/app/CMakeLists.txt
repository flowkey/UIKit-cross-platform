cmake_minimum_required(VERSION 3.16)
project(DemoApp)

get_filename_component(PROJECT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/../../ ABSOLUTE)
#file(GLOB_RECURSE SOURCE_FILES "${PROJECT_DIRECTORY}/*.swift" "${PROJECT_DIRECTORY}/*.c" "${PROJECT_DIRECTORY}/*.cpp")
set(OUTPUT_LIBS "${PROJECT_DIRECTORY}/android/app/src/main/jniLibs/${ANDROID_ABI}/libDemoApp.so")

set(BuildSwiftProject_DIR ../../../../swift-android-toolchain)
find_package(BuildSwiftProject REQUIRED)

build_swift_project(
    PROJECT_DIRECTORY ${PROJECT_DIRECTORY}
    #SOURCE_FILES ${SOURCE_FILES}
    OUTPUT_LIBS ${OUTPUT_LIBS}
)