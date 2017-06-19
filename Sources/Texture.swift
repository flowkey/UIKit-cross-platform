//
//  Texture.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal final class Texture {
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
