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

    // Rasterise the gradient once into `contents` on the GPU (render-to-texture), then the render walk
    // blits that cached texture each frame like any image — recomputing only when the gradient changes
    // (`setNeedsDisplay`). See the note in `display()` about disabling the render target's camera.
    @_optimize(speed)
    override open func display() {
        super.display()

        if bounds.width.isZero || bounds.height.isZero { return }

        // Fill in implicit stop locations and collapse the degenerate cases.
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

        // Render-to-texture needs a live renderer/context. `display()` only runs inside the render walk
        // (where the context is current), but guard so a stray call can't crash.
        guard UIScreen.main != nil else { return }

        let pixelWidth = Int(bounds.width * contentsScale)
        let pixelHeight = Int(bounds.height * contentsScale)
        guard pixelWidth > 0, pixelHeight > 0 else { return }

        // Reuse the existing texture when it's already the right size, otherwise allocate one.
        let image: CGImage
        if let existing = contents, existing.width == pixelWidth, existing.height == pixelHeight {
            image = existing
        } else {
            guard let newImage = CGImage(width: pixelWidth, height: pixelHeight) else { return }
            image = newImage
        }

        guard let target = GPU_GetTarget(image.rawPointer) else { return }

        // `display()` runs mid-render-walk, where a clip rect (screen-space GL scissor) may be active and
        // the model-view holds the layer's on-screen transform — both would wrongly affect our offscreen
        // draw. Disable them, and crucially disable the target's CAMERA: the shader's transform is
        // camera × projection × modelview, and image targets default to `use_camera = true` (inverted),
        // which otherwise pushes our rect off the target. With the camera off + a plain ortho + identity
        // model-view, the rect (0,0,w,h) maps 1:1 onto the whole texture.
        let savedClippingRect = UIScreen.main?.clippingRect
        UIScreen.main?.clippingRect = nil
        GPU_FlushBlitBuffer()

        GPU_EnableCamera(target, false)
        GPU_MatrixMode(GPU_PROJECTION); GPU_PushMatrix(); GPU_LoadIdentity()
        GPU_Ortho(0, Float(pixelWidth), Float(pixelHeight), 0, -1, 1)
        GPU_MatrixMode(GPU_MODELVIEW); GPU_PushMatrix(); GPU_LoadIdentity()

        GPU_SetViewport(target, GPU_Rect(x: 0, y: 0, w: Float(pixelWidth), h: Float(pixelHeight)))
        GPU_SetShapeBlending(false) // write the gradient's own straight alpha, don't blend into the cleared texture
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

        ShaderProgram.deactivateAll()
        GPU_FlushBlitBuffer()

        GPU_MatrixMode(GPU_MODELVIEW); GPU_PopMatrix()
        GPU_MatrixMode(GPU_PROJECTION); GPU_PopMatrix()
        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_SetShapeBlending(true)
        UIScreen.main?.clippingRect = savedClippingRect

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
