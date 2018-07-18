cmake_minimum_required(VERSION 3.6)

set(UIKit_DIR ../../../../)

# builds UIKit and bundles the Swift core libraries into the APK
# transitively imports the add_swiftpm_library command
find_package(UIKit REQUIRED)

# DemoApp is the name of the SwiftPM Product as listed in Package.swift
add_swiftpm_library(DemoApp
    PROJECT_DIRECTORY ../..
    PROJECT_DEPENDENCIES UIKit
)
