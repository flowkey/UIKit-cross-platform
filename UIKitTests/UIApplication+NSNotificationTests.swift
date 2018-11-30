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
        let notificationExpectation = expectation(forNotification: .UIApplicationWillEnterForeground,
                                                  object: nil,
                                                  handler: nil)
        UIApplication.onWillEnterForeground()
        wait(for: [notificationExpectation], timeout: 0.1)
    }

    func testApplicationPostsDidBecomeActiveNotification() {
        let notificationExpectation = expectation(forNotification: .UIApplicationDidBecomeActive,
                                                  object: nil,
                                                  handler: nil)
        UIApplication.onDidEnterForeground()
        wait(for: [notificationExpectation], timeout: 0.1)
    }

    func testApplicationPostsWillResignActiveNotification() {
        let notificationExpectation = expectation(forNotification: .UIApplicationWillResignActive,
                                                  object: nil,
                                                  handler: nil)
        UIApplication.onWillEnterBackground()
        wait(for: [notificationExpectation], timeout: 0.1)
    }

    func testApplicationPostsDidEnterBackgroundNotification() {
        let notificationExpectation = expectation(forNotification: .UIApplicationDidEnterBackground,
                                                  object: nil,
                                                  handler: nil)
        UIApplication.onDidEnterBackground()
        wait(for: [notificationExpectation], timeout: 0.1)
    }
}

