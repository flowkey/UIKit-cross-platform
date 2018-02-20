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

    func testConcatIsEqualToGPUMatrixMultiply() {
        let translation: (x: Float, y: Float, z: Float) = (34, 56, 12)
        let scaleFactor: Float = 2.0
        var buffer = [Float](repeating: 0.0, count: 16)
        GPU_MatrixIdentity(&buffer)
        GPU_MatrixTranslate(&buffer, translation.x, translation.y, translation.z)
        GPU_MatrixScale(&buffer, scaleFactor, scaleFactor, scaleFactor)

        let uikitMatrix = UIKit.CATransform3DIdentity
            .concat(CATransform3DMakeTranslation(CGFloat(translation.x), CGFloat(translation.y), CGFloat(translation.z)))
            .concat(CATransform3DMakeScale(CGFloat(scaleFactor), CGFloat(scaleFactor), CGFloat(scaleFactor)))

        let transformFromBuffer = CATransform3D(unsafePointer: buffer)
        XCTAssertEqual(transformFromBuffer, uikitMatrix)
    }

    func testTransformVectorMultiply() {
        let scaleX = CGFloat(arc4random_uniform(100))
        let scaleY = CGFloat(arc4random_uniform(100))
        let scaleZ = CGFloat(arc4random_uniform(100))

        let scale = UIKit.CATransform3DMakeScale(scaleX, scaleY, scaleZ)
        let translation = UIKit.CATransform3DMakeTranslation(10.0, 10.0, 10.0)
        let transform = translation * scale // translation applied first, so translation is absolute / unscaled
        let scaledVector = transform.transformingVector(x: 1.0, y: 1.0, z: 1.0) // so post-scale value == scale

        XCTAssertEqual(scaledVector.x, scaleX + 10.0)
        XCTAssertEqual(scaledVector.y, scaleY + 10.0)
        XCTAssertEqual(scaledVector.z, scaleZ + 10.0)
    }

    func testSDLGpuMatrixPerformance() {
        var identity = [Float](repeating: 0.0, count: 16)
        GPU_MatrixIdentity(&identity)

        var matrixA = identity
        GPU_MatrixTranslate(&matrixA, 20, 20, 20)
        GPU_MatrixScale(&matrixA, 20, 20, 20)

        var matrixB = identity
        GPU_MatrixScale(&matrixB, 20, 20, 20)
        GPU_MatrixTranslate(&matrixB, 20, 20, 20)

        let expectedResult: [Float] = [400.0, 0.0, 0.0, 0.0, 0.0, 400.0, 0.0, 0.0, 0.0, 0.0, 400.0, 0.0, 8020.0, 8020.0, 8020.0, 1.0]
        var result = identity
        measure {
            for _ in 0 ..< 1000 {
                GPU_Multiply4x4(&result, &matrixA, &matrixB)
                XCTAssertEqual(result, expectedResult)
            }
        }
    }

    func testUIKitGPUMatrixPerformance() {
        let translation = UIKit.CATransform3DMakeTranslation(20, 20, 20)
        let scale = UIKit.CATransform3DMakeScale(20, 20, 20)

        let matrixA = translation.concat(scale)
        let matrixB = scale.concat(translation)

        let expectedResult = UIKit.CATransform3D(m11: 400, m12: 0, m13: 0, m14: 0, m21: 0, m22: 400, m23: 0, m24: 0, m31: 0, m32: 0, m33: 400, m34: 0, m41: 8020, m42: 8020, m43: 8020, m44: 1)
        measure {
            for _ in 0 ..< 1000 {
                let result = matrixA.concat(matrixB)
                XCTAssertEqual(result, expectedResult)
            }
        }
    }
}
