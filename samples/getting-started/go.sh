#!/bin/bash

set -e

ORIGINAL_PWD=$PWD
SCRIPT_ROOT=$(cd $(dirname $0); echo -n $PWD)

if [[ ! ${ANDROID_NDK_PATH} ]]
then
    echo "Please define ANDROID_NDK_PATH"
    exit 1
fi

SWIFT_ANDROID_TOOLCHAIN_PATH="${SWIFT_ANDROID_TOOLCHAIN_PATH:-${SCRIPT_ROOT}/../../swift-android-toolchain}"

# Add `ld.gold` to PATH
# This is weird because it looks like it's the armv7a ld.gold but it seems to support all archs
LOWERCASE_UNAME=`uname | tr '[:upper:]' '[:lower:]'`
PATH="${ANDROID_NDK_PATH}/toolchains/arm-linux-androideabi-4.9/prebuilt/${LOWERCASE_UNAME}-x86_64/arm-linux-androideabi/bin:$PATH"

build() {
    echo "Compiling for ${ANDROID_ABI}"

    rm -rf build${ANDROID_ABI}
    mkdir -p build/${ANDROID_ABI}
    cd build/${ANDROID_ABI}

    # You need a different SDK per arch, e.g. swift-android-toolchain/Android.sdk-armeabi-v7a/
    export ANDROID_SDK="$SWIFT_ANDROID_TOOLCHAIN_PATH/Android.sdk-${ANDROID_ABI}"

    $SWIFT_ANDROID_TOOLCHAIN_PATH/setup.sh

    local LIBRARY_OUTPUT_DIRECTORY="${SCRIPT_ROOT}/android/app/src/main/jniLibs/${ANDROID_ABI}"

    cmake \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DANDROID_ABI=${ANDROID_ABI} \
        -DANDROID_PLATFORM=android-21 \
        -DANDROID_NDK="${ANDROID_NDK_PATH}" \
        -DSWIFT_SDK="${ANDROID_SDK}" \
        -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_PATH}/build/cmake/android.toolchain.cmake" \
        -C "${SWIFT_ANDROID_TOOLCHAIN_PATH}/cmake_caches.cmake" \
        -DCMAKE_Swift_COMPILER="${ANDROID_SDK}/usr/bin/swiftc" \
        -DCMAKE_Swift_COMPILER_FORCED=TRUE \
        -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=${LIBRARY_OUTPUT_DIRECTORY} \
        ${ORIGINAL_PWD}

    cmake --build . # --verbose

    # Install stdlib etc. into output directory
    cp "${ANDROID_SDK}/usr/lib/swift/android"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
    cp "$SWIFT_ANDROID_TOOLCHAIN_PATH/libs/${ANDROID_ABI}"/*.so "${LIBRARY_OUTPUT_DIRECTORY}"
    cp "${ANDROID_NDK_PATH}/sources/cxx-stl/llvm-libc++/libs/${ANDROID_ABI}/libc++_shared.so" "${LIBRARY_OUTPUT_DIRECTORY}"

    echo "Finished compiling for ${ANDROID_ABI}"
}

ARGS="$@"
SUPPORTED_ABIS="armeabi-v7a arm64-v8a x86_64"
ABIS_TO_BUILD=${ARGS:-$SUPPORTED_ABIS}

for SUPPORTED_ABI in $SUPPORTED_ABIS
do
    if [[ $ABIS_TO_BUILD == *"$SUPPORTED_ABI"* ]]; then
        export ANDROID_ABI=$SUPPORTED_ABI
        build
    fi 
done
