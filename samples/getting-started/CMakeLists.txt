cmake_minimum_required(VERSION 3.16)

project(DemoApp LANGUAGES C CXX Swift)
#set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

add_subdirectory("../../" UIKit)

add_library(DemoApp SHARED 
    ./DemoApp/ViewController.swift
    ./DemoApp/androidMain.swift
    ./DemoApp/AppDelegate.swift
)

target_link_libraries(DemoApp PRIVATE UIKit JNI SDL)