//
//  CATransaction.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct CATransaction {
    public static func begin() {
        actionStack.append(false)
    }

    public static func commit() {
        actionStack.removeLast()
    }

    public static func setDisableActions(_ to: Bool) {
        actionStack[actionStack.count - 1] = to
    }

    static var disableActions: Bool {
        return actionStack.last ?? false
    }

    private static var actionStack = [Bool]()
}
