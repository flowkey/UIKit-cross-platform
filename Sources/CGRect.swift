//
//  CGRect.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL_gpu

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
}

extension CGRect {
    internal func offsetBy(_ point: CGPoint) -> CGRect {
        var offsetCopy = self
        offsetCopy.origin = self.origin.offsetBy(point)
        return offsetCopy
    }

    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        var offsetCopy = self
        offsetCopy.origin = self.origin.offsetBy(CGPoint(x: dx, y: dy))
        return offsetCopy
    }

    public func applying(_ t: CGAffineTransform) -> CGRect {
        if t.isIdentity { return self }

        let oldPoints: [CGPoint] = [
            CGPoint(x: self.minX, y: self.minY), // top left
            CGPoint(x: self.maxX, y: self.minY), // top right
            CGPoint(x: self.minX, y: self.maxY), // bottom left
            CGPoint(x: self.maxX, y: self.maxY)  // bottom right
        ]

        let newPoints = oldPoints.map { oldPoint in
            CGPoint(
                x: oldPoint.x * t.m11 + oldPoint.y * t.m21 + t.tX,
                y: oldPoint.x * t.m12 + oldPoint.y * t.m22 + t.tY
            )
        }

        // TODO: Put all of this "inline" to avoid the overhead of multiple arrays and loops
        let result = newPoints.reduce((minX: CGFloat.greatestFiniteMagnitude, minY: CGFloat.greatestFiniteMagnitude, maxX: -CGFloat.greatestFiniteMagnitude, maxY: -CGFloat.greatestFiniteMagnitude)) { result, point in
            return (
                minX: min(result.minX, point.x),
                minY: min(result.minY, point.y),
                maxX: max(result.maxX, point.x),
                maxY: max(result.maxY, point.y)
            )
        }

        // XXX: What happens if the point that was furthest left is now on the right (because of a rotation)?
        // i.e. Should do we return a normalised rect or one with a negative width?
        return CGRect(
            x: result.minX,
            y: result.minY,
            width: result.maxX - result.minX,
            height: result.maxY - result.minY
        )
    }
}

extension CGRect {
    // This doesn't exist in iOS but it's useful for debugging our rendering
    internal func applying(_ t: CATransform3D) -> CGRect {
        if t == CATransform3DIdentity { return self }

        var topLeft = [Float(self.minX), Float(self.minY), 0]
        var topRight = [Float(self.maxX), Float(self.minY), 0]
        var bottomLeft = [Float(self.minX), Float(self.maxY), 0]
        var bottomRight = [Float(self.maxX), Float(self.maxY), 0]

        t.asNonMutatingPointer { transform in
            GPU_VectorApplyMatrix(&topLeft, transform)
            GPU_VectorApplyMatrix(&topRight, transform)
            GPU_VectorApplyMatrix(&bottomLeft, transform)
            GPU_VectorApplyMatrix(&bottomRight, transform)
        }

        let newMinX = min(topLeft[0], topRight[0], bottomLeft[0], bottomRight[0])
        let newMinY = min(topLeft[1], topRight[1], bottomLeft[1], bottomRight[1])

        let newMaxX = max(topLeft[0], topRight[0], bottomLeft[0], bottomRight[0])
        let newMaxY = max(topLeft[1], topRight[1], bottomLeft[1], bottomRight[1])

        return CGRect(
            x: CGFloat(newMinX),
            y: CGFloat(newMinY),
            width: CGFloat(newMaxX - newMinX),
            height: CGFloat(newMaxY - newMinY)
        )
    }
}

extension GPU_Rect {
    init(_ cgRect: CGRect) {
        self.w = Float(cgRect.size.width)
        self.h = Float(cgRect.size.height)
        self.x = Float(cgRect.origin.x)
        self.y = Float(cgRect.origin.y)
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
