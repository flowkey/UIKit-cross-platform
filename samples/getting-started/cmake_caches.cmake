# Copied from NDK's android.toolchain.cmake:
if(ANDROID_ABI STREQUAL armeabi-v7a)
  set(ANDROID_SYSROOT_ABI arm)
  set(ANDROID_TOOLCHAIN_NAME arm-linux-androideabi)
  set(ANDROID_TOOLCHAIN_ROOT ${ANDROID_TOOLCHAIN_NAME})
  set(ANDROID_HEADER_TRIPLE arm-linux-androideabi)
  set(CMAKE_SYSTEM_PROCESSOR armv7-a)
  set(ANDROID_LLVM_TRIPLE armv7-none-linux-androideabi)
elseif(ANDROID_ABI STREQUAL arm64-v8a)
  set(ANDROID_SYSROOT_ABI arm64)
  set(CMAKE_SYSTEM_PROCESSOR aarch64)
  set(ANDROID_TOOLCHAIN_NAME aarch64-linux-android)
  set(ANDROID_TOOLCHAIN_ROOT ${ANDROID_TOOLCHAIN_NAME})
  set(ANDROID_LLVM_TRIPLE aarch64-none-linux-android)
  set(ANDROID_HEADER_TRIPLE aarch64-linux-android)
elseif(ANDROID_ABI STREQUAL x86_64)
  set(ANDROID_SYSROOT_ABI x86_64)
  set(CMAKE_SYSTEM_PROCESSOR x86_64)
  set(ANDROID_TOOLCHAIN_NAME x86_64-linux-android)
  set(ANDROID_TOOLCHAIN_ROOT ${ANDROID_ABI})
  set(ANDROID_LLVM_TRIPLE x86_64-none-linux-android)
  set(ANDROID_HEADER_TRIPLE x86_64-linux-android)
endif()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
  set(ANDROID_HOST_TAG linux-x86_64)
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)
  set(ANDROID_HOST_TAG darwin-x86_64)
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
  set(ANDROID_HOST_TAG windows-x86_64)
endif()

######################################################################

set(ANDROID_ABI_LINK_BASEPATH ${ANDROID_NDK}/toolchains/${ANDROID_TOOLCHAIN_ROOT}-4.9/prebuilt/${ANDROID_HOST_TAG})
if(ANDROID_ABI STREQUAL armeabi-v7a)
  set(ANDROID_LINKER_PATH_SUFFIX ${CMAKE_SYSTEM_PROCESSOR}/thumb)
endif()
set(ANDROID_LINKER_GCC_PATH ${ANDROID_ABI_LINK_BASEPATH}/lib/gcc/${ANDROID_TOOLCHAIN_NAME}/4.9.x/${ANDROID_LINKER_PATH_SUFFIX})
set(ANDROID_LINKER_CXX_PATH ${ANDROID_ABI_LINK_BASEPATH}/${ANDROID_TOOLCHAIN_NAME}/lib/${ANDROID_LINKER_PATH_SUFFIX})

# Make a list that we then convert to a (space-delimited) string, below
set(SWIFT_FLAGS
    -g # always produce debug symbols
    -sdk ${SWIFT_SDK}
    -tools-directory ${SWIFT_SDK}/usr/bin
    -Xcc --sysroot=${ANDROID_NDK}/sysroot
    -Xlinker -L${ANDROID_NDK}/platforms/${ANDROID_PLATFORM}/arch-${ANDROID_SYSROOT_ABI}/usr/lib
    -Xclang-linker -L${ANDROID_LINKER_GCC_PATH}
    -Xclang-linker -L${ANDROID_LINKER_CXX_PATH}
    -Xclang-linker --sysroot=${ANDROID_NDK}/platforms/${ANDROID_PLATFORM}/arch-${ANDROID_SYSROOT_ABI}
    -Xclang-linker -nostdlib++
    -Xlinker -L${SWIFT_SDK}/usr/lib/swift/android
)

if(NOT CMAKE_BUILD_TYPE STREQUAL Debug)
    list(APPEND SWIFT_FLAGS -O)
endif()

list(JOIN SWIFT_FLAGS " " SWIFT_FLAGS)
set(CMAKE_Swift_FLAGS "${SWIFT_FLAGS}" CACHE INTERNAL "")

set(CMAKE_Swift_COMPILER_TARGET "${ANDROID_LLVM_TRIPLE}" CACHE INTERNAL "")