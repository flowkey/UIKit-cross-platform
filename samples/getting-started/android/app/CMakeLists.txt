cmake_minimum_required(VERSION 3.6)
project(DemoApp)

get_filename_component(PROJECT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/../../ ABSOLUTE)

set(BuildSwiftProject_DIR ../../../../swift-android-toolchain)
find_package(BuildSwiftProject REQUIRED)

build_swift_project(
    PROJECT_DIRECTORY ${PROJECT_DIRECTORY}
)