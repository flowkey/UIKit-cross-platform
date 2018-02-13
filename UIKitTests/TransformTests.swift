//
//  TransformTests.swift
//  UIKitTests
//
//  Created by Geordie Jay on 12.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit
import SDL_gpu

class TransformTests: XCTestCase {
    func testIdentityMatricesAreEquivalent() {
        var buffer = [Float](repeating: 0.0, count: 16)
        GPU_MatrixIdentity(&buffer)

        let transformFromBuffer = CATransform3D(unsafePointer: buffer)
        XCTAssertEqual(transformFromBuffer, UIKit.CATransform3DIdentity)
    }
    
    func testScaleMatricesAreEquivalent() {
        var buffer = [Float](repeating: 0.0, count: 16)
        GPU_MatrixIdentity(&buffer)

        let scaleX: Float = 1.5
        let scaleY: Float = 2.5
        let scaleZ: Float = 3.5
        GPU_MatrixScale(&buffer, scaleX, scaleY, scaleZ)

        let transformFromBuffer = CATransform3D(unsafePointer: buffer)
        let uikitTranslation = CATransform3D(
            m11: scaleX, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: scaleY, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: scaleZ, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )

        XCTAssertEqual(transformFromBuffer, uikitTranslation)
    }

    func testTranslationMatricesAreEquivalent() {
        var buffer = [Float](repeating: 0.0, count: 16)
        GPU_MatrixIdentity(&buffer)
        let translation: (x: Float, y: Float, z: Float) = (34, 56, 78)
        GPU_MatrixTranslate(&buffer, translation.x, translation.y, translation.z)

        let transformFromBuffer = CATransform3D(unsafePointer: buffer)
        let uikitTranslation = CATransform3D(
            m11: 1, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: 1, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: translation.x, m42: translation.y, m43: translation.z, m44: 1
        )

        XCTAssertEqual(transformFromBuffer, uikitTranslation)
    }

    func testAffineTranslationMatricesAreEquivalent() {
        let translation: (x: Float, y: Float, z: Float) = (34, 56, 0)
        var buffer = [Float](repeating: 0.0, count: 16)
        GPU_MatrixIdentity(&buffer)
        GPU_MatrixTranslate(&buffer, translation.x, translation.y, translation.z)

        let transformFromBuffer = CATransform3D(unsafePointer: buffer)
        let uikitTranslation = UIKit.CATransform3DMakeAffineTransform(
            CGAffineTransform(translationByX: CGFloat(translation.x), byY: CGFloat(translation.y))
        )

        XCTAssertEqual(transformFromBuffer, uikitTranslation)
    }
}
