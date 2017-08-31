//
//  UIViewAnimationTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 11.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UIViewAnimationTests: XCTestCase {

    override func tearDown() {
        // reset animation state
        UIView.layersWithAnimations = Set<UIKit.CALayer>()
    }

    func testCanAnimateFrame() {
        let view = UIView()

        let frameToStartFrom = CGRect(x: 10, y: 10, width: 10, height: 10)
        let expectedFrame = CGRect(x: 20, y: 20, width: 20, height: 20)

        view.frame = frameToStartFrom

        UIView.animate(withDuration: 5, delay: 0, options: [], animations: {
            view.frame = expectedFrame
        })

        XCTAssertEqual(view.frame, expectedFrame)

        UIView.animateIfNeeded(at: Timer(startingAt: 2500))

        if let presentation = view.layer.presentation {
            assertEqual(presentation.frame, CGRect(x: 15, y: 15, width: 15, height: 15), accuracy: 0.01)
        } else {
            XCTFail("presentation must be defined")
        }
    }

    func testCanAnimateOpacity() {
        let view = UIView()

        UIView.animate(withDuration: 5, delay: 0, options: [], animations: {
            view.alpha = 0.2
        })

        XCTAssertEqual(view.alpha, 0.2, accuracy: 0.001)
        XCTAssertEqual(view.layer.animations.count, 1)

        UIView.animateIfNeeded(at: Timer(startingAt: 2500))
        if let presentation = view.layer.presentation {
            XCTAssertEqual(presentation.opacity, 0.6, accuracy: 0.01)
        } else {
            XCTFail("presentation must be defined")
        }
    }

    func testCanAnimateBounds() {
        let view = UIView()

        let boundsToStartFrom = CGRect(x: 10, y: 10, width: 10, height: 10)
        let expectedBounds = CGRect(x: 20, y: 20, width: 20, height: 20)

        view.bounds = boundsToStartFrom

        UIView.animate(withDuration: 5, delay: 0, options: [], animations: {
            view.bounds = expectedBounds
        })
        XCTAssertEqual(view.bounds, expectedBounds)

        // animating bounds consists of bounds.origin and frame.size animation
        // because mutating frame mutates bounds and vice versa
        XCTAssertEqual(view.layer.animations.count, 2)

        UIView.animateIfNeeded(at: Timer(startingAt: 2500))

        if let presentation = view.layer.presentation {
            assertEqual(presentation.bounds, CGRect(x: 15, y: 15, width: 15, height: 15), accuracy: 0.01)
        } else {
            XCTFail("presentation must be defined")
        }
    }

    func testDelay() {
        let view = UIView()

        UIView.animate(withDuration: 2, delay: 2, options: [], animations: {
            view.alpha = 0
        })

        UIView.animateIfNeeded(at: Timer(startingAt: 3000))
        if let presentation = view.layer.presentation {
            XCTAssertEqual(Double(presentation.opacity), 0.5, accuracy: 0.01)
        } else {
            XCTFail("presentation must be defined")
        }
    }

    func testCompletion() {
        let view = UIView()
        var animationDidFinish = false

        UIView.animate(withDuration: 5, delay: 0, options: [], animations: {
            view.frame = CGRect(x: 20, y: 20, width: 20, height: 20)
            view.alpha = 0.3
            view.bounds.origin.x += 10
        }, completion: {
            animationDidFinish = $0
        })

        UIView.animateIfNeeded(at: Timer(startingAt: 5000))
        XCTAssertTrue(animationDidFinish)
    }

    func testCompletionWhenCancelingAnimations() {
        let view = UIView()
        var firstAnimationDidFinish: Bool?
        var secondAnimationDidFinish: Bool?

        UIView.animate(withDuration: 1, delay: 0, options: [], animations: {
            view.alpha = 0.3
        }, completion: {
            firstAnimationDidFinish = $0
        })

        UIView.animate(withDuration: 1, delay: 0.2, options: [], animations: {
            view.alpha = 0
        }, completion: {
            secondAnimationDidFinish = $0
        })

        UIView.animateIfNeeded(at: Timer(startingAt: 200))
        UIView.animateIfNeeded(at: Timer(startingAt: 5000))

        if
            let firstAnimationDidFinish = firstAnimationDidFinish,
            let secondAnimationDidFinish = secondAnimationDidFinish {
            XCTAssertFalse(firstAnimationDidFinish)
            XCTAssertTrue(secondAnimationDidFinish)
        } else {
            XCTFail("completion callback never called")
        }
    }

    func testCompletionWhenQueingAnimationsOfSameType() {
        let view = UIView()
        var firstAnimationDidFinish: Bool?
        var secondAnimationDidFinish: Bool?

        UIView.animate(withDuration: 1, delay: 0, options: [], animations: {
            view.alpha = 0.3
        }, completion: {
            firstAnimationDidFinish = $0
        })

        UIView.animate(withDuration: 1, delay: 2, options: [], animations: {
            view.alpha = 0
        }, completion: {
            secondAnimationDidFinish = $0
        })

        UIView.animateIfNeeded(at: Timer(startingAt: 5000))

        if
            let firstAnimationDidFinish = firstAnimationDidFinish,
            let secondAnimationDidFinish = secondAnimationDidFinish {
            XCTAssertFalse(firstAnimationDidFinish)
            XCTAssertTrue(secondAnimationDidFinish)
        } else {
            XCTFail("completion callback never called")
        }
    }

    func testPresentationLayerIsSet() {
        let view = UIView()
        let expectedFrame = CGRect(x: 20, y: 20, width: 20, height: 20)

        XCTAssertNil(view.layer.presentation)

        UIView.animate(withDuration: 5, delay: 0, options: [], animations: {
            view.frame = expectedFrame
            view.alpha = 0.1
        })

        UIView.animateIfNeeded(at: Timer(startingAt: 2500))
        XCTAssertNotNil(view.layer.presentation)
    }

    func testPresentationIsRemovedWhenAnimationsComplete() {
        let view = UIView()

        let expectedFrame = CGRect(x: 20, y: 20, width: 20, height: 20)

        UIView.animate(withDuration: 5, delay: 0, options: [], animations: {
            view.frame = expectedFrame
            view.alpha = 0.1
        })

        UIView.animateIfNeeded(at: Timer(startingAt: 6000))
        XCTAssertNil(view.layer.presentation)
    }

    func testLayersWithAnimations() {
        let firstView = UIView()
        let secondView = UIView()
        let thirdView = UIView()

        UIView.animate(withDuration: 10, delay: 0, options: [], animations: {
            firstView.frame.origin.x += 10
            firstView.alpha = 0.1
        })

        XCTAssertEqual(UIView.layersWithAnimations.count, 1)

        UIView.animate(withDuration: 15, delay: 0, options: [], animations: {
            secondView.alpha = 0.5
            thirdView.alpha = 0.3
        })

        XCTAssertEqual(UIView.layersWithAnimations.count, 3)

        // finish first animation
        UIView.animateIfNeeded(at: Timer(startingAt: 10000))
        XCTAssertEqual(UIView.layersWithAnimations.count, 2)

        // finish second animation
        UIView.animateIfNeeded(at: Timer(startingAt: 15000))
        XCTAssertEqual(UIView.layersWithAnimations.count, 0)
    }

    func testBeginFromCurrentState() {
        let view = UIView()

        UIView.animate(withDuration: 10, delay: 0, options: [], animations: {
            view.frame.origin.x = 10
        })
        UIView.animateIfNeeded(at: Timer(startingAt: 5000))
        UIView.animate(withDuration: 10, delay: 5, options: [.beginFromCurrentState], animations: {
            view.frame.origin.x = 20
        })

        let fromValue = view.layer.animations["frame"]?.fromValue as? CGRect
        XCTAssertEqual(fromValue?.origin.x ?? -1, CGFloat(5), accuracy: 0.01)
    }

    func testModifyLayerWhileAnimationIsInFlight() {
        let view = UIView()

        UIView.animate(withDuration: 10, delay: 0, options: [], animations: {
            view.frame.origin.x = 200
        })

        view.alpha = 0
        UIView.animateIfNeeded(at: Timer(startingAt: 5000))

        if let presentation = view.layer.presentation {
            XCTAssertEqual(presentation.opacity, 0)
            XCTAssertEqual(presentation.frame.origin.x, 100, accuracy: 0.01)
        } else {
            XCTFail("presentation must be defined")
        }

    }

    func testModifyPropertyCurrentlyBeingAnimated() {
        let view = UIView()

        UIView.animate(withDuration: 10, delay: 0, options: [], animations: {
            view.frame.origin.x = 200
        })

        view.frame.origin.x = 0
        UIView.animateIfNeeded(at: Timer(startingAt: 5000))

        if let presentation = view.layer.presentation {
            XCTAssertEqual(presentation.frame.origin.x, 0)
        } else {
            XCTFail("presentation must be defined")
        }
        XCTAssertEqual(view.frame.origin.x, 0)
    }
}

fileprivate extension UIViewAnimationTests {
    func assertEqual(_ rect1: CGRect, _ rect2: CGRect, accuracy: CGFloat) {
        XCTAssertEqual(rect1.height, rect2.height, accuracy: accuracy)
        XCTAssertEqual(rect1.width, rect2.width, accuracy: accuracy)
        XCTAssertEqual(rect1.origin.x, rect2.origin.x, accuracy: accuracy)
        XCTAssertEqual(rect1.origin.y, rect2.origin.y, accuracy: accuracy)
    }
}
