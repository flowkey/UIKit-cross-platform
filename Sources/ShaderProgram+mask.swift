//
//  Mask.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL_gpu

extension ShaderProgram {
    static let maskCompositor = try! MaskCompositing()
}

class MaskCompositing: ShaderProgram {
    private var maskTexture: UniformVariable!

    // we only need one MaskShaderProgram, which we can / should treat as a singleton
    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .maskColourWithImage)
        maskTexture = UniformVariable("maskTexture", in: programRef)
    }

    func set(maskImage: CGImage) {
        maskTexture.set(maskImage)
    }
}

extension VertexShader {
    static let common = try! VertexShader(source:
        """
        \(`in`) vec3 gpu_Vertex;
        \(`in`) vec2 gpu_TexCoord;
        \(`in`) vec4 gpu_Color;
        uniform mat4 gpu_ModelViewProjectionMatrix;

        \(`out`) vec4 color;
        \(`out`) vec2 texCoord;

        void main(void)
        {
            color = gpu_Color;
            texCoord = vec2(gpu_TexCoord);
            gl_Position = gpu_ModelViewProjectionMatrix * vec4(gpu_Vertex, 1.0);
        }
        """
    )
}

extension FragmentShader {
    static let maskColourWithImage = try! FragmentShader(source: """
        \(`in`) vec4 color;
        \(`in`) vec2 texCoord;

        \(fragColorDefinition)
        
        uniform sampler2D tex;
        uniform sampler2D maskTexture;

        void main(void)
        {        
            vec4 base = \(texture)(tex, texCoord) * color;
            float mask = \(texture)(maskTexture, texCoord).a;
            \(fragColor) = vec4(base.rgb, base.a * mask);
        }
        """
    )
}
