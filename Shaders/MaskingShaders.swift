//
//  MaskingShaders.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension FragmentShader {
    static let maskImageWithImage = try! FragmentShader(source: """
        in vec4 color;
        in vec2 texCoord;
        out vec4 fragColor;

        uniform sampler2D mask_texture;

        uniform float offset_x;
        uniform float offset_y;
        uniform float resolution_x;
        uniform float resolution_y;

        uniform float mask_resolution_x;
        uniform float mask_resolution_y;

        void main(void)
        {
            vec4 maskColour = texture(mask_texture, texCoord);
            fragColor = vec4(0.0,0.0,texCoord.y, maskColour.a + 0.5); //vec4(color.r, texCoord.x, texCoord.y, maskColour.a);
        }
        """
    )

//    static let maskColourWithImage = try! FragmentShader(source: """
//        in vec4 color;
//        in vec2 texCoord;
//        out vec4 fragColor;
//
//        uniform sampler2D tex;
//        uniform sampler2D mask_texture;
//
//        uniform float offset_x;
//        uniform float offset_y;
//        uniform float resolution_x;
//        uniform float resolution_y;
//        uniform float mask_resolution_x;
//        uniform float mask_resolution_y;
//
//        void main(void)
//        {
//            vec4 col = texture2D(tex, texCoord);
//            vec2 mask_coords = vec2((texCoord.x*resolution_x + offset_x)/mask_resolution_x, (texCoord.y*resolution_y + offset_y)/mask_resolution_y);
//            vec4 mask = texture2D(mask_tex, mask_coords);
//            fragColor = vec4(col.rgb, col.a*mask.a);
//        }
//        """
//    )
}
