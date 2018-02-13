//
//  CATransform3D.swift
//  UIKit
//
//  Created by Geordie Jay on 26.01.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation

// This implementation looks pretty dumb, but the only way we currently have to
// guarantee a particular memory layout (for performance) is to use a tuple for our storage.
// The problem with that is that you can't currently write extensions for tuples.
// This also means they can't conform to protocols etc. So this is the best we've got:
public struct CATransform3D {
    var storage: (
        m11: Float, m12: Float, m13: Float, m14: Float,
        m21: Float, m22: Float, m23: Float, m24: Float,
        m31: Float, m32: Float, m33: Float, m34: Float,
        m41: Float, m42: Float, m43: Float, m44: Float
    )

    public init(
        m11: Float, m12: Float, m13: Float, m14: Float,
        m21: Float, m22: Float, m23: Float, m24: Float,
        m31: Float, m32: Float, m33: Float, m34: Float,
        m41: Float, m42: Float, m43: Float, m44: Float
    ) {
        storage.m11 = m11; storage.m12 = m12; storage.m13 = m13; storage.m14 = m14;
        storage.m21 = m21; storage.m22 = m22; storage.m23 = m23; storage.m24 = m24;
        storage.m31 = m31; storage.m32 = m32; storage.m33 = m33; storage.m34 = m34;
        storage.m41 = m41; storage.m42 = m42; storage.m43 = m43; storage.m44 = m44;
    }

    // Match iOS:
    public init() { storage = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0) }

    public var m11: Float { return storage.m11 }
    public var m12: Float { return storage.m12 }
    public var m13: Float { return storage.m13 }
    public var m14: Float { return storage.m14 }

    public var m21: Float { return storage.m21 }
    public var m22: Float { return storage.m22 }
    public var m23: Float { return storage.m23 }
    public var m24: Float { return storage.m24 }

    public var m31: Float { return storage.m31 }
    public var m32: Float { return storage.m32 }
    public var m33: Float { return storage.m33 }
    public var m34: Float { return storage.m34 }

    public var m41: Float { return storage.m41 }
    public var m42: Float { return storage.m42 }
    public var m43: Float { return storage.m43 }
    public var m44: Float { return storage.m44 }

    mutating func withUnsafeMutablePointer(_ closure: ((UnsafeMutablePointer<Float>) -> Void)) -> Void {
        Swift.withUnsafeMutablePointer(to: &self.storage) { pointerToTuple in
            pointerToTuple.withMemoryRebound(to: Float.self, capacity: 16, closure)
        }
    }
}

extension CATransform3D {
    init(unsafePointer: UnsafePointer<Float>) {
        let buffer = UnsafeBufferPointer(start: unsafePointer, count: 16)
        self.init(
            m11: buffer[0], m12: buffer[1], m13: buffer[2], m14: buffer[3],
            m21: buffer[4], m22: buffer[5], m23: buffer[6], m24: buffer[7],
            m31: buffer[8], m32: buffer[9], m33: buffer[10], m34: buffer[11],
            m41: buffer[12], m42: buffer[13], m43: buffer[14], m44: buffer[15]
        )
    }
}

public let CATransform3DIdentity = CATransform3D(
    m11: 1.0, m12: 0.0, m13: 0.0, m14: 0.0,
    m21: 0.0, m22: 1.0, m23: 0.0, m24: 0.0,
    m31: 0.0, m32: 0.0, m33: 1.0, m34: 0.0,
    m41: 0.0, m42: 0.0, m43: 0.0, m44: 1.0
)

public func CATransform3DEqualToTransform(_ a: CATransform3D, _ b: CATransform3D) -> Bool {
    return
        a.m11 == b.m11 && a.m12 == b.m12 && a.m13 == b.m13 && a.m14 == b.m14 &&
        a.m21 == b.m21 && a.m22 == b.m22 && a.m23 == b.m23 && a.m24 == b.m24 &&
        a.m31 == b.m31 && a.m32 == b.m32 && a.m33 == b.m33 && a.m34 == b.m34 &&
        a.m41 == b.m41 && a.m42 == b.m42 && a.m43 == b.m43 && a.m44 == b.m44
}

extension CATransform3D: Equatable {
    public static func == (_ lhs: CATransform3D, _ rhs: CATransform3D) -> Bool {
        return CATransform3DEqualToTransform(lhs, rhs)
    }
}

extension CATransform3D: CustomStringConvertible {
    public var description: String {
        return """
        \(m11)\t\t\(m12)\t\t\(m13)\t\t\(m14)
        \(m21)\t\t\(m22)\t\t\(m23)\t\t\(m24)
        \(m31)\t\t\(m32)\t\t\(m33)\t\t\(m34)
        \(m41)\t\t\(m42)\t\t\(m43)\t\t\(m44)
        """
    }
}


// https://stackoverflow.com/a/5508486/3086440
/*
 | a b c |      | a b 0 0 |
 | d e f |  =>  | d e 0 0 |
 | g h i |      | 0 0 1 0 |
                | g h 0 1 |
 */
public func CATransform3DMakeAffineTransform(_ m: CGAffineTransform) -> CATransform3D {
    return CATransform3D(
        m11: Float(m.m11), m12: Float(m.m12), m13: 0.0, m14: 0.0,
        m21: Float(m.m21), m22: Float(m.m22), m23: 0.0, m24: 0.0,
        m31: 0.0,          m32: 0.0,          m33: 1.0, m34: 0.0,
        m41: Float(m.tX),  m42: Float(m.tY),  m43: 0.0, m44: 1.0
    )
}

public func CATransform3DGetAffineTransform(_ t: CATransform3D) -> CGAffineTransform {
    return CGAffineTransform(
        m11: CGFloat(t.m11), m12: CGFloat(t.m12),
        m21: CGFloat(t.m21), m22: CGFloat(t.m22),
        tX:  CGFloat(t.m41), tY:  CGFloat(t.m42)
    )
}
