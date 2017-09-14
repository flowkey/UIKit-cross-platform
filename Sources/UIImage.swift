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

    // public convenience init?(data: Data) {
    //     var imageData = data.base64EncodedData()
    //     let freesrc = Int32(1) // non-zero to close the stream after being read

    //     guard
    //         let ptr = SDL_RWFromMem(&imageData, Int32(imageData.count)), // XXX: I have no idea what I'm doing here
    //         let image = SDL_LoadBMP_RW(ptr, freesrc),
    //         let texture = Texture(surface: image)
    //      else {
    //         return nil
    //     }

    //     self.init(texture: texture)
    // }
    
    init(texture: Texture) {
        self.texture = texture
        self.size = texture.size
        scale = 2 // TODO: get from last path component
    }
}
