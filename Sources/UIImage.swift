//
//  UIImage+SDL.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 10.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL
import SDL_gpu
import Foundation

public class UIImage {
    public let cgImage: CGImage

    public var size: CGSize { return cgImage.size }
    public let scale: CGFloat

    public init(cgImage: CGImage, scale: CGFloat) {
        self.cgImage = cgImage
        self.scale = scale
    }

    public convenience init?(path: String) {
        guard let cgImage = CGImage(GPU_LoadImage(path)) else { return nil }

        let pathWithoutExtension = String(path.dropLast(4))
        let scale: CGFloat
        if pathWithoutExtension.hasSuffix("@2x") {
            scale = 2.0
        } else if pathWithoutExtension.hasSuffix("@3x") {
            scale = 3.0
        } else {
            scale = 1.0
        }

        self.init(cgImage: cgImage, scale: scale)
    }

    public convenience init?(data: Data) {
        var data = data
        let dataCount = Int32(data.count)
        let gpuImagePtr = data.withUnsafeMutableBytes { (ptr: UnsafeMutablePointer<Int8>) -> UnsafeMutablePointer<GPU_Image>? in
            let rw = SDL_RWFromMem(ptr, dataCount)
            return GPU_LoadImage_RW(rw, false)
        }

        guard let cgImage = CGImage(gpuImagePtr) else { return nil }
        self.init(cgImage: cgImage, scale: 1.0) // matches iOS
    }
}
