//
//  Window.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal final class Window {
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
