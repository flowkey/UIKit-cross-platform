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

    @_optimize(speed)
    override open func display() {
        super.display()

        if bounds.width.isZero || bounds.height.isZero {
            return
        }

        // Fill in implicit stop locations, and collapse the degenerate cases, exactly as before.
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

        // Rasterising on the GPU means we need a live renderer/context. `display()` only runs inside the
        // render walk (`sdlRender`), where the context is current, but guard anyway so a stray call can't crash.
        guard UIScreen.main != nil else { return }

        let pixelWidth = Int(bounds.width * contentsScale)
        let pixelHeight = Int(bounds.height * contentsScale)
        guard pixelWidth > 0, pixelHeight > 0 else { return }

        // Reuse the existing contents texture if it's already the right size, otherwise allocate one.
        // We render *into* this texture, so both the visible-blit path and the mask-sampling path keep
        // consuming `contents` exactly as they did with the old CPU surface.
        let image: CGImage
        if let existing = contents, existing.width == pixelWidth, existing.height == pixelHeight {
            image = existing
        } else {
            guard let newImage = CGImage(width: pixelWidth, height: pixelHeight) else { return }
            image = newImage
        }

        guard let target = GPU_GetTarget(image.rawPointer) else { return }

        // `display()` runs mid-render-walk, where a clip rect may be active for masking. That clip is a
        // global GL scissor set in *screen* coordinates — it would wrongly clip our offscreen draw (and
        // silently blank it entirely when the texture's pixel space doesn't overlap the screen scissor).
        // Disable it while we render into the texture, then restore it for the rest of the frame.
        let savedClippingRect = UIScreen.main?.clippingRect
        UIScreen.main?.clippingRect = nil

        // SDL_gpu batches draws and reconfigures the render target lazily; flush the pending screen batch
        // before switching to our offscreen target so the switch actually takes effect.
        GPU_FlushBlitBuffer()

        // SDL_gpu already installs the right coordinate system for a target when we start rendering into
        // it (a plain draw with the matrices left untouched fills the target correctly). Overriding the
        // projection/modelview ourselves drew nothing, so we deliberately DON'T touch the matrix stacks —
        // we just clear and draw. `gpu_Vertex` (→ the shader's `absolutePixelPos`) then spans 0..w / 0..h.
        // Force this target's viewport to its full area. SDL_gpu doesn't reliably reconfigure the viewport
        // when we render to a second offscreen target within a frame, leaving the previous target's (screen-
        // or sheet-sized) viewport active — under which this target's shape draw maps outside the FBO and
        // nothing lands (while `GPU_Clear`, which ignores the viewport, still works).
        GPU_SetViewport(target, GPU_Rect(x: 0, y: 0, w: Float(pixelWidth), h: Float(pixelHeight)))

        GPU_SetShapeBlending(false) // write the gradient's own straight alpha instead of blending it
        GPU_Clear(target)

        ShaderProgram.gradient.activate()
        ShaderProgram.gradient.set(
            size: CGSize(width: pixelWidth, height: pixelHeight),
            startPoint: startPoint,
            endPoint: endPoint,
            colors: _colors,
            locations: locations
        )
        GPU_RectangleFilled(
            target,
            GPU_Rect(x: 0, y: 0, w: Float(pixelWidth), h: Float(pixelHeight)),
            color: UIColor.white.sdlColor
        )

        ShaderProgram.deactivateAll()
        // Flush our offscreen draw before the render walk resumes drawing to the screen target.
        GPU_FlushBlitBuffer()
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

    private var gradientSize: ShaderVariableLocationID!
    private var startPoint: ShaderVariableLocationID!
    private var endPoint: ShaderVariableLocationID!
    private var colorCount: ShaderVariableLocationID!
    private var colors: ShaderVariableLocationID!
    private var locations: ShaderVariableLocationID!

    fileprivate init() throws {
        try super.init(vertexShader: .common, fragmentShader: .gradient)
        gradientSize = GPU_GetUniformLocation(programRef, "gradientSize")
        startPoint = GPU_GetUniformLocation(programRef, "startPoint")
        endPoint = GPU_GetUniformLocation(programRef, "endPoint")
        colorCount = GPU_GetUniformLocation(programRef, "colorCount")
        colors = GPU_GetUniformLocation(programRef, "colors")
        locations = GPU_GetUniformLocation(programRef, "locations")
    }

    func set(
        size: CGSize,
        startPoint start: CGPoint,
        endPoint end: CGPoint,
        colors colorStops: [SIMD4<Float>],
        locations locationStops: [Float]
    ) {
        let count = Int32(min(colorStops.count, locationStops.count, GradientShaderProgram.maxStops))

        var sizeValues = [Float(size.width), Float(size.height)]
        GPU_SetUniformfv(gradientSize, 2, 1, &sizeValues)

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
