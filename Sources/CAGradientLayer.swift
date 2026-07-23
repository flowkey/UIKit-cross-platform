internal import SDL
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

    // Rasterises the gradient into `contents` on the GPU, cached until the gradient changes.
    @_optimize(speed)
    override open func display() {
        super.display()

        if bounds.width.isZero || bounds.height.isZero { return }

        if locations.count < colors.count {
            if colors.count == 1 {
                backgroundColor = colors[0]
                colors = []
                locations = []
            } else {
                locations = colors.indices.map { Float($0) / Float(colors.count - 1) }
            }
        }

        if colors.isEmpty {
            contents = nil
            return
        }

        guard UIScreen.main != nil else { return }

        let pixelWidth = Int(bounds.width * contentsScale)
        let pixelHeight = Int(bounds.height * contentsScale)
        guard pixelWidth > 0, pixelHeight > 0 else { return }

        let image: CGImage
        if let existing = contents, existing.width == pixelWidth, existing.height == pixelHeight {
            image = existing
        } else {
            guard let newImage = CGImage(width: pixelWidth, height: pixelHeight) else { return }
            image = newImage
        }

        guard let target = GPU_GetTarget(image.rawPointer) else { return }

        // This runs mid-parent-render-pass, so save every piece of shared GL state we touch and restore it
        // via `defer` — that way any early return added below can't leak state into the outer pass.
        let savedClippingRect = UIScreen.main?.clippingRect
        UIScreen.main?.clippingRect = nil
        GPU_FlushBlitBuffer()
        GPU_MatrixMode(GPU_PROJECTION); GPU_PushMatrix()
        GPU_MatrixMode(GPU_MODELVIEW); GPU_PushMatrix()
        GPU_SetShapeBlending(false)
        defer {
            ShaderProgram.deactivateAll()
            GPU_FlushBlitBuffer()
            GPU_MatrixMode(GPU_MODELVIEW); GPU_PopMatrix()
            GPU_MatrixMode(GPU_PROJECTION); GPU_PopMatrix()
            GPU_MatrixMode(GPU_MODELVIEW) // leave mode as the outer render pass expects it
            GPU_SetShapeBlending(true)
            UIScreen.main?.clippingRect = savedClippingRect
        }

        // Disable the target's camera (inverted on image targets) so a plain ortho + identity maps our
        // rect 1:1 onto the texture; otherwise the shader's camera × projection × modelview draws off-target.
        GPU_EnableCamera(target, false)
        GPU_MatrixMode(GPU_PROJECTION); GPU_LoadIdentity()
        GPU_Ortho(0, Float(pixelWidth), Float(pixelHeight), 0, -1, 1)
        GPU_MatrixMode(GPU_MODELVIEW); GPU_LoadIdentity()
        GPU_SetViewport(target, GPU_Rect(x: 0, y: 0, w: Float(pixelWidth), h: Float(pixelHeight)))
        GPU_Clear(target)

        ShaderProgram.gradient.activate()
        ShaderProgram.gradient.set(
            rect: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight),
            startPoint: startPoint,
            endPoint: endPoint,
            colors: _colors,
            locations: locations.count >= colors.count
                ? locations
                : colors.indices.map { Float($0) / Float(max(colors.count - 1, 1)) }
        )
        GPU_RectangleFilled(target, GPU_Rect(x: 0, y: 0, w: Float(pixelWidth), h: Float(pixelHeight)), color: UIColor.white.sdlColor)

        contents = image
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

        // (minX, minY, height, width) — matches the roundedRect/mask uniform packing.
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
