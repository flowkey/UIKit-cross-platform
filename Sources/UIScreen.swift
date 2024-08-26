//
//  UIScreen.swift
//  UIKit
//
//  Created by Chris on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import SDL_gpu
import Dispatch

extension SDLWindowFlags: OptionSet {}

public extension UIScreen {
    @MainActor
    internal(set) static var main: UIScreen! {
        didSet { CALayer.layerTreeIsDirty = true }
    }
}

@MainActor
public final class UIScreen {
    // If we could use `private` members from an extension this would be private
    // Keep that in mind when using it: i.e. if possible, don't ;)
    internal var rawPointer: UnsafeMutablePointer<GPU_Target>!

    public var bounds: CGRect {
        didSet {
            let newWidth = UInt16(bounds.width.rounded())
            let newHeight = UInt16(bounds.height.rounded())
            GPU_SetWindowResolution(newWidth, newHeight)
            GPU_SetVirtualResolution(rawPointer, newWidth, newHeight)
        }
    }
    nonisolated public let scale: CGFloat

    private init(renderTarget: UnsafeMutablePointer<GPU_Target>!, bounds: CGRect, scale: CGFloat) {
        self.rawPointer = renderTarget
        self.bounds = bounds
        self.scale = scale
    }

    convenience init() {
        guard UIScreen.main == nil else {
            // This is a problem because it means something else in the logic is probably incorrect
            // For example, if you are restarting the app, you should ensure the previous app is fully deinited first
            fatalError("Tried to reinit UIScreen.main when there is already a screen inited")
        }

        #if DEBUG
        GPU_SetDebugLevel(GPU_DEBUG_LEVEL_MAX)
        #endif

        SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "best")

        #if os(Android)
        // height/width are determined by the window when fullscreen:
        var size = CGSize.zero
        let options: SDLWindowFlags = [SDL_WINDOW_FULLSCREEN]
        #else
        var size = CGSize.samsungGalaxyTab10.portrait

        let options: SDLWindowFlags = [
            SDL_WINDOW_ALLOW_HIGHDPI,
            SDL_WINDOW_RESIZABLE,
        ]
        #endif

        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)
        GPU_SetPreInitFlags(GPU_INIT_DISABLE_VSYNC)

        if options.contains(SDL_WINDOW_FULLSCREEN), let displayMode = SDLDisplayMode.current {
            // Fix fullscreen resolution on Mac and make Android easier to reason about:
            // There is an inconsistency between Mac and Android when setting SDL_WINDOW_FULLSCREEN
            // The easiest solution is just to work in 1:1 pixels
            GPU_SetPreInitFlags(GPU_GetPreInitFlags() | GPU_INIT_DISABLE_AUTO_VIRTUAL_RESOLUTION)
            size = CGSize(width: CGFloat(displayMode.w), height: CGFloat(displayMode.h))
        }

        guard let gpuTarget = GPU_Init(UInt16(size.width), UInt16(size.height), UInt32(GPU_DEFAULT_INIT_FLAGS) | options.rawValue) else {
            print(SDLError())
            fatalError("GPU_Init failed")
        }

        #if os(Android)
        let scale = getAndroidDeviceScale()

        GPU_SetVirtualResolution(gpuTarget, UInt16(size.width / scale), UInt16(size.height / scale))
        size.width /= scale
        size.height /= scale
        #else
        // Mac:
        let scale = CGFloat(gpuTarget.pointee.base_h) / CGFloat(gpuTarget.pointee.h)
        #endif

        if size == .zero {
            preconditionFailure("You need window dimensions to run")
        }

        self.init(
            renderTarget: gpuTarget,
            bounds: CGRect(origin: .zero, size: size),
            scale: scale
        )

        // Fixes video surface visibility with transparent & opaque views in SDLSurface above
        // by changing the alpha blend function to: src-alpha * (1 - dst-alpha) + dst-alpha
        setShapeBlending(true)
        setShapeBlendMode(GPU_BLEND_NORMAL_FACTOR_ALPHA)

        clearErrors() // by now we have handled any errors we might have wanted to
    }

    deinit {
        DispatchQueue.main.syncSafe {
            UIView.completePendingAnimations()
            UIView.layersWithAnimations.removeAll()
            UIView.currentAnimationPrototype = nil
            UIEvent.activeEvents.removeAll()
            FontRenderer.cleanupSession()
        }

        guard let rawPointer = self.rawPointer else {
            return
        }

        defer { GPU_Quit() }
        guard let gpuContext = rawPointer.pointee.context else {
            assertionFailure("glRenderer gpuContext not found")
            return
        }

        let existingWindowID = gpuContext.pointee.windowID
        let existingWindow = SDL_GetWindowFromID(existingWindowID)
        SDL_DestroyWindow(existingWindow)
    }

    // Should be in UIScreen+render.swift but you can't store properties in an extension..
    var clippingRect: CGRect? {
        didSet { didSetClippingRect() }
    }
}

// XXX: This can be removed entirely when the new touch handling for Android lands
extension UIScreen {
    func absolutePointInOwnCoordinates(x inputX: CGFloat, y inputY: CGFloat) -> CGPoint {
        #if os(macOS)
        // Here SDL scales our touch events for us, which means we need a special case for it:
        return CGPoint(x: inputX, y: inputY)
        #else
        // On all other platforms, we scale the touch events to the screen size manually:
        return CGPoint(x: inputX / scale, y: inputY / scale)
        #endif
    }
}

#if os(macOS)
import class AppKit.NSWindow
extension UIScreen {
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


extension UIScreen {
    /// Used in tests only and doesn't actually render anything
    static func dummyScreen(
        bounds: CGRect = CGRect(origin: .zero, size: .samsungGalaxyTab10),
        scale: CGFloat
    ) -> UIScreen {
        return UIScreen(
            renderTarget: nil,
            bounds: bounds,
            scale: scale
        )
    }
}

private extension CGSize {
    // smartphones:
    static let samsungGalaxyJ5 = CGSize(width: 1280 / 2.0, height: 720 / 2.0)
    static let samsungGalaxyS5 = CGSize(width: 1920 / 3.0, height: 1080 / 3.0)
    static let samsungGalaxyS7 = CGSize(width: 2560 / 4.0, height: 1440 / 4.0) // 1080p 1.5x Retina
    static let samsungGalaxyS8 = CGSize(width: 2960 / 4.0, height: 1440 / 4.0)

    // tablets:
    static let nexus9 = CGSize(width: 2048 / 2.0, height: 1536 / 2.0)
    static let huaweiM3lite = CGSize(width: 1920 / 2.0, height: 1200 / 2.0)
    static let samsungGalaxyTabS_T800 = CGSize(width: 2560 / 2.0, height: 1600 / 2.0)
    static let samsungGalaxyTab10 = CGSize(width: 1280 / 1.0, height: 800 / 1.0)
    static let samsungGalaxyTabA_T380 = CGSize(width: 1280 / 1.0, height: 800 / 1.0)
    static let samsungGalaxyTabA_T580 = CGSize(width: 1920 / 1.0, height: 1200 / 1.0)

    // change orientation if needed
    var landscape: CGSize {
        if self.width >= self.height {
            return self
        } else {
            return CGSize(width: self.height, height: self.width)
        }
    }

    var portrait: CGSize {
        if self.width <= self.height {
            return self
        } else {
            return CGSize(width: self.height, height: self.width)
        }
    }
}
