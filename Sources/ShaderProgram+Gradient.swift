//
//  Mask.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL_gpu

extension ShaderProgram {
    static let gradient = try! GradientShaderProgram()
}

final class GradientShaderProgram: ShaderProgram {
    private var colorCount: UniformVariable!
    private var gradientColors: UniformVariable!
    private var gradientLocations: UniformVariable!

    private var startPoint: UniformVariable!
    private var endPoint: UniformVariable!

    // we only need one MaskShaderProgram, which we can / should treat as a singleton
    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .gradient)
        colorCount = UniformVariable("colorCount", in: programRef)
        gradientColors = UniformVariable("gradientColors", in: programRef)
        gradientLocations = UniformVariable("gradientLocations", in: programRef)

        startPoint = UniformVariable("startPoint", in: programRef) // in [0,1] layer space
        endPoint = UniformVariable("endPoint", in: programRef) // in [0,1] layer space
    }

    func set(colors: consuming [CGColor]) {
        let count = min(8, colors.count)
        colorCount.set(Int32(count))
        withUnsafeTemporaryAllocation(of: Float.self, capacity: count * 4, { ptr in
            for i in 0 ..< count {
                let outBaseIndex = i * 4
                ptr[outBaseIndex + 0] = Float(colors[i].redValue) / 255.0
                ptr[outBaseIndex + 1] = Float(colors[i].greenValue) / 255.0
                ptr[outBaseIndex + 2] = Float(colors[i].blueValue) / 255.0
                ptr[outBaseIndex + 3] = Float(colors[i].alphaValue) / 255.0
            }

            gradientColors.set(ptr)
        })
    }

    func set(locations: consuming [Float]) {
        gradientLocations.set(locations[0 ..< min(8, locations.count)])
    }
}

extension FragmentShader {
    static let gradient = try! FragmentShader(source: """
        \(`in`) vec4 originalColour;
        \(`in`) vec2 absolutePixelPos;

        \(fragColorDefinition)

        const int MAX_COLORS = 8; // arbitrary but 'should be enough'

        uniform int   colorCount;
        uniform vec4  gradientColors[MAX_COLORS];
        uniform float gradientLocations[MAX_COLORS];  // values in [0,1]

        uniform vec2 startPoint; // in [0,1] layer space
        uniform vec2 endPoint;   // in [0,1] layer space

        vec4 sampleGradient(float t) {
            t = clamp(t, 0.0, 1.0);

            // Handle outside explicit locations: use first / last
            if (t <= gradientLocations[0]) {
                return gradientColors[0];
            }
            if (t >= gradientLocations[colorCount - 1]) {
                return gradientColors[colorCount - 1];
            }

            // Find the two stops [i, i+1] that contain t
            for (int i = 0; i < MAX_COLORS - 1; ++i) {
                if (i >= colorCount - 1) {
                    break;
                }

                float loc0 = gradientLocations[i];
                float loc1 = gradientLocations[i + 1];

                if (t >= loc0 && t <= loc1) {
                    float localT = (t - loc0) / (loc1 - loc0);
                    return mix(gradientColors[i], gradientColors[i + 1], localT);
                }
            }

            // Fallback (shouldn't happen if above logic is correct)
            return gradientColors[colorCount - 1];
        }

        void main() {
            // p is the point in 'layer space' [0,1]×[0,1]
            vec2 p = (absolutePixelPos * 0.5) + 0.5;

            // Match iOS's Y-down coordinates:
            p.y = 1.0 - p.y;

            // Direction of gradient line
            vec2 dir = endPoint - startPoint;
            float len2 = dot(dir, dir);

            float t = 0.0;
            if (len2 > 0.00001) {
                // Project (p - startPoint) onto the gradient direction
                t = dot(p - startPoint, dir) / len2;
            }

            t = clamp(t, 0.0, 1.0);

            \(fragColor) = sampleGradient(t);
        }
        """
    )
}
