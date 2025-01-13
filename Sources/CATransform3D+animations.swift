//
//  CGAffineTransform+animations.swift
//  FlowkeyPlayerSDLPackageDescription
//
//  Created by Michael Knoch on 19.01.18.
//

internal import SDL_gpu

// It doesn't make sense to make these public, they're only to simplify our animation code:
internal extension CATransform3D {
    static func - (_ a: CATransform3D, _ b: CATransform3D) -> CATransform3D {
        return CATransform3D(
            m11: a.m11 - b.m11, m12: a.m12 - b.m12, m13: a.m13 - b.m13, m14: a.m14 - b.m14,
            m21: a.m21 - b.m21, m22: a.m22 - b.m22, m23: a.m23 - b.m23, m24: a.m24 - b.m24,
            m31: a.m31 - b.m31, m32: a.m32 - b.m32, m33: a.m33 - b.m33, m34: a.m34 - b.m34,
            m41: a.m41 - b.m41, m42: a.m42 - b.m42, m43: a.m43 - b.m43, m44: a.m44 - b.m44
        )
    }

    static func + (_ a: CATransform3D, _ b: CATransform3D) -> CATransform3D {
        return CATransform3D(
            m11: a.m11 + b.m11, m12: a.m12 + b.m12, m13: a.m13 + b.m13, m14: a.m14 + b.m14,
            m21: a.m21 + b.m21, m22: a.m22 + b.m22, m23: a.m23 + b.m23, m24: a.m24 + b.m24,
            m31: a.m31 + b.m31, m32: a.m32 + b.m32, m33: a.m33 + b.m33, m34: a.m34 + b.m34,
            m41: a.m41 + b.m41, m42: a.m42 + b.m42, m43: a.m43 + b.m43, m44: a.m44 + b.m44
        )
    }

    static func * (_ a: CATransform3D, _ b: Float) -> CATransform3D {
        return CATransform3D(
            m11: a.m11 * b, m12: a.m12 * b, m13: a.m13 * b, m14: a.m14 * b,
            m21: a.m21 * b, m22: a.m22 * b, m23: a.m23 * b, m24: a.m24 * b,
            m31: a.m31 * b, m32: a.m32 * b, m33: a.m33 * b, m34: a.m34 * b,
            m41: a.m41 * b, m42: a.m42 * b, m43: a.m43 * b, m44: a.m44 * b
        )
    }
}
