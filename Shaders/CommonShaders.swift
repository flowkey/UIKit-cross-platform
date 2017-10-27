//
//  CommonShaders.swift
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

        out vec4 color;
        out vec2 texCoord;

        void main(void)
        {
            color = gpu_Color;
            texCoord = vec2(gpu_TexCoord);
            gl_Position = gpu_ModelViewProjectionMatrix * vec4(gpu_Vertex, 1.0);
        }
        """
    )
}
