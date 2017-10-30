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
        in vec3 gpu_Vertex;
        in vec2 gpu_TexCoord;
        in vec4 gpu_Color;
        uniform mat4 gpu_ModelViewProjectionMatrix;

        out vec4 originalColour;
        out vec2 absolutePixelPos;

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
        in vec4 originalColour;
        in vec2 absolutePixelPos;

        out vec4 fragColor;

        uniform float maskMinX;
        uniform float maskMinY;
        uniform float maskWidth;
        uniform float maskHeight;
        uniform sampler2D maskTexture;

        void main(void)
        {
            vec2 maskCoordinate = vec2(
                ((absolutePixelPos.x - maskMinX) / maskWidth),
                ((absolutePixelPos.y - maskMinY) / maskHeight)
            );

            vec4 maskColour = texture(maskTexture, maskCoordinate);
            fragColor = vec4(originalColour.rgb, originalColour.a * maskColour.a);
        }
        """
    )
}
