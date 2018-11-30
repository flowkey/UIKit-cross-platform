//
//  UIApplication+NSNotificationTests.swift
//  UIKitTests
//
//  Created by Chetan Agarwal on 30.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UIApplication_NSNotificationTests: XCTestCase {
    func testApplicationPostsWillEnterForegroundNotification() {
        expectation(forNotification: .UIApplicationWillEnterForeground, object: nil, handler: nil)
        UIApplication.onWillEnterForeground()
        waitForExpectations(timeout: 0.1)
    }

    func testApplicationPostsDidBecomeActiveNotification() {
        expectation(forNotification: .UIApplicationDidBecomeActive, object: nil, handler: nil)
        UIApplication.onDidEnterForeground()
        waitForExpectations(timeout: 0.1)
    }

    func testApplicationPostsWillResignActiveNotification() {
        expectation(forNotification: .UIApplicationWillResignActive, object: nil, handler: nil)
        UIApplication.onWillEnterBackground()
        waitForExpectations(timeout: 0.1)
    }

    func testApplicationPostsDidEnterBackgroundNotification() {
        expectation(forNotification: .UIApplicationDidEnterBackground, object: nil, handler: nil)
        UIApplication.onDidEnterBackground()
        waitForExpectations(timeout: 0.1)
    }
}

