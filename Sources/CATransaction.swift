//
//  CATransaction.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct CATransaction {
    // These properties have an underscore suffix to avoid conflicts between instance and static members:
    private var disableActions_ = false
    private var animationDuration_: CGFloat = CALayer.defaultAnimationDuration

    internal private(set) static var transactionStack = [CATransaction]()

    public static func begin() {
        transactionStack.append(CATransaction())
    }

    public static func commit() {
        transactionStack.removeLast()
    }

    public static func disableActions() -> Bool {
        return transactionStack.last?.disableActions_ ?? false
    }

    public static func setDisableActions(_ newValue: Bool) {
        if transactionStack.isEmpty { return }
        transactionStack[transactionStack.count - 1].disableActions_ = newValue
    }

    public static func animationDuration() -> CGFloat {
        return transactionStack.last?.animationDuration_ ?? CALayer.defaultAnimationDuration
    }

    public static func setAnimationDuration(_ newValue: CGFloat) {
        if transactionStack.isEmpty { return }
        transactionStack[transactionStack.count - 1].animationDuration_ = newValue
    }
}
    
