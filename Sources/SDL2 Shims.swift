//
//  SDL2 Shims.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 05.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

struct SDLError: Error {
    let description: String
    init() {
        // Get the error at time of throwing, otherwise another error could occur in the meantime:
        self.description = String(cString: __SDL_GetError())
    }
}

extension SDLBool: ExpressibleByBooleanLiteral {
    static let `true` = __SDL_TRUE
    static let `false` = __SDL_FALSE

    public init(booleanLiteral value: Bool) {
        self = (value ? .true : .false)
    }
}

final class Texture {
    let rawPointer: UnsafeMutablePointer<GPU_Image>

    let height: Int
    let width: Int
    let scale: Float

    init?(imagePath: String) {
        guard let gpuImage = GPU_LoadImage(imagePath) else { return nil }

        var image = gpuImage.pointee
        let scale = UInt16(2) // XXX: get this from image path
        self.scale = Float(scale)

        // Setting the scale here allows the texture to render at the expected size automatically
        image.h /= scale
        image.w /= scale
        image.texture_h /= scale
        image.texture_w /= scale
        image.base_h /= scale
        image.base_w /= scale
        height = Int(image.h)
        width = Int(image.w)

        gpuImage.pointee = image
        GPU_SetAnchor(gpuImage, 0, 0)

        rawPointer = gpuImage
    }

    deinit { GPU_FreeImage(rawPointer) }
}

final class Window {
    private let rawPointer: UnsafeMutablePointer<GPU_Target>
    let size: CGSize

    // There is an inconsistency between Mac and Android when setting SDL_WINDOW_FULLSCREEN
    // The easiest solution is just to work in 1:1 pixels
    init(size: CGSize, options: SDLWindowFlags) {
        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)
        let windowIsFullscreen = options.contains(SDL_WINDOW_FULLSCREEN)

        var size = size
        if windowIsFullscreen, let displayMode = SDLDisplayMode.current {
            // Fix fullscreen resolution on Mac and make Android easier to reason about:
            GPU_SetPreInitFlags(GPU_INIT_DISABLE_AUTO_VIRTUAL_RESOLUTION)
            size = CGSize(width: CGFloat(displayMode.w), height: CGFloat(displayMode.h))
        }

        rawPointer = GPU_Init(UInt16(size.width), UInt16(size.height), UInt32(GPU_DEFAULT_INIT_FLAGS) | options.rawValue)!

        #if os(Android)
        GPU_SetVirtualResolution(rawPointer, UInt16(size.width / 2), UInt16(size.height / 2))
        size.width /= 2
        size.height /= 2
        pixelCoordinateContentScale = 2
        #else
        pixelCoordinateContentScale = 1
        #endif

        self.size = size
    }

    private let pixelCoordinateContentScale: CGFloat

    func absolutePointInOwnCoordinates(x inputX: CGFloat, y inputY: CGFloat) -> CGPoint {
        return CGPoint(x: inputX / pixelCoordinateContentScale, y: inputY / pixelCoordinateContentScale)
    }

    func blit(_ texture: Texture, to destination: CGPoint) {
        rawPointer.pointee.blit(texture.rawPointer, from: nil, x: Float(destination.x), y: Float(destination.y))
    }

    func blit(_ texture: Texture, from source: CGRect, to destination: CGPoint) {
        var source = GPU_Rect(source)
        rawPointer.pointee.blit(texture.rawPointer, from: &source, x: Float(destination.x), y: Float(destination.y))
    }

    func clear() {
        rawPointer.pointee.clear()
    }

    func fill(_ rect: CGRect, with color: UIColor) {
        GPU_RectangleFilled(rawPointer, GPU_Rect(rect), color: color.sdlColor)
    }

    func fill(_ rect: CGRect, with color: UIColor, cornerRadius: CGFloat) {
        if cornerRadius >= rect.width / 2 {
            GPU_CircleFilled(rawPointer, Float(rect.midX), Float(rect.midY), Float(rect.width / 2), color.sdlColor)
        } else if cornerRadius >= 1 {
            GPU_RectangleRoundFilled(rawPointer, GPU_Rect(rect), cornerRadius: Float(cornerRadius), color: color.sdlColor)
        } else {
            fill(rect, with: color)
        }
    }

    func outline(_ rect: CGRect, with color: UIColor) {
        GPU_Rectangle(rawPointer, GPU_Rect(rect), color: color.sdlColor)
    }

    func outline(_ rect: CGRect, with color: UIColor, cornerRadius: CGFloat) {
        if cornerRadius >= 1 {
            GPU_RectangleRound(rawPointer, GPU_Rect(rect), cornerRadius: Float(cornerRadius), color: color.sdlColor)
        } else {
            outline(rect, with: color)
        }
    }

    func flip() {
        rawPointer.pointee.flip()
    }

    deinit {
        // GPU_FreeImage(rawPointer) // The docs state that we shouldn't try to free the GPU_Target ourselves..
        GPU_Quit()
    }
}

extension SDLWindowFlags: OptionSet {}

extension SDLDisplayMode {
    static var current: SDLDisplayMode? {
        var displayMode = SDLDisplayMode()
        guard __SDL_GetCurrentDisplayMode(0, &displayMode) == 0 else {
            return nil
        }

        return displayMode
    }
}

extension SDLRect: Equatable {
    public func intersects(_ other: SDLRect) -> Bool {
        var other = other
        return self.intersects(&other) == .true
    }

    public func intersection(with other: SDLRect) -> SDLRect {
        var other = other
        var result = SDLRect()
        self.intersection(with: &other, result: &result)
        return result
    }

    public static func == (lhs: SDLRect, rhs: SDLRect) -> Bool {
        var rhs = rhs
        return lhs.equals(&rhs) == .true
    }
}
