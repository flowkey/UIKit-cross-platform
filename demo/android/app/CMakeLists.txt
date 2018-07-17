cmake_minimum_required(VERSION 3.6)

set(UIKit_DIR ../../../)
find_package(UIKit REQUIRED)

add_swiftpm_library(DemoApp
    PROJECT_DIRECTORY ../..
    PROJECT_DEPENDENCIES UIKit
)
