//
//  UIImage+SDL.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 10.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL
import Foundation

public class UIImage {
    var texture: Texture

    public let size: CGSize
    public let scale: Double

    public init?(path: String) {
        guard let texture = Texture(imagePath: path) else { return nil }
        self.texture = texture
        self.size = texture.size
        scale = 2 // TODO: get from last path component
    }

    public convenience init?(data: Data) {
        let imageData = data.base64EncodedData()
        let bufferSize = Int32(imageData.count)

//        let imageDataPtr = (imageData as NSData).bytes
//        let unsafeImageDataPtr = UnsafeMutableRawPointer(mutating: imageDataPtr)

        let unsafeImageDataPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: imageData.count)
        unsafeImageDataPtr.initialize(from: data)

        guard
            let rwOps = SDL_RWFromMem(unsafeImageDataPtr, bufferSize),
            let gpuImagePtr = GPU_LoadImage_RW(rwOps, true),
            let texture = Texture(gpuImage: gpuImagePtr.pointee)
        else {
            print("Could not load image or create texture")
            return nil
        }

//        var texture: Texture? = nil
//        var imageData = data.base64EncodedData()
//        imageData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>)->Void in
//            guard
//                let rwOps = SDL_RWFromMem(bytes, Int32(imageData.count)),
//                let gpuImagePtr = GPU_LoadImage_RW(rwOps, true),
//                let _texture = Texture(gpuImage: gpuImagePtr.pointee)
//            else {
//                print("Could not load image or create texture")
//                return
//            }
//            texture = _texture
//        }
//
//        guard let imageTexture = texture else {
//            return nil
//        }

        self.init(texture: texture)
    }

    init(texture: Texture) {
        self.texture = texture
        self.size = texture.size
        scale = 2 // TODO: get from last path component
    }
}
