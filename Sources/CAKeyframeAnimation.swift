//
//  CAKeyframeAnimation.swift
//  UIKit
//
//  Created by Michael Knoch on 31.08.26.
//  Copyright © 2026 flowkey. All rights reserved.
//

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
        guard let values, !values.isEmpty else { return nil }
        guard values.count > 1 else { return values[0] }

        let keyTimes = self.keyTimes ?? (0 ..< values.count).map {
            CGFloat($0) / CGFloat(values.count - 1)
        }
        guard keyTimes.count == values.count else {
            assertionFailure("keyTimes and values must have the same number of elements")
            return nil
        }

        var segment = 0
        while segment < values.count - 2, progress > keyTimes[segment + 1] { segment += 1 }

        let keyTimeSpan = keyTimes[segment + 1] - keyTimes[segment]
        var segmentProgress = keyTimeSpan > 0
            ? max(0, min(1, (progress - keyTimes[segment]) / keyTimeSpan))
            : 1
        if let timingFunctions, timingFunctions.indices.contains(segment) {
            segmentProgress = timingFunctions[segment][at: segmentProgress]
        }

        return values[segment] + (values[segment + 1] - values[segment]) * segmentProgress
    }
}
