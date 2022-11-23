// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// Note from the UIKit-Crossplatform authors:
// The `AffineTransform` type has been essentially copied verbatim from the
// swift-corelibs-foundation project (below). The main difference in this
// file compared to its equivalent in that project is that we don't include
// the "reference type" bridging and other dynamic features (or types) that
// the original includes.
//
/// AffineTransform represents an affine transformation matrix of the following form:
///
/// ```swift
/// [ m11  m12  0 ]
/// [ m21  m22  0 ]
/// [  tX   tY  1 ]
/// ```
public struct AffineTransform {
    public var m11: CGFloat
    public var m12: CGFloat
    public var m21: CGFloat
    public var m22: CGFloat
    public var tX: CGFloat
    public var tY: CGFloat

    /// Creates an affine transformation.
    public init(
        m11: CGFloat, m12: CGFloat,
        m21: CGFloat, m22: CGFloat,
        tX: CGFloat, tY: CGFloat
    ) {
        self.m11 = m11
        self.m12 = m12
        self.m21 = m21
        self.m22 = m22
        self.tX = tX
        self.tY = tY
    }
}

extension AffineTransform {
    /// Creates an affine transformation matrix with identity values.
    public init() {
        self.init(m11: 1, m12: 0,
                  m21: 0, m22: 1,
                   tX: 0,  tY: 0)
    }

    /// An identity affine transformation matrix
    ///
    /// ```swift
    /// [ 1  0  0 ]
    /// [ 0  1  0 ]
    /// [ 0  0  1 ]
    /// ```
    public static let identity = AffineTransform()
}

extension AffineTransform {
    /// Creates an affine transformation matrix from translation values.
    /// The matrix takes the following form:
    ///
    /// ```swift
    /// [ 1  0  0 ]
    /// [ 0  1  0 ]
    /// [ x  y  1 ]
    /// ```
    public init(translationByX x: CGFloat, byY y: CGFloat) {
        self.init(m11: 1, m12: 0,
                  m21: 0, m22: 1,
                   tX: x,  tY: y)
    }

    /// Creates an affine transformation matrix from scaling values.
    /// The matrix takes the following form:
    ///
    /// ```swift
    /// [ x  0  0 ]
    /// [ 0  y  0 ]
    /// [ 0  0  1 ]
    /// ```
    public init(scaleByX x: CGFloat, byY y: CGFloat) {
        self.init(m11: x, m12: 0,
                  m21: 0, m22: y,
                   tX: 0,  tY: 0)
    }

    /// Creates an affine transformation matrix from scaling a single value.
    /// The matrix takes the following form:
    ///
    /// ```swift
    /// [ f  0  0 ]
    /// [ 0  f  0 ]
    /// [ 0  0  1 ]
    /// ```
    public init(scale factor: CGFloat) {
        self.init(scaleByX: factor, byY: factor)
    }

    /// Creates an affine transformation matrix from rotation value (angle in radians).
    /// The matrix takes the following form:
    ///
    /// ```swift
    /// [  cos α   sin α  0 ]
    /// [ -sin α   cos α  0 ]
    /// [    0       0    1 ]
    /// ```
    public init(rotationByRadians angle: CGFloat) {
        let sinα = sin(angle)
        let cosα = cos(angle)

        self.init(
            m11:  cosα, m12: sinα,
            m21: -sinα, m22: cosα,
             tX:  0,     tY: 0
        )
    }

    /// Creates an affine transformation matrix from a rotation value (angle in degrees).
    /// The matrix takes the following form:
    ///
    /// ```swift
    /// [  cos α   sin α  0 ]
    /// [ -sin α   cos α  0 ]
    /// [    0       0    1 ]
    /// ```
    public init(rotationByDegrees angle: CGFloat) {
        let α = angle * .pi / 180
        self.init(rotationByRadians: α)
    }
}

extension AffineTransform {
    /// Creates an affine transformation matrix by combining the two matrices `A×B` and returns the result.
    ///
    /// The resulting matrix takes the following form
    ///
    /// ```swift
    ///
    ///       [ a1, b1, 0 ]   [ a2, b2, 0 ]
    /// A×B = [ c1, d1, 0 ] × [ c2, d2, 0 ]
    ///       [ x1, y1, 1 ]   [ x2, y2, 1 ]
    ///
    ///       [ a1*a2+b1*c2+0*x2 a1*b2+b1*d2+0*y2 a1*0+b1*0+0*1 ]
    /// A×B = [ c1*a2+d1*c2+0*x2 c1*b2+d1*d2+0*y2 c1*0+d1*0+0*1 ]
    ///       [ x1*a2+y1*c2+1*x2 x1*b2+y1*d2+1*y2 x1*0+y1*0+1*1 ]
    ///
    ///       [   a1*a2+b1*c2    a1*b2+b1*d2        0 ]
    /// A×B = [   c1*a2+d1*c2    c1*b2+d1*d2        0 ]
    ///       [ x1*a2+y1*c2+x2  x1*b2+y1*d2+y2      1 ]
    /// ```
    @inline(__always)
    internal func concatenated(_ other: AffineTransform) -> AffineTransform {
        let (t, m) = (self, other)

        return AffineTransform(
            m11: (t.m11 * m.m11) + (t.m12 * m.m21), m12: (t.m11 * m.m12) + (t.m12 * m.m22),
            m21: (t.m21 * m.m11) + (t.m22 * m.m21), m22: (t.m21 * m.m12) + (t.m22 * m.m22),
            tX: (t.tX * m.m11) + (t.tY * m.m21) + m.tX,
            tY: (t.tX * m.m12) + (t.tY * m.m22) + m.tY
        )
    }

    /// Mutates an affine transformation by appending the specified matrix.
    public mutating func append(_ transform: AffineTransform) {
        self = concatenated(transform)
    }

    /// Mutates an affine transformation by prepending the specified matrix.
    public mutating func prepend(_ transform: AffineTransform) {
        self = transform.concatenated(self)
    }
}

extension AffineTransform {
    // Translating
    public mutating func translate(x: CGFloat, y: CGFloat) {
        self = concatenated(
            AffineTransform(translationByX: x, byY: y)
        )
    }

    /// Mutates an affine transformation matrix to perform a scaling in each of the x and y dimensions.
    public mutating func scale(x: CGFloat, y: CGFloat) {
        self = concatenated(
            AffineTransform(scaleByX: x, byY: y)
        )
    }

    /// Mutates an affine transformation matrix to perform the given scaling in both x and y dimensions.
    public mutating func scale(_ scale: CGFloat) {
        self.scale(x: scale, y: scale)
    }

    /// Mutates an affine transformation matrix from a rotation value (angle α in radians).
    /// The matrix takes the following form:
    ///
    /// ```swift
    /// [  cos α   sin α  0 ]
    /// [ -sin α   cos α  0 ]
    /// [    0       0    1 ]
    /// ```
    public mutating func rotate(byRadians angle: CGFloat) {
        self = concatenated(
            AffineTransform(rotationByRadians: angle)
        )
    }

    /// Mutates an affine transformation matrix from a rotation value (angle α in degrees).
    /// The matrix takes the following form:
    ///
    /// ```swift
    /// [  cos α   sin α  0 ]
    /// [ -sin α   cos α  0 ]
    /// [    0       0    1 ]
    /// ```
    public mutating func rotate(byDegrees angle: CGFloat) {
        self = concatenated(
            AffineTransform(rotationByDegrees: angle)
        )
    }
}

extension AffineTransform {
    /// Returns an inverted version of the matrix if possible, or nil if not.
    public func inverted() -> AffineTransform? {
        // We need the matrix of cofactors to calculate the inverse, but first we
        // need to calculate the minors of each element — where the minor of an
        // element Ai,j is the determinant of the matrix derived from deleting
        // the ith row and jth column:
        //
        //     [ |d y|  |c x|  |c x| ]
        //     [ |0 1|  |0 1|  |d y| ]
        //     [                     ]
        //     [ |b y|  |a x|  |a x| ]
        // M = [ |0 1|  |0 1|  |b y| ]
        //     [                     ]
        //     [ |b d|  |a c|  |a c| ]
        //     [ |0 0|  |0 0|  |b d| ]
        //
        //     [ d*1-y*0  c*1-x*0  c*y-x*d ]
        // M = [ b*1-y*0  a*1-x*0  a*y-x*b ]
        //     [ b*0-d*0  a*0-c*0  a*d-c*b ]
        //
        //     [ d    c    c*y-x*d ]
        // M = [ b    a    a*y-x*b ]
        //     [ 0    0      |A|   ]
        //
        // Now we can calculate the matrix of cofactors by negating each element Ai,j
        // where i+j is odd:
        //
        //     [  d    -c     c*y-x*d   ]
        // C = [ -b     a   -(a*y-x*b)  ]
        //     [  0    -0       |A|     ]
        //
        // Next, we can find the adjugate matrix, which is the transposed matrix of
        // cofactors — a matrix whose ith column is the ith row of the matrix of C:
        //
        //          [    d         -b          0  ]
        // adj(A) = [   -c          a         -0  ]
        //          [ c*y-x*d  -(a*y-x*b)     |A| ]
        //
        // Finally, the inverse matrix is the product of the reciprocal of the determinant
        // of A times adj(A), assuming that |A|≠0:
        //
        // A^-1 = (1 / |A|) × adj(A)
        //
        //        [     d/|A|          -b/|A|         0/|A|  ]
        // A^-1 = [    -c/|A|           a/|A|        -0/|A|  ]
        //        [ (c*y-x*d)/|A|  -(a*y-x*b)/|A|    |A|/|A| ]
        //
        //        [     d/|A|          -b/|A|          0 ]
        // A^-1 = [    -c/|A|           a/|A|          0 ]
        //        [ (c*y-x*d)/|A|   (x*b-a*y)/|A|      1 ]

        let determinant = (m11 * m22) - (m12 * m21)

        // We compare to ulp of 0 instead of doing determinant != 0,
        // to catch floating-point rounding errors.
        if abs(determinant) <= CGFloat.zero.ulp {
            return nil
        }

        return AffineTransform(
            m11:  m22 / determinant,                 m12: -m12 / determinant,
            m21: -m21 / determinant,                 m22:  m11 / determinant,
             tX: (m21 * tY - m22 * tX) / determinant, tY: (m12 * tX - m11 * tY) / determinant
        )
    }

    /// Inverts the transformation matrix if possible. Matrices with a determinant that is less than
    /// the smallest valid representation of a double value greater than zero are considered to be
    /// invalid for representing as an inverse. If the input AffineTransform can potentially fall into
    /// this case then the inverted() method is suggested to be used instead since that will return
    /// an optional value that will be nil in the case that the matrix cannot be inverted.
    ///
    /// ```swift
    /// D = (m11 * m22) - (m12 * m21)
    /// ```
    ///
    /// - Note: `D < ε` the inverse is undefined and will be nil
    public mutating func invert() {
        guard let inverse = inverted() else {
            fatalError("Transform has no inverse")
        }

        self = inverse
    }
}

extension AffineTransform {
    /// Applies the transform to the specified point and returns the result.
    public func transform(_ point: CGPoint) -> CGPoint {
        // Multiply the given point matrix with the matrix:
        //
        //                           [ m11  m12  0 ]
        // [ x' y' 1 ] = [ x y 1 ] × [ m21  m22  0 ]
        //                           [  tX   tY  1 ]
        //
        // [ x' y' 1 ] = [ x*m11+y*m21+1*tX  x*m12+y*m22+1*tY  x*0+y*0+1*1 ]
        //
        // [ x' y' 1 ] = [ x*m11+y*m21+tX  x*m12+y*m22+tY  1 ]
        CGPoint(
            x: (m11 * point.x) + (m21 * point.y) + tX,
            y: (m12 * point.x) + (m22 * point.y) + tY
        )
    }

    /// Applies the transform to the specified size and returns the result.
    public func transform(_ size: CGSize) -> CGSize {
        // Multiply the given size matrix with the scale & rotation matrix:
        //
        // [ w' h' ] = [ w  h ]  *  [ m11  m12 ]
        //                          [ m21  m22 ]
        //
        // [ w' h' ] = [ w*m11+h*m21  w*m12+h*m22 ]
        CGSize(
            width : (m11 * size.width) + (m21 * size.height),
            height: (m12 * size.width) + (m22 * size.height)
        )
    }
}

extension AffineTransform: Hashable {}
extension AffineTransform: Codable {}

extension AffineTransform: CustomStringConvertible {
    /// A textual description of the transform.
    public var description: String {
        return "{m11:\(m11), m12:\(m12), m21:\(m21), m22:\(m22), tX:\(tX), tY:\(tY)}"
    }

    /// A textual description of the transform suitable for debugging.
    public var debugDescription: String {
        return description
    }
}