//
//  CATransform3D.swift
//  UIKit
//
//  Created by Geordie Jay on 26.01.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import Foundation

public struct CATransform3D {
    public init(
        m11: Float, m12: Float, m13: Float, m14: Float,
        m21: Float, m22: Float, m23: Float, m24: Float,
        m31: Float, m32: Float, m33: Float, m34: Float,
        m41: Float, m42: Float, m43: Float, m44: Float
    ) {
        self.m11 = m11; self.m12 = m12; self.m13 = m13; self.m14 = m14;
        self.m21 = m21; self.m22 = m22; self.m23 = m23; self.m24 = m24;
        self.m31 = m31; self.m32 = m32; self.m33 = m33; self.m34 = m34;
        self.m41 = m41; self.m42 = m42; self.m43 = m43; self.m44 = m44;
    }

    // Matches iOS:
    public init() {
        self.m11 = 0.0; self.m12 = 0.0; self.m13 = 0.0; self.m14 = 0.0;
        self.m21 = 0.0; self.m22 = 0.0; self.m23 = 0.0; self.m24 = 0.0;
        self.m31 = 0.0; self.m32 = 0.0; self.m33 = 0.0; self.m34 = 0.0;
        self.m41 = 0.0; self.m42 = 0.0; self.m43 = 0.0; self.m44 = 0.0;
    }

    public var m11: Float
    public var m12: Float
    public var m13: Float
    public var m14: Float

    public var m21: Float
    public var m22: Float
    public var m23: Float
    public var m24: Float

    public var m31: Float
    public var m32: Float
    public var m33: Float
    public var m34: Float

    public var m41: Float
    public var m42: Float
    public var m43: Float
    public var m44: Float

    func asNonMutatingPointer(_ closure: ((UnsafeMutablePointer<Float>) -> Void)) -> Void {
        var copy = [m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44]
        copy.withUnsafeMutableBufferPointer { buffer in
            closure(buffer.baseAddress!)
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

public func CATransform3DMakeScale(_ sx: CGFloat, _ sy: CGFloat, _ sz: CGFloat) -> CATransform3D {
    return CATransform3D(
        m11: Float(sx), m12: 0,         m13: 0,         m14: 0,
        m21: 0,         m22: Float(sy), m23: 0,         m24: 0,
        m31: 0,         m32: 0,         m33: Float(sz), m34: 0,
        m41: 0,         m42: 0,         m43: 0,         m44: 1
    )
}

public func CATransform3DMakeTranslation(_ tx: CGFloat, _ ty: CGFloat, _ tz: CGFloat) -> CATransform3D {
    return CATransform3D(
        m11: 1,         m12: 0,         m13: 0,         m14: 0,
        m21: 0,         m22: 1,         m23: 0,         m24: 0,
        m31: 0,         m32: 0,         m33: 1,         m34: 0,
        m41: Float(tx), m42: Float(ty), m43: Float(tz), m44: 1
    )
}

public func CATransform3DConcat(_ a: CATransform3D, _ b: CATransform3D) -> CATransform3D {
    if b == CATransform3DIdentity { return a }

    var result = CATransform3D()

    result.m11 = a.m11 * b.m11 + a.m21 * b.m12 + a.m31 * b.m13 + a.m41 * b.m14
    result.m12 = a.m12 * b.m11 + a.m22 * b.m12 + a.m32 * b.m13 + a.m42 * b.m14
    result.m13 = a.m13 * b.m11 + a.m23 * b.m12 + a.m33 * b.m13 + a.m43 * b.m14
    result.m14 = a.m14 * b.m11 + a.m24 * b.m12 + a.m34 * b.m13 + a.m44 * b.m14

    result.m21 = a.m11 * b.m21 + a.m21 * b.m22 + a.m31 * b.m23 + a.m41 * b.m24
    result.m22 = a.m12 * b.m21 + a.m22 * b.m22 + a.m32 * b.m23 + a.m42 * b.m24
    result.m23 = a.m13 * b.m21 + a.m23 * b.m22 + a.m33 * b.m23 + a.m43 * b.m24
    result.m24 = a.m14 * b.m21 + a.m24 * b.m22 + a.m34 * b.m23 + a.m44 * b.m24

    result.m31 = a.m11 * b.m31 + a.m21 * b.m32 + a.m31 * b.m33 + a.m41 * b.m34
    result.m32 = a.m12 * b.m31 + a.m22 * b.m32 + a.m32 * b.m33 + a.m42 * b.m34
    result.m33 = a.m13 * b.m31 + a.m23 * b.m32 + a.m33 * b.m33 + a.m43 * b.m34
    result.m34 = a.m14 * b.m31 + a.m24 * b.m32 + a.m34 * b.m33 + a.m44 * b.m34

    result.m41 = a.m11 * b.m41 + a.m21 * b.m42 + a.m31 * b.m43 + a.m41 * b.m44
    result.m42 = a.m12 * b.m41 + a.m22 * b.m42 + a.m32 * b.m43 + a.m42 * b.m44
    result.m43 = a.m13 * b.m41 + a.m23 * b.m42 + a.m33 * b.m43 + a.m43 * b.m44
    result.m44 = a.m14 * b.m41 + a.m24 * b.m42 + a.m34 * b.m43 + a.m44 * b.m44

    return result
}

extension CATransform3D {
    func concat(_ other: CATransform3D) -> CATransform3D {
        return CATransform3DConcat(self, other)
    }
}

public func CATransform3DGetAffineTransform(_ t: CATransform3D) -> CGAffineTransform {
    return CGAffineTransform(
        m11: CGFloat(t.m11), m12: CGFloat(t.m12),
        m21: CGFloat(t.m21), m22: CGFloat(t.m22),
        tX:  CGFloat(t.m41), tY:  CGFloat(t.m42)
    )
}
