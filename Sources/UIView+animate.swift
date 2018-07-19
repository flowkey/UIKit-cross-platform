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

    public static func animate(withDuration duration: Double, _ animations: () -> Void) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [],
            animations: animations
        )
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
    public static let curveLinear = UIViewAnimationOptions(rawValue: 1 << 5)
    static let customEaseOut = UIViewAnimationOptions(rawValue: 1 << 9)
}
