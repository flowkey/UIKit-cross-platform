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
        \(`out`) vec2 texCoord;

        void main(void)
        {
            originalColour = gpu_Color;
            absolutePixelPos = vec2(gpu_Vertex.xy);
            texCoord = gpu_TexCoord;
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

    private static var _roundedRectShadow: FragmentShader?
    static var roundedRectShadow: FragmentShader {
        if let existing = _roundedRectShadow { return existing }
        let shader = try! FragmentShader(source: roundedRectShadowSource)
        _roundedRectShadow = shader
        return shader
    }

    private static var _gradient: FragmentShader?
    static var gradient: FragmentShader {
        if let existing = _gradient { return existing }
        let shader = try! FragmentShader(source: gradientSource)
        _gradient = shader
        return shader
    }

    static func invalidateAll() {
        _maskColourWithImage = nil
        _roundedRect = nil
        _roundedRectShadow = nil
        _gradient = nil
    }

    private static let maskColourWithImageSource = """
        \(`in`) vec4 originalColour;
        \(`in`) vec2 absolutePixelPos;
        \(`in`) vec2 texCoord;

        \(fragColorDefinition)

        uniform vec4 maskFrame;
        uniform sampler2D maskTexture;
        uniform sampler2D tex; // the masked layer's own contents (blit image, texture unit 0)

        void main(void)
        {
            vec2 maskCoordinate = vec2(
                ((absolutePixelPos.x - maskFrame.x) / maskFrame.w),
                ((absolutePixelPos.y - maskFrame.y) / maskFrame.z) // z == height
            );

            vec4 maskColour = \(texture)(maskTexture, maskCoordinate);
            vec4 base = \(texture)(tex, texCoord) * originalColour;
            \(fragColor) = vec4(base.rgb, base.a * maskColour.a);
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

            // Centred anti-aliasing: the fade straddles the true boundary (d in [-aa, aa]), so the
            // 50%-coverage contour lands exactly on the geometric edge and the shape keeps its real
            // size. The caller snaps this rect's edges to the pixel grid, so on straight runs no pixel
            // centre falls in the fade band (crisp, seam-free edges); the corner arcs still cross pixel
            // centres, so that's effectively the only place the fade is visible.
            float outer = 1.0 - smoothstep(-aa, aa, d);
            float inner = 1.0 - smoothstep(-aa, aa, d + borderWidth);
            float alpha = outer - inner;

            \(fragColor) = vec4(originalColour.rgb, originalColour.a * alpha);
        }
        """

    // SDF rounded-rect drop shadow: like the rounded-rect fill but with a soft, symmetric edge
    // falloff (`blurRadius`) instead of a 1px AA — the SDL renderer has no automatic layer shadow,
    // so this draws a blurred rounded rect to mimic Core Animation's `shadow*` (the caller passes
    // the shape rect — the layer bounds or its shadowPath).
    private static let roundedRectShadowSource = """
        \(`in`) vec4 originalColour;
        \(`in`) vec2 absolutePixelPos;

        \(fragColorDefinition)

        uniform vec4 rectFrame;
        uniform float cornerRadius;
        uniform float blurRadius;

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

            // Soft, symmetric falloff centred on the shape edge (approximates a Gaussian):
            // it reads as a blurred shadow rather than a hard offset band. The edge sits at
            // 50% and fades to 0 by `blurRadius` outside / to 1 by `blurRadius` inside.
            float blur = max(blurRadius, 1e-5);
            float alpha = 1.0 - smoothstep(-blur, blur, d);

            \(fragColor) = vec4(originalColour.rgb, originalColour.a * alpha);
        }
        """

    // Per-fragment colour gradient (CAGradientLayer). Keep in sync with `GradientShaderProgram.maxStops`.
    static let maxGradientStops = 16
    private static let gradientSource = """
        #define MAX_GRADIENT_STOPS \(maxGradientStops)

        \(`in`) vec2 absolutePixelPos;

        \(fragColorDefinition)

        uniform vec4 rectFrame; // (x, y, height, width) — same packing as roundedRect/mask
        uniform vec2 startPoint;
        uniform vec2 endPoint;
        uniform int colorCount;
        uniform vec4 colors[MAX_GRADIENT_STOPS];
        uniform float locations[MAX_GRADIENT_STOPS];

        void main(void)
        {
            vec2 p = (absolutePixelPos - vec2(rectFrame.x, rectFrame.y)) / vec2(rectFrame.w, rectFrame.z);

            vec2 dir = endPoint - startPoint;
            float len2 = dot(dir, dir);
            float t = len2 > 0.00001 ? dot(p - startPoint, dir) / len2 : 0.0;
            t = clamp(t, 0.0, 1.0);

            vec4 color = colors[0];
            if (t <= locations[0]) {
                color = colors[0];
            } else if (t >= locations[colorCount - 1]) {
                color = colors[colorCount - 1];
            } else {
                for (int i = 0; i < colorCount - 1; i++) {
                    float loc0 = locations[i];
                    float loc1 = locations[i + 1];
                    if (t >= loc0 && t <= loc1) {
                        float localT = (t - loc0) / max(loc1 - loc0, 0.000001);
                        color = mix(colors[i], colors[i + 1], localT);
                        break;
                    }
                }
            }

            \(fragColor) = color;
        }
        """
}
