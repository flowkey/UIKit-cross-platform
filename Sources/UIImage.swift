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
    public let cgImage: CGImage

    public var size: CGSize { return cgImage.size }
    public let scale: CGFloat

    public init(cgImage: CGImage, scale: CGFloat) {
        self.cgImage = cgImage
        self.scale = scale
    }

    public convenience init?(path: String) {
        guard let cgImage = CGImage(imagePath: path) else { return nil }
        self.init(cgImage: cgImage, scale: 1.0) // TODO: get scale from last path component
    }

    public convenience init?(data: Data) {
        guard let cgImage = CGImage(data: data, scale: 1) else { return nil }
        self.init(cgImage: cgImage, scale: 1)
    }
}
