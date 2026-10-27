//
//  CGPath.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

/// A minimal cross-platform stand-in for CoreGraphics' `CGPath`. The SDL renderer draws rounded
/// rectangles and straight lines, so a path is either a bounding rectangle plus a corner radius
/// (the rect / rounded-rect / oval shapes `UIBezierPath` produces) or straight-line subpaths built
/// with `move(to:)` / `addLine(to:)`. Curves are not modelled.
public struct CGPath {
    public let boundingBox: CGRect
    public let cornerRadius: CGFloat
    internal let subpaths: [Subpath]

    struct Subpath {
        var points: [CGPoint]
        var isClosed = false
    }

    init(boundingBox: CGRect, cornerRadius: CGFloat) {
        self.boundingBox = boundingBox
        self.cornerRadius = cornerRadius
        self.subpaths = []
    }

    init(subpaths: [Subpath]) {
        self.boundingBox = CGRect(boundingPoints: subpaths.lazy.flatMap(\.points))
        self.cornerRadius = 0
        self.subpaths = subpaths
    }

    public init(rect: CGRect, transform: CGAffineTransform?) {
        self.init(boundingBox: rect, cornerRadius: 0)
    }
}
