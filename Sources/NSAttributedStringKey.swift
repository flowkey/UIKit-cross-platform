//
//  NSAttributedStringKey.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

private let NSKernAttributeName = "NSKernAttribute"
private let NSForegroundAttributeName = "NSForegroundAttribute"

public struct NSAttributedStringKey: Hashable {
    public var hashValue: Int

    public static func ==(lhs: NSAttributedStringKey, rhs: NSAttributedStringKey) -> Bool {
        return lhs == rhs
    }

    public static let kern = NSKernAttributeName
    public static let foregroundColor = NSForegroundAttributeName
}
