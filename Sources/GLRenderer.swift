//
//  GLRenderer.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import SDL_gpu
import func Foundation.round

internal final class GLRenderer {
    private let rawPointer: UnsafeMutablePointer<GPU_Target>
    internal let size: CGSize
    internal let scale: CGFloat

    // There is an inconsistency between Mac and Android when setting SDL_WINDOW_FULLSCREEN
    // The easiest solution is just to work in 1:1 pixels
    init() {
        #if DEBUG
        GPU_SetDebugLevel(GPU_DEBUG_LEVEL_MAX)
        #endif

        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "best")

    #if os(Android)
        // height/width are determined by the window when fullscreen:
        var size = CGSize.zero
        let options: SDLWindowFlags = [SDL_WINDOW_FULLSCREEN]
    #else
        var size: CGSize = .samsungS7
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
        if size == .zero {
            preconditionFailure("You need window dimensions to run")
        }

        // Fixes video surface visibility with transparent & opaque views in SDLSurface above
        // by changing the alpha blend function to: src-alpha * (1 - dst-alpha) + dst-alpha
        setShapeBlending(true)
        setShapeBlendMode(GPU_BLEND_NORMAL_FACTOR_ALPHA)

        clearErrors() // by now we have handled any errors we might have wanted to
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

    func blit(
        _ image: CGImage,
        anchorPoint: CGPoint,
        contentsScale: CGFloat,
        contentsGravity: ContentsGravityTransformation,
        opacity: Float
    ) {
        GPU_SetAnchor(image.rawPointer, Float(anchorPoint.x), Float(anchorPoint.y))
        GPU_SetRGBA(image.rawPointer, 255, 255, 255, opacity.normalisedToUInt8())

        GPU_BlitTransform(
            image.rawPointer,
            nil,
            self.rawPointer,
            Float(contentsGravity.offset.x),
            Float(contentsGravity.offset.y),
            0, // rotation in degrees
            Float(contentsGravity.scale.width / contentsScale),
            Float(contentsGravity.scale.height / contentsScale)
        )
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

    var clippingRect: CGRect? {
        didSet {
            guard let clippingRect = clippingRect else {
                return GPU_UnsetClip(rawPointer)
            }

            GPU_SetClipRect(rawPointer, clippingRect.gpuRect(scale: scale))
        }
    }

    func fill(_ rect: CGRect, with color: UIColor, cornerRadius: CGFloat) {
        if cornerRadius >= 1 {
            GPU_RectangleRoundFilled(rawPointer, rect.gpuRect(scale: scale), cornerRadius: Float(cornerRadius), color: color.sdlColor)
        } else {
            GPU_RectangleFilled(rawPointer, rect.gpuRect(scale: scale), color: color.sdlColor)
        }
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat) {
        GPU_SetLineThickness(Float(lineThickness))
        GPU_Rectangle(rawPointer, rect.gpuRect(scale: scale), color: lineColor.sdlColor)
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat, cornerRadius: CGFloat) {
        if cornerRadius > 1 {
            GPU_SetLineThickness(Float(lineThickness))
            GPU_RectangleRound(rawPointer, rect.gpuRect(scale: scale), cornerRadius: Float(cornerRadius), color: lineColor.sdlColor)
        } else {
            outline(rect, lineColor: lineColor, lineThickness: lineThickness)
        }
    }

    func flip() throws {
        GPU_Flip(rawPointer)
        try throwOnErrors(ofType: [GPU_ERROR_USER_ERROR, GPU_ERROR_BACKEND_ERROR])
    }

    deinit {
        defer { GPU_Quit() }

        // get and destroy existing GLRenderer because only one SDL_Window can exist on Android at the same time
        guard let gpuContext = self.rawPointer.pointee.context else {
            assertionFailure("glRenderer gpuContext not found")
            return
        }

        let existingWindowID = gpuContext.pointee.windowID
        let existingWindow = SDL_GetWindowFromID(existingWindowID)
        SDL_DestroyWindow(existingWindow)
    }
}

#if os(macOS)
import class AppKit.NSWindow
extension GLRenderer {
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
        if let density: Float = try? jni.call("getDeviceDensity", on: getSDLView()) {
            return CGFloat(density)
        } else {
            return 2.0 // assume retina
        }
    }
#endif

private extension CGRect {
    func gpuRect(scale: CGFloat) -> GPU_Rect {
        return GPU_Rect(
            x: Float(round(self.origin.x * scale) / scale),
            y: Float(round(self.origin.y * scale) / scale),
            w: Float(round(self.size.width * scale) / scale),
            h: Float(round(self.size.height * scale) / scale)
        )
    }
}

private extension CGSize {
    static let samsungS7 = CGSize(width: 2560 / 3.0, height: 1440 / 3.0) // 1080p 1.5x Retina
    static let nexus9 = CGSize(width: 2048 / 2.0, height: 1536 / 2.0)
}
