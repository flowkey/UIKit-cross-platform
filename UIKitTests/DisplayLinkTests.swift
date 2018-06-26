//
//  DisplayLinkTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 26.06.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class DisplayLinkTests: XCTestCase {
    var displayLink: DisplayLink!

    override func setUp() {
        DisplayLink.activeDisplayLinks = []
        displayLink = DisplayLink()
        displayLink.callback = {}
    }

    func testIsActiveWhenNotPaused() {
        displayLink.isPaused = false
        XCTAssertTrue(DisplayLink.activeDisplayLinks.contains(displayLink))
    }

    func testIsInactiveWhenPaused() {
        displayLink.isPaused = false
        XCTAssertTrue(DisplayLink.activeDisplayLinks.contains(displayLink))

        displayLink.isPaused = true
        XCTAssertFalse(DisplayLink.activeDisplayLinks.contains(displayLink))
    }

    func testIsInactiveWhenCallbackIsRemoved() {
        displayLink.isPaused = false
        XCTAssertTrue(DisplayLink.activeDisplayLinks.contains(displayLink))

        displayLink.callback = nil
        XCTAssertFalse(DisplayLink.activeDisplayLinks.contains(displayLink))
    }

    func testInvalidateRemovesCallback() {
        displayLink.invalidate()
        XCTAssertNil(displayLink.callback)
    }
}
