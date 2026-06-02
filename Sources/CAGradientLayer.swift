internal import SDL
private import SDL_gpu

open class CAGradientLayer: CALayer {
    public var colors: [CGColor] = [] {
        didSet {
            _colors = colors.map {
                SIMD4<CGFloat>(
                    x: CGFloat($0.redValue) / 255,
                    y: CGFloat($0.greenValue) / 255,
                    z: CGFloat($0.blueValue) / 255,
                    w: CGFloat($0.alphaValue) / 255
                )
            }
            setNeedsDisplay()
        }
    }

    private var _colors: [SIMD4<CGFloat>] = []

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

        let width: Int32
        let height: Int32

        if startPoint.x == endPoint.x {
            width = 1
            height = Int32(bounds.height * self.contentsScale)
        } else if startPoint.y == endPoint.y {
            width = Int32(bounds.width * self.contentsScale)
            height = 1
        } else {
            // pessimistic case where we need to fill the entire thing
            width = Int32(bounds.width * self.contentsScale)
            height = Int32(bounds.height * self.contentsScale)
        }

        guard let surface = SDL_CreateRGBSurfaceWithFormat(
            0, // surface flags are always 0 in SDL2
            width,
            height,
            32, // bit depth
            UInt32(SDL_PIXELFORMAT_RGBA32)
        ) else {
            return
        }

        SDL_LockSurface(surface)

        let startPoint = SIMD2(x: self.startPoint.x, y: self.startPoint.y)
        let endPoint = SIMD2(x: self.endPoint.x, y: self.endPoint.y)

        for y in 0 ..< Int(height) {
            let pixelPosY = y * Int(surface.pointee.pitch)

            for x in 0 ..< Int(width) {
                let pixel = surface.pointee.pixels.assumingMemoryBound(to: UInt8.self)
                    .advanced(by: pixelPosY)
                    .advanced(by: x * Int(surface.pointee.format.pointee.BytesPerPixel))

                let p = SIMD2(x: CGFloat(x) / bounds.width, y: CGFloat(y) / bounds.height)

                // Direction of gradient line
                let dir = endPoint - startPoint
                let len2 = dot(dir, dir)

                var t: CGFloat = 0.0
                if len2 > 0.00001 {
                    // Project (p - startPoint) onto the gradient direction
                    t = dot(p - startPoint, dir) / len2
                }

                t = max(0.0, min(t, 1.0))
                let color = sampleGradient(t)

                let normalized = color * 255
                pixel[0] = UInt8(clamping: Int(normalized.x))
                pixel[1] = UInt8(clamping: Int(normalized.y))
                pixel[2] = UInt8(clamping: Int(normalized.z))
                pixel[3] = UInt8(clamping: Int(normalized.w))
            }
        }

        SDL_UnlockSurface(surface)

        if
            let contents,
            contents.width != Int(bounds.width) ||
            contents.height != Int(bounds.height)
        {
            contents.replacePixels(
                with: surface.pointee.pixels.assumingMemoryBound(to: UInt8.self)
            )
        } else {
            contents = CGImage(surface: surface)
        }
    }

    @_optimize(speed)
    func sampleGradient(_ position: CGFloat) -> SIMD4<CGFloat> {
        precondition(colors.count >= 2)
        precondition(locations.count >= 2)

        let t = Float(max(0.0, min(position, 1.0)))

        if t <= locations.first! {
            return _colors.first!
        } else if t >= locations.last! {
            return _colors.last!
        }

        // Find stops [i, i+1] containing t
        for i in 0 ..< (colors.count - 1) {
            let loc0 = locations[i]
            let loc1 = locations[i + 1]

            if t >= loc0 && t <= loc1 {
                let localT = (t - loc0) / (loc1 - loc0)
                return mix(_colors[i], _colors[i + 1], t: CGFloat(localT))
            }
        }

        return _colors.last!
    }
}


// GLSL-style mix for SIMD4
@inline(__always)
func mix(_ a: SIMD4<CGFloat>, _ b: SIMD4<CGFloat>, t: CGFloat) -> SIMD4<CGFloat> {
    return a + (b - a) * t
}

@inline(__always)
func dot(_ a: SIMD2<CGFloat>, _ b: SIMD2<CGFloat>) -> CGFloat {
    return a.x * b.x + a.y * b.y
}
