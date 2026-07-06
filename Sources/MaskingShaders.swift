//
//  MaskingShaders.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension VertexShader {
    private static var _common: VertexShader?
    static var common: VertexShader {
        if let existing = _common { return existing }
        let shader = try! VertexShader(source: commonSource)
        _common = shader
        return shader
    }

    static func invalidateAll() { _common = nil }

    private static let commonSource =
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
}

extension FragmentShader {
    private static var _maskColourWithImage: FragmentShader?
    static var maskColourWithImage: FragmentShader {
        if let existing = _maskColourWithImage { return existing }
        let shader = try! FragmentShader(source: maskColourWithImageSource)
        _maskColourWithImage = shader
        return shader
    }

    private static var _roundedRect: FragmentShader?
    static var roundedRect: FragmentShader {
        if let existing = _roundedRect { return existing }
        let shader = try! FragmentShader(source: roundedRectSource)
        _roundedRect = shader
        return shader
    }

    static func invalidateAll() {
        _maskColourWithImage = nil
        _roundedRect = nil
    }

    private static let maskColourWithImageSource = """
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

    // SDF rounded-rect with analytic anti-aliasing.
    // `rectFrame` is laid out the same way as `maskFrame` above (x, y, height, width) so it lines
    // up with `ShaderProgram.UniformVariable.set(_: CGRect)`. `borderWidth` >= half of the smaller
    // dimension collapses the inner edge and produces a solid fill.
    private static let roundedRectSource = """
        \(`in`) vec4 originalColour;
        \(`in`) vec2 absolutePixelPos;

        \(fragColorDefinition)

        uniform vec4 rectFrame;
        uniform float cornerRadius;
        uniform float borderWidth;

        float sdRoundedBox(vec2 p, vec2 b, float r) {
            vec2 q = abs(p) - b + r;
            return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
        }

        void main(void)
        {
            vec2 halfSize = vec2(rectFrame.w, rectFrame.z) * 0.5;
            vec2 center = vec2(rectFrame.x, rectFrame.y) + halfSize;
            float r = min(cornerRadius, min(halfSize.x, halfSize.y));

            float d = sdRoundedBox(absolutePixelPos - center, halfSize, r);
            float aa = max(fwidth(d), 1e-5) * 0.5;

            // Antialias inward (the fade sits at d in [-2aa, 0], entirely inside the shape) so the
            // edge never bleeds past the shape boundary and gets clipped by the draw quad.
            float outer = 1.0 - smoothstep(-2.0 * aa, 0.0, d);
            float inner = 1.0 - smoothstep(-2.0 * aa, 0.0, d + borderWidth);
            float alpha = outer - inner;

            \(fragColor) = vec4(originalColour.rgb, originalColour.a * alpha);
        }
        """
}
