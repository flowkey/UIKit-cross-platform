//
//  ShaderProgram.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_implementationOnly import SDL_gpu

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

        func set(_ newValue: CGRect) {
            var vals = [Float(newValue.minX), Float(newValue.minY), Float(newValue.height), Float(newValue.width)]
            GPU_SetUniformfv(location, 4, 1, &vals)
        }

        func set(_ newValue: CGImage) {
            let textureUnit: Int32 = 1 // Texture unit 0 is the one used internally for SDL_gpu's blitting funcs
            GPU_SetShaderImage(newValue.rawPointer, location, textureUnit)
        }
    }
}
