//
//  Window.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

internal final class Window {
    private let rawPointer: UnsafeMutablePointer<GPU_Target>
    let size: CGSize

    // There is an inconsistency between Mac and Android when setting SDL_WINDOW_FULLSCREEN
    // The easiest solution is just to work in 1:1 pixels
    init(size: CGSize, options: SDLWindowFlags) {
        SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)

        GPU_SetPreInitFlags(GPU_INIT_ENABLE_VSYNC)

        var size = size
        if options.contains(SDL_WINDOW_FULLSCREEN), let displayMode = SDLDisplayMode.current {
            // Fix fullscreen resolution on Mac and make Android easier to reason about:
            GPU_SetPreInitFlags(GPU_GetPreInitFlags() | GPU_INIT_DISABLE_AUTO_VIRTUAL_RESOLUTION)
            size = CGSize(width: CGFloat(displayMode.w), height: CGFloat(displayMode.h))
        }
        
        rawPointer = GPU_Init(UInt16(size.width), UInt16(size.height), UInt32(GPU_DEFAULT_INIT_FLAGS) | options.rawValue)!

        #if os(Android)
            GPU_SetVirtualResolution(rawPointer, UInt16(size.width / 2), UInt16(size.height / 2))
            size.width /= 2
            size.height /= 2
            pixelCoordinateContentScale = 2
        #else // Mac:
            pixelCoordinateContentScale = 1
        #endif
        
        self.size = size
    }

    private let pixelCoordinateContentScale: CGFloat

    func absolutePointInOwnCoordinates(x inputX: CGFloat, y inputY: CGFloat) -> CGPoint {
        return CGPoint(x: inputX / pixelCoordinateContentScale, y: inputY / pixelCoordinateContentScale)
    }

    func blit(_ texture: Texture, to destination: CGPoint) {
        GPU_Blit(texture.rawPointer, nil, rawPointer, Float(destination.x), Float(destination.y))
    }

    func blit(_ texture: Texture, from source: CGRect, to destination: CGPoint) {
        var source = GPU_Rect(source)
        GPU_Blit(texture.rawPointer, &source, rawPointer, Float(destination.x), Float(destination.y))
    }

    func clear() {
        GPU_Clear(rawPointer)
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
    }

    deinit {
        // GPU_FreeImage(rawPointer) // The docs state that we shouldn't try to free the GPU_Target ourselves..
        GPU_Quit()
    }
}

extension SDLWindowFlags: OptionSet {}
