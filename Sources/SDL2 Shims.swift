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

class SDLRenderer {
    public typealias Options = SDLRendererFlags
    public let rawPointer: OpaquePointer
    init?(window: SDLWindow, index: Int, options: Options) {
        guard let renderer = SDL_CreateRenderer(window.rawPointer, -1, options.rawValue) else { return nil }
        rawPointer = renderer
    }

    var blendMode: SDLBlendMode? {
        get {
            var blendMode: SDLBlendMode = SDLBlendMode(rawValue: 0)
            return SDL_GetRenderDrawBlendMode(rawPointer, &blendMode) == 0 ? blendMode : nil
        }
        set {
            guard let newValue = newValue else { return }
            SDL_SetRenderDrawBlendMode(rawPointer, newValue)
        }
    }

    func getDrawColor() -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        var r: UInt8 = 0
        var g: UInt8 = 0
        var b: UInt8 = 0
        var a: UInt8 = 0
        SDL_GetRenderDrawColor(rawPointer, &r, &g, &b, &a)
        return (r, g, b, a)
    }

    func setDrawColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        SDL_SetRenderDrawColor(rawPointer, r, g, b, a)
    }

    func fill() {
        SDL_RenderFillRect(rawPointer, nil)
    }

    func fill(_ rect: SDLRect) {
        var rect = rect
        SDL_RenderFillRect(rawPointer, &rect)
    }

    func fill(_ rects: [SDLRect]) {
        SDL_RenderFillRects(rawPointer, rects, Int32(rects.count))
    }

    func clear() {
        SDL_RenderClear(rawPointer)
    }

    func present() {
        SDL_RenderPresent(rawPointer)
    }

    deinit { SDL_DestroyRenderer(rawPointer) }
}

extension SDLRenderer.Options: OptionSet {
    static let software = __SDL_RENDERER_SOFTWARE
    static let accelerated = __SDL_RENDERER_ACCELERATED
    static let presentVSync = __SDL_RENDERER_PRESENTVSYNC
    static let targetTexture = __SDL_RENDERER_TARGETTEXTURE
}

class Texture {
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

class Window {
    private let rawPointer: UnsafeMutablePointer<GPU_Target>

    let size: CGSize
    let scaleFactor: CGFloat

    init(size: CGSize, options: SDLWindowFlags) {
        let pointer = GPU_Init(UInt16(size.width), UInt16(size.height), UInt32(GPU_DEFAULT_INIT_FLAGS) | options.rawValue)
        rawPointer = pointer!

        // On the Mac, the provided size should == (gpuWindow.w, gpuWindow.h)
        // On Android etc. (or maybe always wenn fullscreen), the native device size is taken, so set size
        let gpuWindow = rawPointer.pointee

        // Test this on Android:
        if let displayMode = SDLDisplayMode.current {
            print(displayMode.w, displayMode.h)
            print(size)
            print(gpuWindow.viewport)
            print(gpuWindow.base_w, gpuWindow.base_h)
            print(gpuWindow.w, gpuWindow.h)
        }

        var size = size
        size.width = CGFloat(gpuWindow.w)
        size.height = CGFloat(gpuWindow.h)
        self.size = size

        scaleFactor = CGFloat(gpuWindow.base_w) / CGFloat(gpuWindow.w)
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

    // The docs state that we shouldn't try to free the GPU_Target ourselves..
    //deinit { GPU_FreeImage(rawPointer) }
}

class SDLWindow {
    public typealias Options = SDLWindowFlags
    public let rawPointer: OpaquePointer

    let contentsScale: Double
    let id: UInt32

    var width: Int
    var height: Int

    init?(title: String, x: Int = Int(SDL_WINDOWPOS_UNDEFINED_MASK), y: Int = Int(SDL_WINDOWPOS_UNDEFINED_MASK), w: Int, h: Int, options: Options = []) {
        guard let window = __SDL_CreateWindow(title, Int32(x), Int32(y), Int32(w), Int32(h), options.rawValue) else { return nil }

        rawPointer = window
        id = SDL_GetWindowID(rawPointer)

        width = w
        height = h

        // test for retina
        var actualWidth: Int32 = 0
        var actualHeight: Int32 = 0
        SDL_GL_GetDrawableSize(window, &actualWidth, &actualHeight)
        contentsScale = (actualWidth > 0) ? Double(actualWidth) / Double(w) : 1.0
    }

    func updateWindowSurface() {
        SDL_UpdateWindowSurface(rawPointer)
    }

    var surface: SDLSurface? {
        guard let surface = SDL_GetWindowSurface(rawPointer) else {
            print(SDLError().description)
            return nil
        }
        return surface.pointee
    }

    deinit { SDL_DestroyWindow(rawPointer) }
}

extension SDLWindow.Options: OptionSet {}


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
