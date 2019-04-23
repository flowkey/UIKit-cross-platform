//
//  Mask.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL_gpu

extension ShaderProgram {
    static let mask = try! MaskShaderProgram()
}

class MaskShaderProgram: ShaderProgram {
    private var maskFrame: UniformVariable!
    private var maskTexture: UniformVariable!

    // we only need one MaskShaderProgram, which we can / should treat as a singleton
    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .maskColourWithImage)
        maskFrame = UniformVariable("maskFrame", in: programRef)
        maskTexture = UniformVariable("maskTexture", in: programRef)
    }

    func set(maskImage: CGImage, frame: CGRect) {
        maskFrame.set(frame)
        maskTexture.set(maskImage)
    }
}
