//
//  UIImage+SDL.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 10.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

public class UIImage {
    var texture: Texture

    public let size: CGSize
    public let scale: Double

    public init?(path: String) {
        guard let texture = Texture(imagePath: path) else { return nil }
        self.texture = texture
        self.size = CGSize(width: texture.width, height: texture.height)
        scale = 2 // TODO: get from last path component
    }
}
