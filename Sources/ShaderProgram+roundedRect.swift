//
//  ShaderProgram+roundedRect.swift
//  UIKit
//

internal import SDL_gpu

extension ShaderProgram {
    static let roundedRect = try! RoundedRectShaderProgram()
}

class RoundedRectShaderProgram: ShaderProgram {
    private var rectFrame: UniformVariable!
    private var cornerRadius: UniformVariable!
    private var borderWidth: UniformVariable!

    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .roundedRect)
        rectFrame = UniformVariable("rectFrame", in: programRef)
        cornerRadius = UniformVariable("cornerRadius", in: programRef)
        borderWidth = UniformVariable("borderWidth", in: programRef)
    }

    /// Configure a solid rounded-rect fill.
    func setFill(rect: CGRect, cornerRadius radius: CGFloat) {
        rectFrame.set(rect)
        cornerRadius.set(Float(radius))
        // Any value >= half the smaller dimension collapses the inner edge → solid fill.
        borderWidth.set(Float(max(rect.width, rect.height)))
    }

    /// Configure a rounded-rect ring stroke (border drawn inside `rect`).
    func setStroke(rect: CGRect, cornerRadius radius: CGFloat, borderWidth width: CGFloat) {
        rectFrame.set(rect)
        cornerRadius.set(Float(radius))
        borderWidth.set(Float(width))
    }
}
