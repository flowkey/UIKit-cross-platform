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
        self.size = texture.size
        scale = 2 // TODO: get from last path component
    }
    
    public init?(iconName: String, fontName: String, fontSize: CGFloat, color: UIColor) {
        let font = UIFont(fontFileName: fontName, fontSize: fontSize)
        guard let fontTexture = font.render(iconName, color: color) else { return nil }
        texture = fontTexture
        size = fontTexture.size
        scale = 2 // TODO: get from last path component
    }
}
