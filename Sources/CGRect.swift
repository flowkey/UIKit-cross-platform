//
//  CGRect.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//


public struct CGRect {
    public var origin: CGPoint
    public var size: CGSize

    public init(origin: CGPoint = .zero, size: CGSize = .zero) {
        self.origin = origin
        self.size = size
    }

    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }

    public var isNull: Bool { return self == .null }

    public static let null = CGRect(x: .infinity, y: .infinity, width: 0, height: 0)
    public static let zero = CGRect()
}

extension CGRect {
    public var minX: CGFloat {
        get { return origin.x }
        set { origin.x = newValue }
    }

    public var midX: CGFloat {
        get { return minX + width / 2 }
        set { self.origin.x = newValue - (width / 2) }
    }

    public var maxX: CGFloat {
        get { return minX + width }
        set { self.origin.x = newValue - width }
    }

    public var minY: CGFloat {
        get { return origin.y }
        set { origin.y = newValue }
    }

    public var midY: CGFloat {
        get { return minY + height / 2 }
        set { self.origin.y = newValue - (height / 2) }
    }

    public var maxY: CGFloat {
        get { return minY + height }
        set { self.origin.y = newValue - height }
    }

    public var width: CGFloat {
        get { return self.size.width }
        set { self.size.width = newValue }
    }

    public var height: CGFloat {
        get { return self.size.height }
        set { self.size.height = newValue }
    }

    public func contains(_ point: CGPoint) -> Bool {
        return
            (point.x >= minX) && (point.x < maxX) &&
            (point.y >= minY) && (point.y < maxY)
    }

    public func insetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        return CGRect(x: origin.x + dx, y: origin.y + dy, width: size.width - dx * 2, height: size.height - dy * 2)
    }
}

extension CGRect {
    public func intersects(_ other: CGRect) -> Bool {
        if min(self.maxX, other.maxX) < max(self.minX, other.minX) { return false }
        if min(self.maxY, other.maxY) < max(self.minY, other.minY) { return false }

        return true
    }

    public func intersection(_ other: CGRect) -> CGRect {
        let largestMinX = max(self.minX, other.minX)
        let largestMinY = max(self.minY, other.minY)

        let smallestMaxX = min(self.maxX, other.maxX)
        let smallestMaxY = min(self.maxY, other.maxY)

        let width = smallestMaxX - largestMinX
        let height = smallestMaxY - largestMinY

        if width > 0, height > 0 {
            // The intersection rectangle has dimensions, i.e. there is an intersection:
            return CGRect(x: largestMinX, y: largestMinY, width: width, height: height)
        } else {
            return .null
        }
    }
}

extension CGRect {
    internal func offsetBy(_ point: CGPoint) -> CGRect {
        var offsetCopy = self
        offsetCopy.origin = self.origin + point
        return offsetCopy
    }

    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        var offsetCopy = self
        offsetCopy.origin = self.origin + CGPoint(x: dx, y: dy)
        return offsetCopy
    }

    public func applying(_ t: CGAffineTransform) -> CGRect {
        if t.isIdentity { return self }

        let newTopLeft = CGPoint(x: minX, y: minY).applying(t)
        let newTopRight = CGPoint(x: maxX, y: minY).applying(t)
        let newBottomLeft = CGPoint(x: minX, y: maxY).applying(t)
        let newBottomRight = CGPoint(x: maxX, y: maxY).applying(t)

        let newMinX = min(newTopLeft.x, newTopRight.x, newBottomLeft.x, newBottomRight.x)
        let newMaxX = max(newTopLeft.x, newTopRight.x, newBottomLeft.x, newBottomRight.x)

        let newMinY = min(newTopLeft.y, newTopRight.y, newBottomLeft.y, newBottomRight.y)
        let newMaxY = max(newTopLeft.y, newTopRight.y, newBottomLeft.y, newBottomRight.y)

        // XXX: What happens if the point that was furthest left is now on the right (because of a rotation)?
        // i.e. Should do we return a normalised rect or one with a negative width?
        return CGRect(
            x: newMinX,
            y: newMinY,
            width: newMaxX - newMinX,
            height: newMaxY - newMinY
        )
    }
}

extension CGRect {
    // This doesn't exist in iOS but it's useful for debugging our rendering
    internal func applying(_ t: CATransform3D) -> CGRect {
        if t == CATransform3DIdentity { return self }

        let topLeft = t.transformingVector(x: minX, y: minY, z: 0)
        let topRight = t.transformingVector(x: maxX, y: minY, z: 0)
        let bottomLeft = t.transformingVector(x: minX, y: maxY, z: 0)
        let bottomRight = t.transformingVector(x: maxX, y: maxY, z: 0)

        let newMinX = min(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x)
        let newMaxX = max(topLeft.x, topRight.x, bottomLeft.x, bottomRight.x)

        let newMinY = min(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y)
        let newMaxY = max(topLeft.y, topRight.y, bottomLeft.y, bottomRight.y)

        return CGRect(
            x: CGFloat(newMinX),
            y: CGFloat(newMinY),
            width: CGFloat(newMaxX - newMinX),
            height: CGFloat(newMaxY - newMinY)
        )
    }
}

extension CGRect: CustomStringConvertible {
    public var description: String {
        return "(\(origin.x), \(origin.y), \(width), \(height))"
    }
}

extension CGRect: Equatable {
    public static func == (lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.origin == rhs.origin && lhs.size == rhs.size
    }
}

// MARK: Performance optimizations:
// The unspecialised generic versions of these functions take over 20% of the render func's CPU time in debug
// As they are written here they don't even register in the profiler:

private func min(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
    var minValue = (a < b) ? a : b
    minValue = (minValue < c) ? minValue : c
    minValue = (minValue < d) ? minValue : d
    return minValue
}

private func max(_ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) -> CGFloat {
    var maxValue = (a > b) ? a : b
    maxValue = (maxValue > c) ? maxValue : c
    maxValue = (maxValue > d) ? maxValue : d
    return maxValue
}
