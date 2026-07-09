//
//  UIBezierPath.swift
//  UIKit
//
//  Copyright © flowkey. All rights reserved.
//

/// A minimal cross-platform `UIBezierPath` covering the shape constructors — the part the app uses
/// cross-platform (e.g. building a `CALayer.shadowPath`). Freeform building (move/addLine/curves)
/// and drawing (`stroke`/`fill`, which need a graphics context) are iOS-only and intentionally not
/// provided here, so those uses stay behind `#if os(iOS)`.
public class UIBezierPath {
    public let cgPath: CGPath

    public init(rect: CGRect) {
        cgPath = CGPath(boundingBox: rect, cornerRadius: 0)
    }

    public init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
        cgPath = CGPath(boundingBox: rect, cornerRadius: cornerRadius)
    }

    public init(ovalIn rect: CGRect) {
        // Our renderer draws rounded rectangles: a max corner radius is an exact circle for a
        // square, and a stadium approximation for a non-square rect.
        cgPath = CGPath(boundingBox: rect, cornerRadius: min(rect.width, rect.height) / 2)
    }
}
