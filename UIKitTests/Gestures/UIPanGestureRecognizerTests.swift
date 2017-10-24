//
//  UIGestureRecognizerTests.swift
//  UIKitTests
//
//  Created by flowing erik on 22.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UIGestureRegognizerTests: XCTestCase {
    var mockTouch: UITouch!
    let mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
    override func setUp() {
        mockTouch = UITouch(
            at: CGPoint(x: 0, y: 0),
            in: mockView,
            touchId: 0
        )
    }

    func testPanGestureVelocity () {
        let touchPositionDiff: CGFloat = 50
        let timeInterval = 1.0

        let pgr = UIPanGestureRecognizer()
        let velocityExp = expectation(description: "velocity is as expected")

        self.mockTouch.previousPositionInView = CGPoint(x: 0, y: 0)
        self.mockTouch.positionInView = CGPoint(x: touchPositionDiff, y: 0)
        pgr.touchesBegan([mockTouch], with: UIEvent())
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
            pgr.touchesMoved([self.mockTouch], with: UIEvent())
            let velocityX = pgr.velocity(in: self.mockView).x
            let expectedVelocityX: CGFloat = touchPositionDiff / CGFloat(timeInterval)

            // we can not predict the exact velocity because we use DispatchTime.now
            // because of this we allow some deviation of a few percent
            print(velocityX, expectedVelocityX)
            if velocityX.isRoundAbout(to: expectedVelocityX, percentalAccuracy: 5.0) {
                velocityExp.fulfill()
            }
        }

        wait(for: [velocityExp], timeout: 1.1)
    }
}

fileprivate extension CGFloat {
    func isRoundAbout(to value: CGFloat, percentalAccuracy: Double) -> Bool {
        let min = Double(value) - ((Double(value) * percentalAccuracy) / 100)
        let max = Double(value) + ((Double(value) * percentalAccuracy) / 100)
        let result = (min ..< max)~=(Double(self)) // if in range
        if (result == false) {
            fatalError(String(describing: self) + "is not in range between " + String(describing: min) + " and " + String(describing: max))
        }
        return result
    }
}
