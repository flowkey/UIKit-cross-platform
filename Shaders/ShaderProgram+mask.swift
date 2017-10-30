//
//  Mask.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.gpu

extension ShaderProgram {
    static let mask = try! MaskShaderProgram()
}

class MaskShaderProgram: ShaderProgram {
    private var maskFrame: UniformVariable!
    private var maskMinY: UniformVariable!
    private var maskWidth: UniformVariable!
    private var maskHeight: UniformVariable!
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

extension ShaderProgram {
    struct UniformVariable {
        let location: ShaderVariableLocationID
        init(_ name: String, in programRef: UInt32) {
            location = GPU_GetUniformLocation(programRef, name)
            assert(location != -1, "Couldn't find location of UniformVariable \(name)")
        }

        func set(_ newValue: Float) {
            GPU_SetUniformf(location, newValue)
        }

        func set (_ newValue: CGRect) {
            var vals = [Float(newValue.minX), Float(newValue.minY), Float(newValue.height), Float(newValue.width)]
            GPU_SetUniformfv(location, 4, 1, &vals)
        }

        func set(_ newValue: CGImage) {
            let textureUnit: Int32 = 1 // Texture unit 0 is the one used internally for SDL_gpu's blitting funcs
            GPU_SetShaderImage(newValue.rawPointer, location, textureUnit)
        }
    }
}
