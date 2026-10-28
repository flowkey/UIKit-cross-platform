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
    private var roundedCorners: UniformVariable!
    private var blurRadius: UniformVariable!

    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .roundedRectShadow)
        rectFrame = UniformVariable("rectFrame", in: programRef)
        cornerRadius = UniformVariable("cornerRadius", in: programRef)
        roundedCorners = UniformVariable("roundedCorners", in: programRef)
        blurRadius = UniformVariable("blurRadius", in: programRef)
    }

    /// Set the rounded-rect shadow uniforms. (The caller — `UIScreen.shadow` — expands the draw
    /// quad by `blur` so the feathered edge isn't clipped.)
    func setShadow(rect: CGRect, cornerRadius radius: CGFloat, maskedCorners: CACornerMask, blurRadius blur: CGFloat) {
        rectFrame.set(rect)
        cornerRadius.set(Float(radius))
        roundedCorners.set(maskedCorners)
        blurRadius.set(Float(blur))
    }
}
