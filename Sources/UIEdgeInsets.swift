//
//  UIEdgeInsets.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct UIEdgeInsets: Equatable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.top = top; self.left = left; self.bottom = bottom; self.right = right
    }

    public static let zero = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    public static func ==(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> Bool {
        return lhs.bottom == rhs.bottom
            && lhs.left == rhs.left
            && lhs.right == rhs.right
            && lhs.top == rhs.top
    }
}
