//
//  CGPoint.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

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
extension CGPoint: Equatable {
    public static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
