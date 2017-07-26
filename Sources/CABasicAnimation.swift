//
//  CABasicAnimation.swift
//  UIKit
//
//  Created by Geordie Jay on 06.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public let kCAFillModeForwards = "kCAFillModeForwards"

public class CABasicAnimation {
    public init(keyPath: String?) {
        self.keyPath = keyPath
    }

    public var keyPath: String?
    public var fillMode: String?
    public var isRemovedOnCompletion = true
    public var duration: CGFloat = 0
    public var fromValue: Any?
    public var toValue: Any?

    internal var timer = Timer()

    internal var multiplier: CGFloat {
        return min(CGFloat(timer.getElapsedTimeInMilliseconds()) / (duration * 1000), 1)
    }
}
