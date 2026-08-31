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

    func testRemovingAGroupRemovesItsChildren() {
        let layer = CALayer()

        let scaleUp = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        scaleUp.values = [1, 3]
        scaleUp.duration = 1

        let group = UIKit.CAAnimationGroup()
        group.animations = [scaleUp]
        layer.add(group, forKey: "scaleUp")
        XCTAssertFalse(layer.animations.isEmpty)

        layer.removeAnimation(forKey: "scaleUp")

        XCTAssertTrue(layer.animations.isEmpty)
    }

    func testGroupKeepsItsChildrenWhenItIsNotRemovedOnCompletion() throws {
        let layer = CALayer()

        let scaleUp = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        scaleUp.values = [1, 3]
        scaleUp.duration = 0.5

        let group = UIKit.CAAnimationGroup()
        group.animations = [scaleUp]
        group.duration = 0.5
        group.isRemovedOnCompletion = false
        layer.add(group, forKey: "scaleUp")

        UIView.animateIfNeeded(at: Timer(startingAt: 1000))

        let presentation = try XCTUnwrap(layer._presentation)
        XCTAssertEqual(presentation.transform.m11, 3, accuracy: 0.01)
    }

    /// The medal flip in the player: a scale.x flip-in running in parallel with a scale wiggle.
    func testParallelFlipAndWiggleEndsAtTheModelTransform() throws {
        let layer = CALayer()

        let flipIn = UIKit.CAKeyframeAnimation(keyPath: "transform.scale.x")
        flipIn.values = [0.001, 1]
        flipIn.keyTimes = [0, 1]
        flipIn.duration = 0.15
        flipIn.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let wiggle = UIKit.CAKeyframeAnimation(keyPath: "transform.scale")
        wiggle.values = [1, 1.35, 0.98, 1]
        wiggle.keyTimes = [0, 0.4, 0.75, 1]
        wiggle.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeOut),
        ]
        wiggle.duration = 0.52

        let group = UIKit.CAAnimationGroup()
        group.animations = [flipIn, wiggle]
        group.duration = 0.52
        layer.add(group, forKey: "flipWiggle")

        UIView.animateIfNeeded(at: Timer(startingAt: 75))
        let midFlip = try XCTUnwrap(layer._presentation)
        XCTAssertGreaterThan(midFlip.transform.m22, 1)
        XCTAssertLessThan(midFlip.transform.m11, midFlip.transform.m22)

        UIView.animateIfNeeded(at: Timer(startingAt: 520))
        XCTAssertTrue(layer.animations.isEmpty)
        XCTAssertNil(layer._presentation)
        XCTAssertEqual(layer.transform, CATransform3DIdentity)
    }
}
