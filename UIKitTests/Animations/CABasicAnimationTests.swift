//
//  CABasicAnimationTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 17.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit
typealias CALayer = UIKit.CALayer
typealias CABasicAnimation = UIKit.CABasicAnimation

class CABasicAnimationTests: XCTestCase {
    func testCanAnimateOpacity() {
        let layer = CALayer()
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")

        fadeOutAnimation.duration = 0.5
        fadeOutAnimation.fromValue = CGFloat(1)
        fadeOutAnimation.toValue = CGFloat(0)

        layer.add(fadeOutAnimation, forKey: "fadeOut")

        UIView.animateIfNeeded(at: Timer(startingAt: 250))

        if let presentation = layer.presentation {
            XCTAssertEqual(presentation.opacity, CGFloat(0.5), accuracy: 0.01)
        } else {
            XCTFail("presentation must be defined")
        }
    }

    func testAddingAnimationsToLayerCreatesCopy() {
        let firstLayer = CALayer()
        let secondLayer = CALayer()
        let animation = CABasicAnimation(keyPath: "opacity")

        firstLayer.add(animation, forKey: "fadeOut")
        secondLayer.add(animation, forKey: "fadeOut")

        XCTAssertNotEqual(firstLayer.animations.first?.animation, secondLayer.animations.first?.animation)
    }

    func testDoNotRemoveOnCompletion() {
        let layer = CALayer()

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 0.5
        animation.fromValue = CGFloat(1)
        animation.toValue = CGFloat(0)
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: "fadeOut")

        UIView.animateIfNeeded(at: Timer(startingAt: 2000))

        XCTAssertNotNil(layer.presentation)
        XCTAssertEqual(layer.presentation?.opacity, 0)
    }
}


