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
        // since all the sheets seem to have a scale factor of two, we have to pass this scale factor,
        // otherwise on lower dpi screens they appear too big (e.g. on external Full HD screen with a windows scale of 1)
        guard let texture = Texture(data: data, scale: 2) else {
            return nil
        }
        self.init(texture: texture)
    }

    init(texture: Texture) {
        self.texture = texture
        self.size = texture.size
        scale = 2 // TODO: get from last path component
    }
}
