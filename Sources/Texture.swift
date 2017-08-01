//
//  Texture.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

internal final class Texture {
    let rawPointer: UnsafeMutablePointer<GPU_Image>

    var scale: Float = 2 // TODO: get from window

    var size: CGSize {
        return CGSize(width: Int(rawPointer.pointee.w), height: Int(rawPointer.pointee.h))
    }

    init?(imagePath: String) {
        guard let image = GPU_LoadImage(imagePath) else { return nil }
        rawPointer = image
        GPU_SetSnapMode(rawPointer, GPU_SNAP_POSITION_AND_DIMENSIONS)
        GPU_SetImageFilter(rawPointer, GPU_FILTER_NEAREST)
        scaleImage(scale)
    }
    
    init?(surface: UnsafeMutablePointer<SDLSurface>) {
        guard let image = GPU_CopyImageFromSurface(surface) else { return nil }
        rawPointer = image
        GPU_SetSnapMode(rawPointer, GPU_SNAP_POSITION_AND_DIMENSIONS)
        scaleImage(scale)
    }

    init?(gpuImage: GPU_Image) {
        let gpuImagePointer = UnsafeMutablePointer<GPU_Image>.allocate(capacity: 1)
        gpuImagePointer.initialize(to: gpuImage)

        rawPointer = gpuImagePointer
    }

    init(width: Int, height: Int, format: GPU_FormatEnum) {
        let scale = 1
        let image = GPU_CreateImage(UInt16(width), UInt16(height), format)
        rawPointer = image!
        GPU_SetAnchor(rawPointer, 0, 0)
        self.scale = Float(scale)
    }

    func replacePixels(with bytes: UnsafePointer<UInt8>, bytesPerPixel: Int) {
        var rect = GPU_Rect(x: 0, y: 0, w: Float(rawPointer.pointee.w), h: Float(rawPointer.pointee.h))
        GPU_UpdateImageBytes(rawPointer, &rect, bytes, Int32(rawPointer.pointee.w) * Int32(bytesPerPixel))
    }

    private func scaleImage(_ scale: Float) {
        var image = rawPointer.pointee
        let scale = UInt16(2) // XXX: get this from image path
        self.scale = Float(scale)
        
        // Setting the scale here allows the texture to render at the expected size automatically
        image.h /= scale
        image.w /= scale
        image.texture_h /= scale
        image.texture_w /= scale
        image.base_h /= scale
        image.base_w /= scale

        rawPointer.pointee = image
        GPU_SetAnchor(rawPointer, 0, 0)
    }

    deinit {
        GPU_FreeImage(rawPointer)
    }
}
