//
//  CGAffineTransform.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import struct Foundation.AffineTransform
public typealias CGAffineTransform = AffineTransform

public extension CGAffineTransform {
    public init(scaleX: CGFloat, y: CGFloat) {
        self.init(scaleByX: scaleX, byY: y)
    }

    internal func transforming(_ point: CGPoint) -> CGPoint {
        return CGPoint(
            x: point.x * m11 + point.y * m21 + tX,
            y: point.x * m12 + point.y * m22 + tY
        )
    }

    public var isIdentity: Bool {
        return self == .identity
    }

}
