//
//  CAKeyframeAnimationTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 31.08.26.
//  Copyright © 2026 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

@MainActor
class CAKeyframeAnimationTests: XCTestCase {
    func testInterpolatesBetweenKeyframes() throws {
        let layer = CALayer()

        let wiggle = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        wiggle.values = [1.0, 2.0, 1.0]
        wiggle.keyTimes = [0, 0.5, 1]
        wiggle.duration = 1
        layer.add(wiggle, forKey: "wiggle")

        UIView.animateIfNeeded(at: Timer(startingAt: 250))

        let presentation = try XCTUnwrap(layer._presentation)
        XCTAssertEqual(presentation.transform.m11, 1.5, accuracy: 0.01)
        XCTAssertEqual(presentation.transform.m22, 1.5, accuracy: 0.01)
    }

    func testKeyTimesDefineSegmentDurations() throws {
        let layer = CALayer()

        let wiggle = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        wiggle.values = [1.0, 2.0, 4.0]
        wiggle.keyTimes = [0, 0.25, 1]
        wiggle.duration = 1
        layer.add(wiggle, forKey: "wiggle")

        UIView.animateIfNeeded(at: Timer(startingAt: 625))

        let halfwayThroughSecondSegment: Float = 3
        let presentation = try XCTUnwrap(layer._presentation)
        XCTAssertEqual(presentation.transform.m11, halfwayThroughSecondSegment, accuracy: 0.01)
    }

    func testAnimationGroupAnimatesItsChildrenInParallel() throws {
        let layer = CALayer()

        let flipIn = UIKit.CAKeyframeAnimation(keyPath: "transform.scale.x")
        flipIn.values = [0, 1]
        flipIn.duration = 1

        let scaleUp = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        scaleUp.values = [1, 3]
        scaleUp.duration = 1

        let group = UIKit.CAAnimationGroup()
        group.animations = [flipIn, scaleUp]
        group.duration = 1
        layer.add(group, forKey: "flipAndScale")

        UIView.animateIfNeeded(at: Timer(startingAt: 500))

        let scaleX: Float = 0.5
        let scale: Float = 2
        let presentation = try XCTUnwrap(layer._presentation)
        XCTAssertEqual(presentation.transform.m11, scaleX * scale, accuracy: 0.01)
        XCTAssertEqual(presentation.transform.m22, scale, accuracy: 0.01)
    }

    func testAnimationGroupClipsChildrenToItsOwnDuration() throws {
        let layer = CALayer()

        let scaleUp = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        scaleUp.values = [1, 3]
        scaleUp.duration = 1

        let group = UIKit.CAAnimationGroup()
        group.animations = [scaleUp]
        group.duration = 0.5
        layer.add(group, forKey: "scaleUp")

        UIView.animateIfNeeded(at: Timer(startingAt: 250))

        let presentation = try XCTUnwrap(layer._presentation)
        XCTAssertEqual(presentation.transform.m11, 2, accuracy: 0.01)
    }

    func testAddingGroupToLayerCreatesCopiesOfItsChildren() {
        let layer = CALayer()

        let scaleUp = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        scaleUp.values = [1, 3]
        scaleUp.duration = 1

        let group = UIKit.CAAnimationGroup()
        group.animations = [scaleUp]
        layer.add(group, forKey: "scaleUp")

        let addedAnimation = layer.animations["scaleUp.0"] as? UIKit.CAKeyframeAnimation
        XCTAssertTrue(addedAnimation !== scaleUp)
        XCTAssertEqual(addedAnimation?.values ?? [], [1, 3])
    }
}
