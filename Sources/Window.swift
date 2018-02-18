//
//  Window.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import SDL_gpu

internal final class Window {
    var printThisLoop = false // XXX: REMOVE ME!!

    private let rawPointer: UnsafeMutablePointer<GPU_Target>
    let size: CGSize
    let scale: CGFloat

    // There is an inconsistency between Mac and Android when setting SDL_WINDOW_FULLSCREEN
    // The easiest solution is just to work in 1:1 pixels
    init() {
        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "best")

    #if os(Android)
        // height/width are determined by the window when fullscreen:
        var size = CGSize.zero
        let options: SDLWindowFlags = [SDL_WINDOW_FULLSCREEN]
    #else
        // This corresponds to the Samsung S7 screen at its 1080p 1.5x Retina resolution:
        var size = CGSize(width: 2560 / 3.0, height: 1440 / 3.0)
//        size = CGSize(width: 512, height: 512)
        let options: SDLWindowFlags = [
            SDL_WINDOW_ALLOW_HIGHDPI,
            //SDL_WINDOW_FULLSCREEN
        ]
    #endif

        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)
        GPU_SetPreInitFlags(GPU_INIT_DISABLE_VSYNC)

        if options.contains(SDL_WINDOW_FULLSCREEN), let displayMode = SDLDisplayMode.current {
            // Fix fullscreen resolution on Mac and make Android easier to reason about:
            GPU_SetPreInitFlags(GPU_GetPreInitFlags() | GPU_INIT_DISABLE_AUTO_VIRTUAL_RESOLUTION)
            size = CGSize(width: CGFloat(displayMode.w), height: CGFloat(displayMode.h))
        }

        guard let gpuTarget = GPU_Init(UInt16(size.width), UInt16(size.height), UInt32(GPU_DEFAULT_INIT_FLAGS) | options.rawValue) else {
            print(SDLError())
            fatalError("GPU_Init failed")
        }
        rawPointer = gpuTarget

        #if os(Android)
            scale = getAndroidDeviceScale()

            GPU_SetVirtualResolution(rawPointer, UInt16(size.width / scale), UInt16(size.height / scale))
            size.width /= scale
            size.height /= scale
        #else
            // Mac:
            scale = CGFloat(rawPointer.pointee.base_h) / CGFloat(rawPointer.pointee.h)
        #endif

        
        self.size = size

        // Fixes video surface visibility with transparent & opaque views in SDLSurface above
        // by changing the alpha blend function to: src-alpha * (1 - dst-alpha) + dst-alpha
        setShapeBlending(true)
        setShapeBlendMode(GPU_BLEND_NORMAL_FACTOR_ALPHA)
    }

    func absolutePointInOwnCoordinates(x inputX: CGFloat, y inputY: CGFloat) -> CGPoint {
        #if os(macOS)
            // Here SDL scales our touch events for us, which means we need a special case for it:
            return CGPoint(x: inputX, y: inputY)
        #else
            // On all other platforms, we scale the touch events to the screen size manually:
            return CGPoint(x: inputX / scale, y: inputY / scale)
        #endif
    }

    /// clippingRect behaves like an offset
    func blit(_ image: CGImage, anchorPoint: CGPoint, scaleX: Float, scaleY: Float, opacity: Float, clippingRect: CGRect?) {
        GPU_SetAnchor(image.rawPointer, Float(anchorPoint.x), Float(anchorPoint.y))
        GPU_SetRGBA(image.rawPointer, 255, 255, 255, opacity.normalisedToUInt8())

        // The only difference between these two is/should be whether we pass a clipping rect:
        if let clippingRect = clippingRect {
            var clipGPU_Rect = GPU_Rect(clippingRect)
            GPU_BlitTransform(
                image.rawPointer,
                &clipGPU_Rect,
                self.rawPointer,
                Float(clippingRect.origin.x),
                Float(clippingRect.origin.y),
                0, // rotation in degrees
                scaleX,
                scaleY
            )
        } else {
            GPU_BlitTransform(
                image.rawPointer,
                nil,
                self.rawPointer,
                0,
                0,
                0, // rotation in degrees
                scaleX,
                scaleY
            )
        }
    }

    func setShapeBlending(_ newValue: Bool) {
        GPU_SetShapeBlending(newValue)
    }

    func setShapeBlendMode(_ newValue: GPU_BlendPresetEnum) {
        GPU_SetShapeBlendMode(newValue)
    }

    func clear() {
        GPU_Clear(rawPointer)
    }

    var clippingRect: CGRect = .zero {
        didSet {
            GPU_SetClipRect(rawPointer, GPU_Rect(clippingRect))
        }
    }

    func fill(_ rect: CGRect, with color: UIColor, cornerRadius: CGFloat) {
        if cornerRadius >= 1 {
            GPU_RectangleRoundFilled(rawPointer, GPU_Rect(rect), cornerRadius: Float(cornerRadius), color: color.sdlColor)
        } else {
            GPU_RectangleFilled(rawPointer, GPU_Rect(rect), color: color.sdlColor)
        }
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat) {
        GPU_SetLineThickness(Float(lineThickness))
        GPU_Rectangle(rawPointer, GPU_Rect(rect), color: lineColor.sdlColor)
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat, cornerRadius: CGFloat) {
        if cornerRadius > 1 {
            GPU_SetLineThickness(Float(lineThickness))
            GPU_RectangleRound(rawPointer, GPU_Rect(rect), cornerRadius: Float(cornerRadius), color: lineColor.sdlColor)
        } else {
            outline(rect, lineColor: lineColor, lineThickness: lineThickness)
        }
    }

    func flip() {
        GPU_Flip(rawPointer)
        printThisLoop = false
    }

    var isCameraEnabled: Bool {
        get { return GPU_IsCameraEnabled(rawPointer) }
        set { GPU_EnableCamera(rawPointer, newValue) }
    }

    deinit {
        defer { GPU_Quit() }

        // get and destroy existing Window because only one SDL_Window can exist on Android at the same time
        guard let gpuContext = self.rawPointer.pointee.context else {
            assertionFailure("window gpuContext not found")
            return
        }

        let existingWindowID = gpuContext.pointee.windowID
        let existingWindow = SDL_GetWindowFromID(existingWindowID)
        SDL_DestroyWindow(existingWindow)
    }
}

#if os(macOS)
import class AppKit.NSWindow
extension Window {
    var nsWindow: NSWindow {
        let sdlWindowID = rawPointer.pointee.context.pointee.windowID
        let sdlWindow = SDL_GetWindowFromID(sdlWindowID)
        var info = SDL_SysWMinfo()

        var version = SDL_version()
        SDL_GetVersion(&version)

        info.version.major = version.major
        info.version.minor = version.minor
        info.version.patch = version.patch

        SDL_GetWindowWMInfo(sdlWindow, &info)
        return info.info.cocoa.window.takeUnretainedValue()
    }
}
#endif

extension SDLWindowFlags: OptionSet {}

#if os(Android)
    import JNI

    fileprivate func getAndroidDeviceScale() -> CGFloat {
        let sdlView = getSDLView()
        if let density: Float = try? jni.call("getDeviceDensity", on: sdlView) {
            return CGFloat(density)
        } else {
            return 2.0 // assume retina
        }
    }
#endif
