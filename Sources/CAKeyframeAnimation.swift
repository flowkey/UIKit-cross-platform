public class CAKeyframeAnimation: CABasicAnimation {
    public var values: [CGFloat]?
    public var keyTimes: [CGFloat]?
    public var timingFunctions: [CAMediaTimingFunction]?

    public override init(keyPath: AnimationKeyPath) {
        super.init(keyPath: keyPath)
        timingFunction = nil
    }

    init(from animation: CAKeyframeAnimation) {
        values = animation.values
        keyTimes = animation.keyTimes
        timingFunctions = animation.timingFunctions
        super.init(from: animation)
    }

    override func copy() -> CAKeyframeAnimation {
        return CAKeyframeAnimation(from: self)
    }

    func value(at progress: CGFloat) -> CGFloat? {
        guard let values, let firstValue = values.first else { return nil }
        guard values.count > 1 else { return firstValue }
        if let keyTimes, keyTimes.count != values.count {
            assertionFailure("keyTimes and values must have the same number of elements")
            return nil
        }

        var segment = 0
        while segment < values.count - 2, progress > keyTime(segment + 1, of: values.count) {
            segment += 1
        }

        let segmentStart = keyTime(segment, of: values.count)
        let segmentSpan = keyTime(segment + 1, of: values.count) - segmentStart
        var segmentProgress = segmentSpan > 0
            ? max(0, min(1, (progress - segmentStart) / segmentSpan))
            : 1
        if let timingFunctions, timingFunctions.indices.contains(segment) {
            segmentProgress = timingFunctions[segment][at: segmentProgress]
        }

        return values[segment] + (values[segment + 1] - values[segment]) * segmentProgress
    }

    /// Keyframes are spaced evenly when `keyTimes` is not set, as on iOS.
    private func keyTime(_ index: Int, of valueCount: Int) -> CGFloat {
        return keyTimes?[index] ?? CGFloat(index) / CGFloat(valueCount - 1)
    }
}
