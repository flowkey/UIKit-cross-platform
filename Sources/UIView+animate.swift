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
}

extension UIView {
    static var animationGroups = [UIViewAnimationGroup]()
    static var animationPrototype: AnimationPrototype?

    public static func animate(
        withDuration duration: Double,
        delay: Double = 0.0,
        options: UIViewAnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        animationGroups.append(UIViewAnimationGroup(completion: completion))
        animationPrototype = CABasicAnimationPrototype(
            delay: CGFloat(delay),
            duration: CGFloat(duration),
            options: options
        )

        animations()
        animationPrototype = nil
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
        animationGroups.append(UIViewAnimationGroup(completion: completion))
        animationPrototype = CASpringAnimationPrototype(
            delay: CGFloat(delay),
            duration: CGFloat(duration),
            damping: usingSpringWithDamping,
            initialSpringVelocity: initialSpringVelocity,
            options: options
        )

        animations()
        animationPrototype = nil
    }

    static func animateIfNeeded() {
        if animationGroups.isEmpty { return }
        animationGroups.forEach({ $0.layersWithAnimations.forEach({ $0.animate() }) })
    }

}

extension UIView {
    open static func animate(withSpringDuration duration: Double, delay: Double = 0, damping: CGFloat = 0.9, initialVelocity: CGFloat = 0.7, options: UIViewAnimationOptions = [], animations: @escaping (() -> Void), completion: ((Bool) -> Void)? = nil) {

        animate(withDuration: duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: initialVelocity, options: options, animations: animations, completion: completion)
    }
}
