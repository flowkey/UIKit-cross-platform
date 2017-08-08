//
//  CGRect+animations.swift
//  UIKit
//
//  Created by Michael Knoch on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CGRect {
    static func -(rhs: CGRect, lhs: CGRect) -> CGRect {
        return CGRect(
            x: rhs.origin.x - lhs.origin.x,
            y: rhs.origin.y - lhs.origin.y,
            width: rhs.width - lhs.width,
            height: rhs.height - lhs.height
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

    func multiply(_ multiplier: CGFloat) -> CGRect {
        return CGRect(
            x: self.origin.x * multiplier,
            y: self.origin.y * multiplier,
            width: self.width * multiplier,
            height: self.height * multiplier
        )
    }
}
