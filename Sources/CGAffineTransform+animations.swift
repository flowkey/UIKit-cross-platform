//
//  CGAffineTransform+animations.swift
//  FlowkeyPlayerSDLPackageDescription
//
//  Created by Michael Knoch on 19.01.18.
//

extension CGAffineTransform {
    static func -(lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
        return CGAffineTransform(
            m11: lhs.m11 - rhs.m11,
            m12: lhs.m12 - rhs.m12,
            m21: lhs.m21 - rhs.m21,
            m22: lhs.m22 - rhs.m22,
            tX: lhs.tX - rhs.tX,
            tY: lhs.tY - rhs.tY
        )
    }
    static func +(lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
        return CGAffineTransform(
            m11: lhs.m11 + rhs.m11,
            m12: lhs.m12 + rhs.m12,
            m21: lhs.m21 + rhs.m21,
            m22: lhs.m22 + rhs.m22,
            tX: lhs.tX + rhs.tX,
            tY: lhs.tY + rhs.tY
        )
    }
    static func *(lhs: CGAffineTransform, rhs: CGFloat) -> CGAffineTransform {
        return CGAffineTransform(
            m11: lhs.m11 * rhs,
            m12: lhs.m12 * rhs,
            m21: lhs.m21 * rhs,
            m22: lhs.m22 * rhs,
            tX: lhs.tX * rhs,
            tY: lhs.tY * rhs
        )
    }
}
