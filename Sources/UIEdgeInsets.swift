//
//  UIEdgeInsets.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct UIEdgeInsets: Equatable {
    public var left: CGFloat = 0
    public var right: CGFloat = 0
    public var top: CGFloat = 0
    public var bottom: CGFloat = 0

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.left = left; self.right = right; self.top = top; self.bottom = bottom;
    }

    public init() {}

    public static let zero: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    public static func ==(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> Bool {
        return lhs.bottom == rhs.bottom
            && lhs.left == rhs.left
            && lhs.right == rhs.right
            && lhs.top == rhs.top
    }
}
