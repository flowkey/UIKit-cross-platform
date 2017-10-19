//
//  UIView+animate.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension UIView {
    static var layersWithAnimations = Set<CALayer>()
    static var currentAnimationPrototype: CABasicAnimationPrototype?

    static var animationsArePending: Bool {
        return !layersWithAnimations.isEmpty
    }

    public static func animate(
        withDuration duration: Double,
        delay: Double = 0.0,
        options: UIViewAnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        currentAnimationPrototype = CABasicAnimationPrototype(
            duration: CGFloat(duration),
            delay: CGFloat(delay),
            animationGroup: .init(options: options, completion: completion)
        )

        animations()

        if currentAnimationPrototype?.animationGroup.queuedAnimations == 0 {
            completion?(true)
        }
        currentAnimationPrototype = nil
    }

    public static func animate(
        withDuration duration: Double,
        delay: Double,
        usingSpringWithDamping: CGFloat,
        initialSpringVelocity: CGFloat,
        options: UIViewAnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        currentAnimationPrototype = CASpringAnimationPrototype(
            duration: CGFloat(duration),
            delay: CGFloat(delay),
            damping: usingSpringWithDamping,
            initialSpringVelocity: initialSpringVelocity,
            animationGroup: .init(options: options, completion: completion)
        )

        animations()

        if currentAnimationPrototype?.animationGroup.queuedAnimations == 0 {
            completion?(true)
        }
        currentAnimationPrototype = nil
    }

    static func animateIfNeeded(at currentTime: Timer) {
        if layersWithAnimations.isEmpty { return }
        layersWithAnimations.forEach { $0.animate(at: currentTime) }
    }
}

public struct UIViewAnimationOptions: RawRepresentable, OptionSet {
    public let rawValue: UInt
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let allowUserInteraction = UIViewAnimationOptions(rawValue: 1 << 0)
    public static let beginFromCurrentState = UIViewAnimationOptions(rawValue: 1 << 1)
    public static let curveEaseIn = UIViewAnimationOptions(rawValue: 1 << 2)
    public static let curveEaseOut = UIViewAnimationOptions(rawValue: 1 << 3)
    public static let curveEaseInOut = UIViewAnimationOptions(rawValue: 1 << 4)
}
