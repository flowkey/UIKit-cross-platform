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

    var scale = Float(SDL.window.scale)

    var size: CGSize {
        return CGSize(width: Int(rawPointer.pointee.w), height: Int(rawPointer.pointee.h))
    }

    init?(ptr: UnsafeMutablePointer<GPU_Image>?) {
        guard let ptr = ptr else { return nil }
        rawPointer = ptr
        GPU_SetSnapMode(rawPointer, GPU_SNAP_POSITION_AND_DIMENSIONS)
        GPU_SetImageFilter(rawPointer, GPU_FILTER_NEAREST)
        GPU_SetAnchor(rawPointer, 0, 0)
    }

    convenience init?(imagePtr: UnsafeMutablePointer<GPU_Image>?, scale: Float = 2) {
        self.init(ptr: imagePtr)
        scaleImage(scale)
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

    func replacePixels(with bytes: UnsafePointer<UInt8>, bytesPerPixel: Int) {
        var rect = GPU_Rect(x: 0, y: 0, w: Float(rawPointer.pointee.w), h: Float(rawPointer.pointee.h))
        GPU_UpdateImageBytes(rawPointer, &rect, bytes, Int32(rawPointer.pointee.w) * Int32(bytesPerPixel))
    }

    private func scaleImage(_ scale: Float = 2) { // XXX: get scale this from image path
        var image = rawPointer.pointee
        self.scale = scale
        
        // Setting the scale here allows the texture to render at the expected size automatically
        image.h /= UInt16(scale)
        image.w /= UInt16(scale)
        image.texture_h /= UInt16(scale)
        image.texture_w /= UInt16(scale)
        image.base_h /= UInt16(scale)
        image.base_w /= UInt16(scale)

        rawPointer.pointee = image
    }

    deinit {
        GPU_FreeImage(rawPointer)
    }
}
