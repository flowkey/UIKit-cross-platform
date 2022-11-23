//
//  UIViewControllerTests.swift
//  UIKitTests
//
//  Created by Geordie Jay on 23.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
import UIKit

@MainActor
class UIViewControllerTests: XCTestCase {
    func testPresentedViewControllerViewHasCorrectFrameOnPhone() {
        let testFrame = CGRect(x: 0, y: 0, width: 300, height: 200)
        let viewController = UIViewController(nibName: nil, bundle: nil)

        viewController.view.frame = testFrame

        let presentedViewController = UIViewController(nibName: nil, bundle: nil)
        viewController.present(presentedViewController, animated: false)

        // Matches iOS: Presented VC always has screen bounds even if the original VC didn't.
        XCTAssertNotEqual(testFrame, UIScreen.main.bounds)
        XCTAssertEqual(presentedViewController.view.frame, UIScreen.main.bounds)
    }

    func testNoMemoryLeakExistsInSimpleCase() {
        var viewController: UIViewController? = UIViewController(nibName: nil, bundle: nil)
        var otherViewController: UIViewController? = UIViewController(nibName: nil, bundle: nil)
        viewController?.present(otherViewController!, animated: false)

        weak var weakViewController = viewController
        weak var weakViewControllerView = viewController?.view
        weak var weakOtherViewControllerView = otherViewController?.view

        XCTAssertNotNil(weakViewControllerView)
        XCTAssertNotNil(weakOtherViewControllerView)

        viewController = nil
        otherViewController = nil

        // otherViewController should be owned by viewController but there should be no reference cycle between them
        XCTAssertNil(otherViewController)
        XCTAssertNil(weakViewController)

        // The views should be nil now too
        XCTAssertNil(weakViewControllerView)
        XCTAssertNil(weakOtherViewControllerView)
    }

    func testPresentedAndPresentingViewController() {
        let viewController = UIViewController(nibName: nil, bundle: nil)
        let otherViewController = UIViewController(nibName: nil, bundle: nil)

        viewController.present(otherViewController, animated: false)
        XCTAssert(viewController.presentedViewController === otherViewController)
        XCTAssert(otherViewController.presentingViewController === viewController)

        otherViewController.dismiss(animated: false)
        XCTAssertNil(viewController.presentedViewController)
        XCTAssertNil(otherViewController.presentingViewController)
    }

    func testMemoryLeakInNavigationController() {
        var viewController: UIViewController? = UIViewController(nibName: nil, bundle: nil)
        var otherViewController: UIViewController? = UIViewController(nibName: nil, bundle: nil)
        var navigationController: UINavigationController? = UINavigationController(rootViewController: otherViewController!)

        viewController!.present(navigationController!, animated: false)
        XCTAssert(viewController!.presentedViewController === navigationController)
        XCTAssert(navigationController!.presentingViewController === viewController)
        XCTAssert(navigationController!.presentedViewController === otherViewController)
        XCTAssert(otherViewController!.presentingViewController === navigationController)


        navigationController!.dismiss(animated: false)

        weak var weakViewController = viewController
        weak var weakOtherViewController = otherViewController
        weak var weakNavigationController = navigationController

        viewController = nil
        otherViewController = nil
        navigationController = nil

        XCTAssertNil(weakViewController)
        XCTAssertNil(weakOtherViewController)
        XCTAssertNil(weakNavigationController)
    }
}
