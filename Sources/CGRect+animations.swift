//
//  CGRect+animations.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CGRect: AnimatableProperty {
    static func -(lhs: CGRect, rhs: CGRect) -> CGRect {
        return CGRect(
            x: lhs.origin.x - rhs.origin.x,
            y: lhs.origin.y - rhs.origin.y,
            width: lhs.width - rhs.width,
            height: lhs.height - rhs.height
        )
    }

    static func +(lhs: CGRect, rhs: CGRect) -> CGRect {
        return CGRect(
            x: lhs.origin.x + rhs.origin.x,
            y: lhs.origin.y + rhs.origin.y,
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }

    static func *(lhs: CGRect, rhs: CGFloat) -> CGRect {
        return CGRect(
            x: lhs.origin.x * rhs,
            y: lhs.origin.y * rhs,
            width: lhs.width * rhs,
            height: lhs.height * rhs
        )
    }
}
