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

    public init(keyPath: AnimationProperty, options: UIViewAnimationOptions = []) {
        self.keyPath = keyPath
        self.options = options
    }

    init(keyPath: AnimationProperty, protoType: CABasicAnimationPrototype) {
        self.keyPath = keyPath
        self.delay = protoType.delay
        self.duration = protoType.duration
        self.options = protoType.options
    }

    public var keyPath: AnimationProperty?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var duration: CGFloat = 0
    public var delay: CGFloat = 0
    public var fromValue: AnimatableProperty?
    public var toValue: AnimatableProperty?
    let options: UIViewAnimationOptions

    private var timer = Timer()
    var progress: CGFloat = 0
    var hasStarted: Bool {
        return progress > 0
    }
    var isComplete: Bool {
        return progress == 1
    }
    func updateProgress(to currentTime: Timer) -> CGFloat {
        let elapsedTime = max(CGFloat(currentTime - self.timer) - (delay * 1000), 0)
        progress = min(elapsedTime / (duration * 1000), 1)
        return progress
    }

    func compute(at timer: Timer) -> CGFloat {
        if options.contains(.curveEaseIn) { return easeInQuad(at: updateProgress(to: timer)) }
        if options.contains(.curveEaseOut) { return easeOutQuad(at: updateProgress(to: timer)) }
        if options.contains(.curveEaseInOut) { return easeInOutCubic(at: updateProgress(to: timer)) }
        return updateProgress(to: timer)
    }
}

fileprivate func easeInQuad(at x: CGFloat) -> CGFloat { return pow(x, 2) }
fileprivate func easeInCubic(at x: CGFloat) -> CGFloat { return pow(x, 3) }
fileprivate func easeOutQuad(at x: CGFloat) -> CGFloat { return x * (2-x) }
fileprivate func easeOutCubic(at x: CGFloat) -> CGFloat { return x * (2-x) }
fileprivate func easeInOutCubic(at x: CGFloat) -> CGFloat { return x < 0.5 ? 4*pow(x,3) : (x-1)*(2*x-2)*(2*x-2)+1 }

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

public protocol AnimatableProperty {}

extension CABasicAnimation: Equatable {
    public static func ==(lhs: CABasicAnimation, rhs: CABasicAnimation) -> Bool {
        return ObjectIdentifier(lhs).hashValue == ObjectIdentifier(rhs).hashValue
    }
}
