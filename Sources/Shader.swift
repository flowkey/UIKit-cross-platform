//
//  Shader.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_implementationOnly import SDL_gpu

class VertexShader: Shader {
    // Some keywords have changed since the earlier shader language versions available on Android:
    #if os(Android) // GLES/GLSL:
    static let `in` = "attribute"
    static let `out` = "varying"
    #else // OpenGL:
    static let `in` = "in"
    static let `out` = "out"
    #endif

    init(source: String) throws {
        try super.init(source, type: GPU_VERTEX_SHADER)
    }
}

class FragmentShader: Shader {
    // Some keywords have changed since the earlier shader language versions available on Android:
    #if os(Android) // GLES/GLSL:
    static let `in` = "varying"
    static let texture = "texture2D"
    static let fragColor = "gl_FragColor"
    static let fragColorDefinition = "" // magically predefined by the driver
    #else // OpenGL:
    static let `in` = "in"
    static let texture = "texture"
    static let fragColor = "fragColor"
    static let fragColorDefinition = "out vec4 \(fragColor);"
    #endif

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

    // To be overriden in subclasses
    // e.g. We need to do different overrides depending on whether we're in a vertex / fragment shader
//    static func transformedSource(_ source: String) -> String {
//        if self is VertexShader {
//            return source
//                .replacingOccurrences(of: "(^|\n)in", with: "\nattribute", options: .regularExpression)
//                .replacingOccurrences(of: "(^|\n)out", with: "\nvarying", options: .regularExpression)
//                .replacingOccurrences(of: "(^|\n)texture", with: "\ntexture2D", options: .regularExpression)
//        } else {
//            return source
//        }
//    }

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
            precision highp int;
            precision highp float;
            """
        default:
            throw Error.unknownRendererShaderLanguage
        }

        let fullShaderSource = """
            \(header)
            \(source)
            """
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
