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
        scaleImage(scale)
    }
    
    init?(surface: UnsafeMutablePointer<SDLSurface>) {
        guard let image = GPU_CopyImageFromSurface(surface) else { return nil }
        rawPointer = image
        scaleImage(scale)
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

    deinit { GPU_FreeImage(rawPointer) }
}
