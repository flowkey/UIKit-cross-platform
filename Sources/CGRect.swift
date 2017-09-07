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
       return CGRect(x: origin.x + dx / 2, y: origin.y + dy / 2, width: size.width - dx, height: size.height - dy)
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
}

extension GPU_Rect {
    init(_ cgRect: CGRect) {
        self.w = Float(cgRect.size.width)
        self.h = Float(cgRect.size.height)
        self.x = Float(cgRect.origin.x)
        self.y = Float(cgRect.origin.y)
    }
}

extension CGRect: Equatable {
    public static func == (lhs: CGRect, rhs: CGRect) -> Bool {
        return lhs.origin == rhs.origin && lhs.size == rhs.size
    }
}
