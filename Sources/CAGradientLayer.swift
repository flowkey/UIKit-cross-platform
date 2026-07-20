private import SDL_gpu

open class CAGradientLayer: CALayer {
    public var colors: [CGColor] = [] {
        didSet {
            _colors = colors.map {
                SIMD4<Float>(
                    x: Float($0.redValue) / 255,
                    y: Float($0.greenValue) / 255,
                    z: Float($0.blueValue) / 255,
                    w: Float($0.alphaValue) / 255
                )
            }
            setNeedsDisplay()
        }
    }

    private var _colors: [SIMD4<Float>] = []

    public var locations: [Float] = [] {
        didSet { setNeedsDisplay() }
    }

    public var startPoint = CGPoint(x: 0.5, y: 0.0) {
        didSet { setNeedsDisplay() }
    }

    public var endPoint = CGPoint(x: 0.5, y: 1.0) {
        didSet { setNeedsDisplay() }
    }

    /// Draw the gradient straight to the screen with the gradient shader — GPU-rasterised, with no
    /// intermediate texture (the same mechanism `fill`/`shadow`/`roundedRect` use). Called by the render
    /// walk (`CALayer+SDL`); `rect` is this layer's anchor-relative render rect.
    @_optimize(speed)
    func drawGradient(into renderer: UIScreen, rect: CGRect) {
        guard !colors.isEmpty else { return }

        // Implicit, evenly-spaced stop locations when none (or too few) are provided — matches CAGradientLayer.
        let stops = locations.count >= colors.count
            ? locations
            : colors.indices.map { Float($0) / Float(max(colors.count - 1, 1)) }

        renderer.gradientFill(
            rect,
            startPoint: startPoint,
            endPoint: endPoint,
            colors: _colors,
            locations: stops
        )
    }
}


extension ShaderProgram {
    private static var _gradient: GradientShaderProgram?
    static var gradient: GradientShaderProgram {
        if let existing = _gradient { return existing }
        let program = try! GradientShaderProgram()
        _gradient = program
        return program
    }
    static func invalidateGradient() { _gradient = nil }
}

class GradientShaderProgram: ShaderProgram {
    // Keep in sync with `FragmentShader.maxGradientStops` in the shader source.
    static let maxStops = 16

    private var rectFrame: ShaderVariableLocationID!
    private var startPoint: ShaderVariableLocationID!
    private var endPoint: ShaderVariableLocationID!
    private var colorCount: ShaderVariableLocationID!
    private var colors: ShaderVariableLocationID!
    private var locations: ShaderVariableLocationID!

    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .gradient)
        rectFrame = GPU_GetUniformLocation(programRef, "rectFrame")
        startPoint = GPU_GetUniformLocation(programRef, "startPoint")
        endPoint = GPU_GetUniformLocation(programRef, "endPoint")
        colorCount = GPU_GetUniformLocation(programRef, "colorCount")
        colors = GPU_GetUniformLocation(programRef, "colors")
        locations = GPU_GetUniformLocation(programRef, "locations")
    }

    func set(
        rect: CGRect,
        startPoint start: CGPoint,
        endPoint end: CGPoint,
        colors colorStops: [SIMD4<Float>],
        locations locationStops: [Float]
    ) {
        let count = Int32(min(colorStops.count, locationStops.count, GradientShaderProgram.maxStops))

        // (minX, minY, height, width) — same packing the roundedRect/mask shaders expect.
        var frameValues = [Float(rect.minX), Float(rect.minY), Float(rect.height), Float(rect.width)]
        GPU_SetUniformfv(rectFrame, 4, 1, &frameValues)

        var startValues = [Float(start.x), Float(start.y)]
        GPU_SetUniformfv(startPoint, 2, 1, &startValues)

        var endValues = [Float(end.x), Float(end.y)]
        GPU_SetUniformfv(endPoint, 2, 1, &endValues)

        GPU_SetUniformi(colorCount, count)

        var colorValues = colorStops.prefix(Int(count)).flatMap { [$0.x, $0.y, $0.z, $0.w] }
        GPU_SetUniformfv(colors, 4, count, &colorValues)

        var locationValues = Array(locationStops.prefix(Int(count)))
        GPU_SetUniformfv(locations, 1, count, &locationValues)
    }
}
