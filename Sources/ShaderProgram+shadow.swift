//
//  ShaderProgram+shadow.swift
//  UIKit
//

internal import SDL_gpu

extension ShaderProgram {
    private static var _shadow: ShadowShaderProgram?
    static var shadow: ShadowShaderProgram {
        if let existing = _shadow { return existing }
        let program = try! ShadowShaderProgram()
        _shadow = program
        return program
    }
    static func invalidateShadow() { _shadow = nil }
}

class ShadowShaderProgram: ShaderProgram {
    private var rectFrame: UniformVariable!
    private var cornerRadius: UniformVariable!
    private var blurRadius: UniformVariable!

    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .roundedRectShadow)
        rectFrame = UniformVariable("rectFrame", in: programRef)
        cornerRadius = UniformVariable("cornerRadius", in: programRef)
        blurRadius = UniformVariable("blurRadius", in: programRef)
    }

    /// Configure a feathered rounded-rect drop shadow: solid inside `rect`, fading to
    /// zero over `blur` pixels outside it. Draw a quad expanded by `blur` on every side
    /// so the feathered edge isn't clipped by the draw rectangle.
    func setShadow(rect: CGRect, cornerRadius radius: CGFloat, blurRadius blur: CGFloat) {
        rectFrame.set(rect)
        cornerRadius.set(Float(radius))
        blurRadius.set(Float(blur))
    }
}
