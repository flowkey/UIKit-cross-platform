//
//  CATransaction.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct CATransaction {
    var actionsAreDisabled = false
    var animationDuration: CGFloat = CALayer.defaultAnimationDuration

    private static var transactionStack = [CATransaction]()

    public static func begin() {
        transactionStack.append(CATransaction())
    }

    public static func commit() {
        transactionStack.removeLast()
    }

    public static func disableActions() -> Bool {
        return transactionStack.last?.actionsAreDisabled ?? false
    }

    public static func setDisableActions(_ newValue: Bool) {
        if transactionStack.isEmpty { return }
        transactionStack[transactionStack.count - 1].actionsAreDisabled = newValue
    }

    public static func animationDuration() -> CGFloat {
        return transactionStack.last?.animationDuration ?? CALayer.defaultAnimationDuration
    }

    public static func setAnimationDuration(_ newValue: CGFloat) {
        if transactionStack.isEmpty { return }
        transactionStack[transactionStack.count - 1].animationDuration = newValue
    }
}
    
