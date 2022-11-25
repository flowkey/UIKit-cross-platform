//
//  UIApplication+NSNotificationTests.swift
//  UIKitTests
//
//  Created by Chetan Agarwal on 30.11.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

@MainActor
class UIApplication_NSNotificationTests: XCTestCase {
    func testApplicationPostsWillEnterForegroundNotification() {
        expectation(forNotification: .UIApplicationWillEnterForeground)
        UIApplication.onWillEnterForeground()
        waitForExpectations(timeout: 0)
    }

    func testApplicationPostsDidBecomeActiveNotification() {
        expectation(forNotification: .UIApplicationDidBecomeActive)
        UIApplication.onDidEnterForeground()
        waitForExpectations(timeout: 0)
    }

    func testApplicationPostsWillResignActiveNotification() {
        expectation(forNotification: .UIApplicationWillResignActive)
        UIApplication.onWillEnterBackground()
        waitForExpectations(timeout: 0)
    }

    func testApplicationPostsDidEnterBackgroundNotification() {
        expectation(forNotification: .UIApplicationDidEnterBackground)
        UIApplication.onDidEnterBackground()
        waitForExpectations(timeout: 0)
    }
}

private extension XCTestCase {
    func expectation(forNotification name: UIKit.Notification.Name) {
        let promise = self.expectation(description: "Expectation for \(name.rawValue)")
        let observer = UIKit.NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { notification in
            promise.fulfill()
        }

        self.addTeardownBlock {
            UIKit.NotificationCenter.default.removeObserver(observer)
        }
    }
}
