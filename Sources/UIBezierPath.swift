//
//  UIBezierPath.swift
//  UIKit
//
//  Copyright © flowkey. All rights reserved.
//

/// A minimal cross-platform `UIBezierPath`: the shape constructors plus straight-line building with
/// `move(to:)` / `addLine(to:)` / `close()`. Curves and drawing (`stroke`/`fill`, which need a graphics
/// context) are iOS-only and intentionally not provided here, so those uses stay behind `#if os(iOS)`.
public class UIBezierPath {
    private let shape: CGPath?
    private var subpaths: [CGPath.Subpath] = []

    public var cgPath: CGPath {
        shape ?? CGPath(subpaths: subpaths)
    }

    public init() {
        shape = nil
    }

    public init(rect: CGRect) {
        shape = CGPath(boundingBox: rect, cornerRadius: 0)
    }

    public init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
        shape = CGPath(boundingBox: rect, cornerRadius: cornerRadius)
    }

    public init(ovalIn rect: CGRect) {
        // Our renderer draws rounded rectangles: a max corner radius is an exact circle for a
        // square, and a stadium approximation for a non-square rect.
        shape = CGPath(boundingBox: rect, cornerRadius: min(rect.width, rect.height) / 2)
    }

    public func move(to point: CGPoint) {
        subpaths.append(CGPath.Subpath(points: [point]))
    }

    public func addLine(to point: CGPoint) {
        guard let current = subpaths.last else { return }
        if current.isClosed {
            subpaths.append(CGPath.Subpath(points: [current.points[0], point]))
        } else {
            subpaths[subpaths.count - 1].points.append(point)
        }
    }

    public func close() {
        guard !subpaths.isEmpty else { return }
        subpaths[subpaths.count - 1].isClosed = true
    }
}
