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
        self.animationDuration = 0
        self.animationDelay = delay
        self.completion = completion
        animations()
        self.animationDuration = 0
        self.animationDelay = 0
        self.completion = nil
    }

    public static func animate(
        withSpringDuration duration: Double,
        delay: Double = 0.0,
        options: UIViewAnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
//        self.animationDuration = 0
//        self.animationDelay = delay
//        self.completion = completion
//        animations()
//        self.animationDuration = 0
//        self.animationDelay = 0
//        self.completion = nil


        UIView._animate(withDuration: duration, animations: animations)
    }

    public static func _animate(
        withDuration duration: Double,
        delay: Double = 0.0,
        options: UIViewAnimationOptions = [],
        animations: () -> Void,
        completion: ((Bool) -> Void)? = nil
        ) {

        self.timer = Timer()
        self.animationDuration = duration
        self.animationDelay = delay


        let totalTime = duration + delay


        var link: DisplayLink? = DisplayLink()
        link?.callback = {
            let finished = totalTime * 1000 - (timer?.getElapsedTimeInMilliseconds() ?? 0) <= 0
            if finished {
                completion?(true)
                link?.isPaused = true
                link = nil
            }
        }
        link?.isPaused = false


        self.completion = completion
        animations()
        self.animationDuration = 0
        self.animationDelay = 0
        self.completion = nil
    }

}
