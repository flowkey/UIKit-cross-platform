//
//  CATransaction.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct CATransaction {
    var areActionsDisabled = false

    private static var transactionStack = [CATransaction]()

    public static func begin() {
        transactionStack.append(CATransaction())
    }

    public static func commit() {
        transactionStack.removeLast()
    }

    public static func setDisableActions(_ newValue: Bool) {
        if transactionStack.isEmpty { return }
        transactionStack[transactionStack.count - 1].areActionsDisabled = newValue
    }

    static var disableActions: Bool {
        return transactionStack.last?.areActionsDisabled ?? false
    }
}
    
