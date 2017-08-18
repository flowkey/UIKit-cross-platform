//
//  CASpringAnimationTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 18.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit
typealias CASpringAnimation = UIKit.CASpringAnimation

class CASpringAnimationTests: XCTestCase {
    func testCreateCopy() {
        let animation = CASpringAnimation(
            duration: 4,
            delay: 5,
            damping: 2,
            initialSpringVelocity: 1,
            options: [.allowUserInteraction]
        )

        let copy = CASpringAnimation(from: animation)

        XCTAssertNotEqual(copy, animation)
        XCTAssertEqual(copy.delay, animation.delay)
        XCTAssertEqual(copy.duration, animation.duration)
        XCTAssertEqual(copy.damping, animation.damping)
        XCTAssertEqual(copy.initialSpringVelocity, animation.initialSpringVelocity)

        XCTAssertEqual(copy.progress, animation.progress)
        XCTAssertEqual(copy.animationGroup, animation.animationGroup)
        XCTAssertEqual(copy.options, animation.options)
    }
}
