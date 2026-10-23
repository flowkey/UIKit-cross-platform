internal import SDL_gpu

#if os(macOS)
import Foundation
#endif

open class CAShapeLayer: CALayer {
    open var path: CGPath? {
        didSet { strokeSegmentsDidChange() }
    }

    open var fillColor: CGColor? = .black {
        didSet { CALayer.layerTreeIsDirty = true }
    }

    open var strokeColor: CGColor? {
        didSet { CALayer.layerTreeIsDirty = true }
    }

    open var lineWidth: CGFloat = 1 {
        didSet { CALayer.layerTreeIsDirty = true }
    }

    open var lineDashPattern: [NSNumber]? {
        didSet { strokeSegmentsDidChange() }
    }

    open var lineDashPhase: CGFloat = 0 {
        didSet { strokeSegmentsDidChange() }
    }

    /// The visible stretches of the path's lines after dashing, in the layer's coordinates.
    private var strokeSegments: [(from: CGPoint, to: CGPoint)]?

    private func strokeSegmentsDidChange() {
        strokeSegments = nil
        CALayer.layerTreeIsDirty = true
    }

    public required init() {
        super.init()
    }

    public required init(layer: Any) {
        guard let layer = layer as? CAShapeLayer else { fatalError() }
        path = layer.path
        fillColor = layer.fillColor
        strokeColor = layer.strokeColor
        lineWidth = layer.lineWidth
        lineDashPattern = layer.lineDashPattern
        lineDashPhase = layer.lineDashPhase
        strokeSegments = layer.strokeSegments
        super.init(layer: layer)
    }

    open override func copy() -> Any {
        CAShapeLayer(layer: self)
    }

    override func sdlRenderContent(at origin: CGPoint, opacity: Float, renderer: UIScreen) {
        guard let path else { return }

        if path.subpaths.isEmpty {
            let rect = path.boundingBox.offsetBy(origin)
            if let fillColor {
                renderer.fill(rect, with: fillColor.multiplyingAlpha(by: opacity), cornerRadius: path.cornerRadius)
            }
            if let strokeColor, lineWidth > 0 {
                renderer.outline(
                    rect.insetBy(dx: -lineWidth / 2, dy: -lineWidth / 2),
                    lineColor: strokeColor.multiplyingAlpha(by: opacity),
                    lineThickness: lineWidth,
                    cornerRadius: path.cornerRadius + lineWidth / 2
                )
            }
            return
        }

        guard let strokeColor, lineWidth > 0 else { return }
        if strokeSegments == nil { strokeSegments = dashedSegments(of: path) }
        let color = strokeColor.multiplyingAlpha(by: opacity).sdlColor
        let previousLineThickness = GPU_SetLineThickness(Float(lineWidth))
        for segment in strokeSegments ?? [] {
            let from = segment.from + origin, to = segment.to + origin
            GPU_Line(renderer.rawPointer, Float(from.x), Float(from.y), Float(to.x), Float(to.y), color)
        }
        GPU_SetLineThickness(previousLineThickness)
    }

    private func dashedSegments(of path: CGPath) -> [(from: CGPoint, to: CGPoint)] {
        let pattern = (lineDashPattern ?? []).map { CGFloat($0.doubleValue) }.filter { $0 >= 0 }
        var segments: [(from: CGPoint, to: CGPoint)] = []
        for subpath in path.subpaths {
            var points = subpath.points
            if subpath.isClosed, let first = points.first { points.append(first) }
            var dash = DashState(pattern: pattern, phase: lineDashPhase)
            for (start, end) in zip(points, points.dropFirst()) {
                dash.stroke(from: start, to: end) { segments.append(($0, $1)) }
            }
        }
        return segments
    }
}

private struct DashState {
    let pattern: [CGFloat]
    var index = 0
    var remainingInDash: CGFloat
    var isOn: Bool { index % 2 == 0 }

    init(pattern: [CGFloat], phase: CGFloat) {
        self.pattern = pattern.reduce(0, +) > 0 ? pattern : []
        remainingInDash = self.pattern.first ?? .infinity
        var phase = phase
        while !self.pattern.isEmpty, phase > 0 {
            let step = min(phase, remainingInDash)
            phase -= step
            remainingInDash -= step
            if remainingInDash <= 0 { advance() }
        }
    }

    mutating func advance() {
        index = (index + 1) % pattern.count
        remainingInDash = pattern[index]
    }

    mutating func stroke(from start: CGPoint, to end: CGPoint, draw: (CGPoint, CGPoint) -> Void) {
        let length = (end - start).magnitude
        guard length > 0 else { return }
        var travelled: CGFloat = 0
        while travelled < length {
            let step = min(remainingInDash, length - travelled)
            if isOn {
                draw(start + (end - start) * (travelled / length), start + (end - start) * ((travelled + step) / length))
            }
            travelled += step
            remainingInDash -= step
            if remainingInDash <= 0 { advance() }
        }
    }
}
