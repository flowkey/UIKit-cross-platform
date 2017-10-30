//
//  MaskingShaders.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension FragmentShader {
    static let maskImageWithImage = try! FragmentShader(source: """
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
