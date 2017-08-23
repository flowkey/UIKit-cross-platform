//
//  UIView+animate.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

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

extension UIView {
    static var layersWithAnimations = Set<CALayer>()
    static var currentAnimationGroup: UIViewAnimationGroup?
    static var currentAnimationPrototype: CABasicAnimationPrototype?

    public static func animate(
        withDuration duration: Double,
        delay: Double = 0.0,
        options: UIViewAnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        currentAnimationGroup = UIViewAnimationGroup(completion: completion)
        currentAnimationPrototype = CABasicAnimationPrototype(
            duration: CGFloat(duration),
            delay: CGFloat(delay),
            options: options
        )

        animations()
        currentAnimationGroup = nil
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
        currentAnimationGroup = UIViewAnimationGroup(completion: completion)
        currentAnimationPrototype = CASpringAnimationPrototype(
            duration: CGFloat(duration),
            delay: CGFloat(delay),
            damping: usingSpringWithDamping,
            initialSpringVelocity: initialSpringVelocity,
            options: options
        )

        animations()
        currentAnimationGroup = nil
        currentAnimationPrototype = nil
    }

    static func animateIfNeeded(at currentTime: Timer) {
        if layersWithAnimations.isEmpty { return }
        layersWithAnimations.forEach { $0.animate(at: currentTime) }
    }
}
