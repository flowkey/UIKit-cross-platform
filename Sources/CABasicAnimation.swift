//
//  CABasicAnimation.swift
//  UIKit
//
//  Created by Geordie Jay on 06.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public let kCAFillModeForwards = "kCAFillModeForwards"

public class CABasicAnimation {

    // != nil means animating in UIView.animate closure
    // == nil means animation was manually instantiated
    var animationGroup: UIViewAnimationGroup? = UIView.currentAnimationGroup

    public init(keyPath: AnimationProperty) {
        self.keyPath = keyPath
    }

    init(keyPath: AnimationProperty, protoType: CABasicAnimationPrototype) {
        self.keyPath = keyPath
        self.delay = protoType.delay
        self.duration = protoType.duration
    }

    public var keyPath: AnimationProperty?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var duration: CGFloat = 0
    public var delay: CGFloat = 0

    public var fromValue: AnimatableProperty? {
        didSet {
            if let value = fromValue as? NSNumber {
                fromValue = CGFloat(truncating: value)
            }
        }
    }

    public var toValue: AnimatableProperty? {
        didSet {
            if let value = toValue as? NSNumber {
                toValue = CGFloat(truncating: value)
            }
        }
    }

    var timer = Timer()
    var progress: CGFloat = 0

    func updateProgress(to currentTime: Timer) -> CGFloat {
        let elapsedTime = max(CGFloat(currentTime - self.timer) - (delay * 1000), 0)
        progress = min(elapsedTime / (duration * 1000), 1)
        return progress
    }

    var hasStarted: Bool {
        return progress > 0
    }

    var isComplete: Bool {
        return progress == 1
    }

}

public enum AnimationProperty: ExpressibleByStringLiteral {
    case frame, opacity, bounds, unknown
    public init(stringLiteral value: String) {
        switch value {
        case "frame": self = .frame
        case "opacity": self = .opacity
        case "bounds": self = .bounds
        default: self = .unknown
        }
    }
}

extension CABasicAnimation: Equatable {
    public static func ==(lhs: CABasicAnimation, rhs: CABasicAnimation) -> Bool {
        return ObjectIdentifier(lhs).hashValue == ObjectIdentifier(rhs).hashValue
    }
}
