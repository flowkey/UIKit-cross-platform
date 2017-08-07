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

    static var animationDuration = 0.0
    static var animationDelay = 0.0
    static var completion: ((Bool) -> Void)?
    static var timer: Timer?

    public static func animate(
        withDuration duration: Double,
        delay: Double = 0.0,
        options: UIViewAnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        self.timer = Timer()
        self.animationDuration = duration
        self.animationDelay = delay

        animations()

        if let completion = completion, let timer = timer {
            run(completion: completion, after: duration + delay, timer: timer)
        }
        clearAnimationProperties()
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
        self.timer = Timer()
        self.animationDuration = duration
        self.animationDelay = delay

        animations()

        if let completion = completion, let timer = timer {
            run(completion: completion, after: duration + delay, timer: timer)
        }
        clearAnimationProperties()
    }



    static func run(completion: @escaping (Bool) -> Void, after time: Double, timer: Timer) {
        var link: DisplayLink? = DisplayLink()
        link?.callback = {
            let finished = time * 1000 - (timer.getElapsedTimeInMilliseconds()) <= 0
            if finished {
                completion(true)
                link?.isPaused = true
                link = nil
            }
        }
        link?.isPaused = false
    }

    static func clearAnimationProperties() {
        self.animationDuration = 0
        self.animationDelay = 0
        self.timer = nil
    }

}


extension UIView {
    open static func animate(withSpringDuration duration: Double, delay: Double = 0, damping: CGFloat = 0.9, initialVelocity: CGFloat = 0.7, options: UIViewAnimationOptions = [], animations: @escaping (() -> Void), completion: ((Bool) -> Void)? = nil) {

        animate(withDuration: duration, delay: delay, usingSpringWithDamping: damping, initialSpringVelocity: initialVelocity, options: options, animations: animations, completion: completion)
    }
}
