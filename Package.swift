// swift-tools-version:4.1

import PackageDescription

// Helpers:

//let platformSubpaths = ["cocoa","darwin","macosx","coreaudio","dummy","x11","disk"] // When building for Mac
let platformSubpaths = ["android","dummy"] // When building for Android

extension String {
    func subpaths(_ subpaths: [[String]]) -> [String] {
        return (subpaths.joined() + platformSubpaths).map { self + $0 }
    }

    func subpaths(_ subpaths: [String] = []) -> [String] {
        return (subpaths + platformSubpaths).map { self + $0 }
    }
}

let package = Package(
    name: "UIKit",
    products: [.library(name: "UIKit", type: .dynamic, targets: ["UIKit"])],
    targets: [
        .target(
            name: "SDL",
            path: "SDL/SDL2",
            sources: "src/".subpaths([
                ["SDL.c","SDL_assert.c","SDL_error.c","SDL_hints.c","SDL_log.c"],
                [ // include these entire subpaths
                    "atomic",
                    "cpuinfo",
                    "dynapi",
                    "events",
                    "loadso/dlopen",
                    "render",
                    "stdlib"
                ],
                "audio/".subpaths(["dummy","SDL_audio.c","SDL_audiodev.c","SDL_mixer.c","SDL_audiocvt.c","SDL_audiotypecvt.c","SDL_wave.c"]),
                "custom/".subpaths(["core"]), // we have overwritten SDL_Android.c
                "file/".subpaths(["SDL_rwops.c"]),
                "filesystem/".subpaths(),
                "haptic/".subpaths(["SDL_haptic.c"]),
                "joystick/".subpaths(["SDL_gamecontroller.c","SDL_joystick.c","darwin"]),
                "power/".subpaths(["SDL_power.c"]),
                "timer/".subpaths(["unix","SDL_timer.c"]),
                "thread/".subpaths(["pthread","SDL_thread.c"]),
                "video/".subpaths(["SDL_RLEaccel.c","SDL_blit.c","SDL_blit_0.c","SDL_blit_1.c","SDL_blit_A.c","SDL_blit_N.c","SDL_blit_auto.c","SDL_blit_copy.c","SDL_blit_slow.c","SDL_bmp.c","SDL_clipboard.c","SDL_egl.c","SDL_fillrect.c","SDL_pixels.c","SDL_rect.c","SDL_shape.c","SDL_stretch.c","SDL_surface.c","SDL_video.c"])
            ])
        ),
        .target(
            name: "SDL_ttf",
            dependencies: ["SDL"],
            path: "SDL/SDL_ttf",
            sources: "".subpaths([
                ["SDL_ttf.c"],
                // Build and statically link freetype.
                // The file list is from SDL_ttf's Android.mk:
                "external/freetype-2.4.12/src/".subpaths([
                    "autofit/autofit.c","base/ftbase.c","base/ftbbox.c","base/ftbdf.c","base/ftbitmap.c","base/ftcid.c","base/ftdebug.c","base/ftfstype.c","base/ftgasp.c","base/ftglyph.c","base/ftgxval.c","base/ftinit.c","base/ftlcdfil.c","base/ftmm.c","base/ftotval.c","base/ftpatent.c","base/ftpfr.c","base/ftstroke.c","base/ftsynth.c","base/ftsystem.c","base/fttype1.c","base/ftwinfnt.c","base/ftxf86.c","bdf/bdf.c","bzip2/ftbzip2.c","cache/ftcache.c","cff/cff.c","cid/type1cid.c","gzip/ftgzip.c","lzw/ftlzw.c","pcf/pcf.c","pfr/pfr.c","psaux/psaux.c","pshinter/pshinter.c","psnames/psmodule.c","raster/raster.c","sfnt/sfnt.c","smooth/smooth.c","truetype/truetype.c","type1/type1.c","type42/type42.c","winfonts/winfnt.c",
                ])
            ])
        ),
        .target(
            name: "SDL_gpu",
            dependencies: ["SDL"],
            path: "SDL/sdl-gpu",
            sources: "".subpaths([
                ["SDL_gpu.c","renderer_GLES_3.c","SDL_gpu_matrix.c","renderer_OpenGL_1.c","SDL_gpu_renderer.c","renderer_OpenGL_1_BASE.c","SDL_gpu_shapes.c","renderer_OpenGL_2.c","renderer_GLES_1.c","renderer_OpenGL_3.c","renderer_GLES_2.c","renderer_OpenGL_4.c"],
                "externals/".subpaths(["stb_image","stb_image_write"])
            ])
        ),
        .target(
            name: "UIKit",
            dependencies: ["SDL", "SDL_ttf", "SDL_gpu"/*, "JNI"*/],
            path: "Sources",
            exclude: [
                "VideoPlayer+Mac.swift",
                "AVPlayerItem+Mac.swift",
                "AVPlayerLayer+Mac.swift",
                "UIApplicationMain+Mac.swift"
            ]
        ),
        .target(
            name: "CJNI",
            dependencies: [],
            path: "swift-jni/Sources/CJNI"
        ),
        .target(
            name: "JNI",
            dependencies: ["CJNI"],
            path: "swift-jni/Sources/JNI"
        ),
    ]
)
