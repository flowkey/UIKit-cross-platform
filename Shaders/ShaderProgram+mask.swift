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
    private var resolutionX: ShaderVariableLocationID = -1
    private var resolutionY: ShaderVariableLocationID = -1
    private var maskResolutionX: ShaderVariableLocationID = -1
    private var maskResolutionY: ShaderVariableLocationID = -1
    private var maskTexture: ShaderVariableLocationID = -1

    // we only need one MaskShaderProgram, which we can / should treat as a singleton
    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .maskImageWithImage)
        resolutionX = GPU_GetUniformLocation(programRef, "resolution_x")
        resolutionY = GPU_GetUniformLocation(programRef, "resolution_y")
        maskResolutionX = GPU_GetUniformLocation(programRef, "mask_resolution_x")
        maskResolutionY = GPU_GetUniformLocation(programRef, "mask_resolution_y")
        maskTexture = GPU_GetUniformLocation(programRef, "mask_texture")

        if //resolutionX == -1 || resolutionY == -1 || maskResolutionX == -1 || maskResolutionY == -1 ||
            maskTexture == -1 {
            fatalError("Couldn't find the location of required shader variables within the compiled shader")
        }
    }

    func set(maskImage: CGImage) {
//        GPU_SetUniformf(maskResolutionX, Float(maskImage.size.width))
//        GPU_SetUniformf(maskResolutionY, Float(maskImage.size.height))

        let textureUnit: Int32 = 1 // Texture unit 0 is the one used internally for SDL_gpu's blitting funcs
        GPU_SetShaderImage(maskImage.rawPointer, maskTexture, textureUnit)
    }
}
