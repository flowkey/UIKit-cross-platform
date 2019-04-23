cmake_minimum_required(VERSION 3.4.1)

get_filename_component(UIKIT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR} ABSOLUTE)

set(SwiftPM_DIR ${UIKIT_DIRECTORY}/swift-android-toolchain)
find_package(SwiftPM REQUIRED)


add_swiftpm_library(JNI
    PROJECT_DIRECTORY ${UIKIT_DIRECTORY}/swift-jni
    MODULE_MAPS Sources/CJNI/include/module.modulemap
)

set(MISC_C_FLAGS # XXX: we should use the flags provided by CMake automatically and/or include the following in our toolchain.json
    -DANDROID
    -fno-exceptions
    -fno-rtti)

set(SDL_C_FLAGS
    -I${UIKIT_DIRECTORY}/SDL/SDL2/include
    -I${UIKIT_DIRECTORY}/SDL/SDL_ttf/include
    -I${UIKIT_DIRECTORY}/SDL/sdl-gpu/externals/stb_image
    -I${UIKIT_DIRECTORY}/SDL/sdl-gpu/externals/stb_image_write
    # XXX: the following build flags shouldn't really be used for builds of UIKit's dependencies
    -DFT2_BUILD_LIBRARY
    -DGL_GLEXT_PROTOTYPES
    -DSDL_GPU_DISABLE_OPENGL)

add_swiftpm_library(UIKit
    PROJECT_DIRECTORY ${UIKIT_DIRECTORY}
    PROJECT_DEPENDENCIES JNI
    C_FLAGS ${MISC_C_FLAGS} ${SDL_C_FLAGS}
    LINK_LIBS dl GLESv1_CM GLESv2 log android
    MODULE_MAPS SDL/SDL2/include/module.modulemap SDL/SDL_ttf/include/module.modulemap SDL/sdl-gpu/include/module.modulemap
)
