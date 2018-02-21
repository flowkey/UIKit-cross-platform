//
//  UIResponderChainTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 21.02.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UIResponderChainTests: XCTestCase {

    var viewRecognizerOnActionWasCalled = false
    var subsubview: UIView = UIView()

    override func setUp() {
        SDL.rootView = UIWindow(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        let view = UIView(frame: SDL.rootView.bounds)
        SDL.rootView.addSubview(view)

        let viewRecognizer = UIPanGestureRecognizer()
        view.addGestureRecognizer(viewRecognizer)
        
        viewRecognizerOnActionWasCalled = false
        viewRecognizer.onAction = { self.viewRecognizerOnActionWasCalled = true }

        let subview = UIView(frame: SDL.rootView.bounds)
        view.addSubview(subview)

        subsubview = UIView(frame: SDL.rootView.bounds)
        subview.addSubview(subsubview)
    }

    func testResponderChainTriggersGestureRecognizers() {
        SDL.handleTouchDown(CGPoint(x: 10, y: 10))
        SDL.handleTouchMove(CGPoint(x: 15, y: 10))
        SDL.handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(viewRecognizerOnActionWasCalled)
    }

    func touch() {
        
    }

    func testCancelsTouchesInViewTrue() {
        let anotherSubview = UIView(frame: SDL.rootView.bounds)
        subsubview.addSubview(anotherSubview)

        let anotherGestureRecognizer = UIPanGestureRecognizer()
        anotherSubview.addGestureRecognizer(anotherGestureRecognizer)

        var anotherGestureRecognizerOnActionWasCalled = false
        anotherGestureRecognizer.onAction = { anotherGestureRecognizerOnActionWasCalled = true }

        SDL.handleTouchDown(CGPoint(x: 10, y: 10))
        SDL.handleTouchMove(CGPoint(x: 15, y: 10))
        SDL.handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertFalse(viewRecognizerOnActionWasCalled)
        XCTAssertTrue(anotherGestureRecognizerOnActionWasCalled)
    }

    func testCancelsTouchesInViewFalse() {
        let anotherSubview = UIView(frame: SDL.rootView.bounds)
        subsubview.addSubview(anotherSubview)

        let anotherGestureRecognizer = UIGestureRecognizer()
        anotherGestureRecognizer.cancelsTouchesInView = false
        anotherSubview.addGestureRecognizer(anotherGestureRecognizer)

        SDL.handleTouchDown(CGPoint(x: 10, y: 10))
        SDL.handleTouchMove(CGPoint(x: 15, y: 10))
        SDL.handleTouchUp(CGPoint(x: 15, y: 10))

        XCTAssertTrue(viewRecognizerOnActionWasCalled)
    }
}
