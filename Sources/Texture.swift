//
//  Texture.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import Foundation

internal final class Texture {
    let rawPointer: UnsafeMutablePointer<GPU_Image>

    var scale = Float(SDL.window.scale)

    var size: CGSize {
        return CGSize(width: Int(rawPointer.pointee.w), height: Int(rawPointer.pointee.h))
    }

    init?(imagePtr: UnsafeMutablePointer<GPU_Image>?, scale: Float = 2) {
        guard let ptr = imagePtr else {
            return nil
        }
        rawPointer = ptr
        GPU_SetSnapMode(rawPointer, GPU_SNAP_POSITION_AND_DIMENSIONS)
        GPU_SetImageFilter(rawPointer, GPU_FILTER_NEAREST)
        self.scale = scale
        scaleImage(scale)
        GPU_SetAnchor(rawPointer, 0, 0)
    }

    convenience init?(imagePath: String) {
        self.init(imagePtr: GPU_LoadImage(imagePath))
    }
    
    convenience init?(surface: UnsafeMutablePointer<SDLSurface>) {
        self.init(imagePtr: GPU_CopyImageFromSurface(surface))
    }

    convenience init?(data: Data) {
        var data = data
        let gpuImagePtr = data.withUnsafeMutableBytes({ (ptr: UnsafeMutablePointer<Int8>) -> UnsafeMutablePointer<GPU_Image>? in
            let rw = SDL_RWFromMem(ptr, Int32(data.count))
            return GPU_LoadImage_RW(rw, false)
        })
        self.init(imagePtr: gpuImagePtr)
    }

    convenience init?(width: Int, height: Int, format: GPU_FormatEnum) {
        self.init(
            imagePtr: GPU_CreateImage(UInt16(width), UInt16(height), format),
            scale: 1
        )
    }

    func replacePixels(with bytes: UnsafePointer<UInt8>, bytesPerPixel: Int) {
        var rect = GPU_Rect(x: 0, y: 0, w: Float(rawPointer.pointee.w), h: Float(rawPointer.pointee.h))
        GPU_UpdateImageBytes(rawPointer, &rect, bytes, Int32(rawPointer.pointee.w) * Int32(bytesPerPixel))
    }

    private func scaleImage(_ scale: Float) { // WARNING: scale parameter currently not used in function
        var image = rawPointer.pointee

        let defaultImageScale = UInt16(2) // XXX: get this from image path
        self.scale = Float(defaultImageScale)
        
        // Setting the scale here allows the texture to render at the expected size automatically
        image.h /= defaultImageScale
        image.w /= defaultImageScale
        image.texture_h /= defaultImageScale
        image.texture_w /= defaultImageScale
        image.base_h /= defaultImageScale
        image.base_w /= defaultImageScale

        rawPointer.pointee = image
    }

    deinit {
        GPU_FreeImage(rawPointer)
    }
}
