//
//  MaskingShaders.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension VertexShader {
    static let common = try! VertexShader(source:
        """
        \(`in`) vec3 gpu_Vertex;
        \(`in`) vec2 gpu_TexCoord;
        \(`in`) vec4 gpu_Color;
        uniform mat4 gpu_ModelViewProjectionMatrix;

        \(`out`) vec4 originalColour;
        \(`out`) vec2 absolutePixelPos;

        void main(void)
        {
            originalColour = gpu_Color;
            absolutePixelPos = vec2(gpu_Vertex.xy);
            gl_Position = gpu_ModelViewProjectionMatrix * vec4(gpu_Vertex, 1.0);
        }
        """
    )
}

extension FragmentShader {
    static let maskColourWithImage = try! FragmentShader(source: """
        \(`in`) vec4 originalColour;
        \(`in`) vec2 absolutePixelPos;

        \(fragColorDefinition)

        uniform vec4 maskFrame;
        uniform sampler2D maskTexture;

        void main(void)
        {
            vec2 maskCoordinate = vec2(
                ((absolutePixelPos.x - maskFrame.x) / maskFrame.w),
                ((absolutePixelPos.y - maskFrame.y) / maskFrame.z) // z == height
            );

            vec4 maskColour = \(texture)(maskTexture, maskCoordinate);
            \(fragColor) = vec4(originalColour.rgb, originalColour.a * maskColour.a);
        }
        """
    )
}
