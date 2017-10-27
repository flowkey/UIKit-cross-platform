//
//  ShaderProgram.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.gpu

// A ShaderProgram consists of a VertexShader and a FragmentShader linked together
// This is a class because Shaders need to be freed after use
class ShaderProgram {
    /// References a variable found inside the shader program. -1 means not found or not used.
    typealias ShaderVariableLocationID = Int32

    var programRef: UInt32
    private var shaderBlock: GPU_ShaderBlock

    enum Error: Swift.Error {
        case noRenderer
        case linkingFailed(reason: String)
    }

    init(vertexShader: VertexShader, fragmentShader: FragmentShader) throws {
        guard GPU_GetCurrentRenderer() != nil else {
            throw Error.noRenderer
        }

        programRef = GPU_LinkShaders(vertexShader.shaderRef, fragmentShader.shaderRef)

        if programRef == 0 {
            let errorMessage = String(cString: GPU_GetShaderMessage())
            throw Error.linkingFailed(reason: errorMessage)
        }

        // NOTE: This hardcodes the names of the various coordinates
        // It's possible we should allow overriding these somehow, for now it doesn't matter
        shaderBlock = GPU_LoadShaderBlock(
            programRef,
            "gpu_Vertex",
            "gpu_TexCoord",
            "gpu_Color",
            "gpu_ModelViewProjectionMatrix"
        )
    }

    func activate() {
        GPU_ActivateShaderProgram(programRef, &shaderBlock)
    }

    deinit {
        GPU_FreeShaderProgram(programRef)
    }
}


extension ShaderProgram {
    static func deactivateAll() {
        GPU_ActivateShaderProgram(0, nil)
    }
}
