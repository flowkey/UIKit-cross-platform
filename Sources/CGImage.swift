//
//  Texture.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import SDL_gpu
import Foundation

public class CGImage {
    let rawPointer: UnsafeMutablePointer<GPU_Image>
    let size: CGSize

    /**
     Initialize a `CGImage` by passing a reference to a `GPU_Image`, which is usually the result of SDL_gpu's `GPU_*Image*` creation functions. May be null.
     */
    internal init?(_ pointer: UnsafeMutablePointer<GPU_Image>?) {
        guard let pointer = pointer else { return nil }
        rawPointer = pointer

        GPU_SetSnapMode(rawPointer, GPU_SNAP_POSITION_AND_DIMENSIONS)
        GPU_SetImageFilter(rawPointer, GPU_FILTER_NEAREST)
        GPU_SetAnchor(rawPointer, 0, 0)

        let uikit = GPU_BlendMode.uikit
        GPU_SetBlendFunction(rawPointer, uikit.source_color, uikit.dest_color, uikit.source_alpha, uikit.dest_alpha)
        GPU_SetBlendEquation(rawPointer, uikit.color_equation, uikit.alpha_equation)

        // Post-scale size.
        // e.g. If the pixel buffer contains 100x100 pixels at scale 2.0, size will be 50x50:
        size = CGSize(
            width: Int(rawPointer.pointee.w),
            height: Int(rawPointer.pointee.h)
        )

        GPU_GenerateMipmaps(rawPointer)
    }

    convenience init?(surface: UnsafeMutablePointer<SDLSurface>) {
        self.init(GPU_CopyImageFromSurface(surface))
    }

    func replacePixels(with bytes: UnsafePointer<UInt8>, bytesPerPixel: Int) {
        var rect = GPU_Rect(x: 0, y: 0, w: Float(rawPointer.pointee.w), h: Float(rawPointer.pointee.h))
        GPU_UpdateImageBytes(rawPointer, &rect, bytes, Int32(rawPointer.pointee.w) * Int32(bytesPerPixel))
    }

    deinit {
        GPU_FreeImage(rawPointer)
    }
}
