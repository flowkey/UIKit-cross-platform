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
        let program = try! MaskShaderProgram()
        _mask = program
        return program
    }
    static func invalidateMask() { _mask = nil }
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
