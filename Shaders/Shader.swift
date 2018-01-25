//
//  Shader.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import Foundation
import SDL_gpu


class VertexShader: Shader {
    init(source: String) throws {
        try super.init(source, type: GPU_VERTEX_SHADER)
    }
}

class FragmentShader: Shader {
    init(source: String) throws {
        try super.init(source, type: GPU_FRAGMENT_SHADER)
    }
}


class Shader {
    let shaderRef: UInt32

    enum Error: Swift.Error {
        case noRenderer
        case unknownRendererShaderLanguage
        case compilationFailed(reason: String)
    }

    // Some hardware (from ATI/AMD) does not let you put non-#version preprocessing at the top of the file. Adds the
    // appropriate header before compiling, allowing us to use the same shader across different OPENGL(ES) versions..
    fileprivate init(_ source: String, type: GPU_ShaderEnum) throws {
        guard let renderer = GPU_GetCurrentRenderer() else {
            throw Error.noRenderer
        }

        let header: String

        switch renderer.pointee.shader_language {
        case GPU_LANGUAGE_GLSL:
            header = "#version \(renderer.pointee.max_shader_version)"
        case GPU_LANGUAGE_GLSLES:
            header = """
            #version 100
            precision mediump int;
            precision mediump float;
            """
        default:
            throw Error.unknownRendererShaderLanguage
        }

        let fullShaderSource = (header + "\n" + source)
        shaderRef = GPU_CompileShader(type, fullShaderSource)

        if shaderRef == 0 {
            let errorMessage = String(cString: GPU_GetShaderMessage())
            throw Error.compilationFailed(reason: errorMessage)
        }
    }

    deinit {
        GPU_FreeShader(shaderRef)
    }
}
