//
//  Geometry.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 11.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

public typealias CGFloat = Double
public extension CGFloat {
    // This is needed because we sometimes try to convert doubles into CGFloats
    public init(_ value: Double) {
        self = value
    }
}

public struct CGPoint {
    public var x: CGFloat = 0
    public var y: CGFloat = 0

    public init() {}

    public init(x: CGFloat, y: CGFloat) {
        self.x = x; self.y = y
    }

    public init(x: Int, y: Int) {
        self.x = CGFloat(x); self.y = CGFloat(y)
    }

    public static let zero = CGPoint()
    public static prefix func - (point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }
}

extension CGPoint {
    internal func offsetBy(_ other: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + other.x, y: self.y + other.y)
    }
}

public struct CGSize {
    public var width: CGFloat = 0
    public var height: CGFloat = 0

    public init() {}

    public init(width: CGFloat, height: CGFloat) {
        self.width = width; self.height = height
    }

    public init(width: Int, height: Int) {
        self.width = CGFloat(width); self.height = CGFloat(height)
    }

    public static let zero = CGSize()
}


extension CGSize: Equatable {
    public static func == (lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

extension CGPoint: Equatable {
    public static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
