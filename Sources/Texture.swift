//
//  Texture.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import Foundation

internal class Texture {
    let rawPointer: UnsafeMutablePointer<GPU_Image>
    let scale: CGFloat
    let size: CGSize

    /**
     Initialize a `Texture` by passing a reference to a `GPU_Image`, which is usually the result of SDL_gpu's `GPU_*Image*` creation functions. May be null.

     - parameter scale:
         Values other than 1.0 will scale the given GPU_Image proportionally in both dimensions. e.g. A scale of 2.0 will internally change the reported size of a GPU_Image with dimensions (w: 100, 100) to (w: 50, h: 50), without changing the actual pixel buffers. The result is that SDL_gpu's blitted output will appear to take up less pixels at higher scale, but with a higher pixel density.

         Defaults to `SDL.window.scale`.
     */
    init?(_ pointer: UnsafeMutablePointer<GPU_Image>?, scale: CGFloat = SDL.window.scale) {
        guard let pointer = pointer else { return nil }
        self.scale = scale
        rawPointer = pointer

        GPU_SetSnapMode(rawPointer, GPU_SNAP_POSITION_AND_DIMENSIONS)
        GPU_SetImageFilter(rawPointer, GPU_FILTER_NEAREST)
        GPU_SetAnchor(rawPointer, 0, 0)

        // Scale the image to allow the texture to render at the expected size automatically on blit
        // If scale == 1.0 we're wasting a few cycles here, but that is preferable to adding complexity to our code:
        var image = rawPointer.pointee
        image.h = UInt16(CGFloat(image.h) / scale)
        image.w = UInt16(CGFloat(image.w) / scale)
        image.texture_h = UInt16(CGFloat(image.texture_h) / scale)
        image.texture_w = UInt16(CGFloat(image.texture_w) / scale)
        image.base_h = UInt16(CGFloat(image.base_h) / scale)
        image.base_w = UInt16(CGFloat(image.base_w) / scale)
        rawPointer.pointee = image

        // Post-scale size.
        // e.g. If the pixel buffer contains 100x100 pixels at scale 2.0, size will be 50x50:
        size = CGSize(
            width: Int(rawPointer.pointee.w),
            height: Int(rawPointer.pointee.h)
        )
    }

    convenience init?(imagePath: String) {
        // TODO: get scale factor from `imagePath` (e.g. @2x means scale == 2)
        self.init(GPU_LoadImage(imagePath), scale: 2)
    }
    
    convenience init?(surface: UnsafeMutablePointer<SDLSurface>) {
        self.init(GPU_CopyImageFromSurface(surface))
    }

    convenience init?(data: Data) {
        var data = data
        let gpuImagePtr = data.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<Int8>) -> UnsafeMutablePointer<GPU_Image>? in
            let rw = SDL_RWFromMem(ptr, Int32(data.count))
            return GPU_LoadImage_RW(rw, false)
        }

        self.init(gpuImagePtr)
    }

    func replacePixels(with bytes: UnsafePointer<UInt8>, bytesPerPixel: Int) {
        var rect = GPU_Rect(x: 0, y: 0, w: Float(rawPointer.pointee.w), h: Float(rawPointer.pointee.h))
        GPU_UpdateImageBytes(rawPointer, &rect, bytes, Int32(rawPointer.pointee.w) * Int32(bytesPerPixel))
    }

    deinit {
        GPU_FreeImage(rawPointer)
    }
}
