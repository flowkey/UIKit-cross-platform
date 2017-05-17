//
//  UIEdgeInsets.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct UIEdgeInsets {
    public var left: CGFloat = 0
    public var right: CGFloat = 0
    public var top: CGFloat = 0
    public var bottom: CGFloat = 0

    public init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        self.left = left; self.right = right; self.top = top; self.bottom = bottom;
    }

    public init() {}
}
