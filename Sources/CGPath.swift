//
//  CGPath.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

/// A minimal cross-platform stand-in for CoreGraphics' `CGPath`. The SDL renderer can only draw
/// rounded rectangles, so a path is represented by its bounding rectangle plus a corner radius —
/// enough for the rect / rounded-rect / oval shapes `UIBezierPath` produces (which is all the app
/// relies on cross-platform, e.g. `CALayer.shadowPath`). Freeform paths (move/addLine/curves) are
/// not modelled: there is no initializer for them, so misuse is a compile error, not a silent
/// mis-render.
public struct CGPath {
    public let boundingBox: CGRect
    public let cornerRadius: CGFloat

    init(boundingBox: CGRect, cornerRadius: CGFloat) {
        self.boundingBox = boundingBox
        self.cornerRadius = cornerRadius
    }

    public init(rect: CGRect, transform: CGAffineTransform?) {
        self.init(boundingBox: rect, cornerRadius: 0)
    }
}
