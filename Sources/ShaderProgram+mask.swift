//
//  Mask.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL_gpu

extension ShaderProgram { 
    private static var _mask: MaskShaderProgram?
    static var mask: MaskShaderProgram {
        if let existing = _mask { return existing }
        let program = try! MaskShaderProgram(fragmentShader: .maskColourWithImage)
        _mask = program
        return program
    }

    // Masks a textured layer (samples its own contents) by an image's alpha.
    private static var _maskImage: MaskShaderProgram?
    static var maskImage: MaskShaderProgram {
        if let existing = _maskImage { return existing }
        let program = try! MaskShaderProgram(fragmentShader: .maskImageWithImage)
        _maskImage = program
        return program
    }

    static func invalidateMask() { _mask = nil; _maskImage = nil }
}

class MaskShaderProgram: ShaderProgram {
    private var maskFrame: UniformVariable!
    private var maskTexture: UniformVariable!

    fileprivate init(fragmentShader: FragmentShader) throws {
        try super.init(vertexShader: .common, fragmentShader: fragmentShader)
        maskFrame = UniformVariable("maskFrame", in: programRef)
        maskTexture = UniformVariable("maskTexture", in: programRef)
    }

    func set(maskImage: CGImage, frame: CGRect) {
        maskFrame.set(frame)
        maskTexture.set(maskImage)
    }
}
