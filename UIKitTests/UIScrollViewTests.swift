//
//  UIScrollViewTests.swift
//  UIKitTests
//
//  Created by flowing erik on 25.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

private let initialSize = CGSize(width: 1000, height: 1000)
private let initialOrigin = CGPoint(x: 0, y: 0)


class UIScrollViewTests: XCTestCase {
    
    var scrollView: UIScrollView!
    
    
    override func setUp() {
        scrollView = UIScrollView(frame: CGRect(origin: initialOrigin, size: initialSize))
    }
    
    func testDefaultValuesOfProperties() {
        XCTAssertTrue(scrollView.showsHorizontalScrollIndicator)
        XCTAssertTrue(scrollView.showsVerticalScrollIndicator)
        
        XCTAssertEqual(scrollView.frame.origin, initialOrigin)
        XCTAssertEqual(scrollView.frame.size, initialSize)
        
        XCTAssertEqual(scrollView.contentOffset, .zero)
        XCTAssertEqual(scrollView.contentSize, .zero)
        XCTAssertEqual(scrollView.contentInset, .zero)
    }
    
    
    func testInitialProperties() { //name change

        //instead test if bounds are set
        let arbitraryContentOffset = CGPoint(x: 10, y: 20)
        scrollView.contentOffset = arbitraryContentOffset
        XCTAssertEqual(scrollView.bounds.origin, arbitraryContentOffset)

        let arbitraryContentSize = CGSize(width: 5, height: 10)
        scrollView.contentSize = arbitraryContentSize
        XCTAssertEqual(scrollView.contentSize, arbitraryContentSize)

        let arbitraryContentInset = UIEdgeInsets(top: 12, left: 0, bottom: 2, right: 4)
        scrollView.contentInset = arbitraryContentInset
        XCTAssertEqual(scrollView.contentInset, arbitraryContentInset)
    }
    
    
    func testScrollIndicatorsVisibility() {
        //TODO: update to match iOS behaviour:
        //1. frame is always there, alpha changes from 0 to 1
        //2. behaviour contentOffset set programatically yet to be thoroughly tested
        XCTAssertEqual(scrollView.contentSize, CGSize.zero)
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame, CGRect.zero)
        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame, CGRect.zero)

        mockTouch(toPoint: CGPoint(x: 100, y: 100), inScrollView: scrollView)
        XCTAssertEqual(scrollView.contentSize, CGSize.zero)
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame, CGRect.zero)
        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame, CGRect.zero)

        // setting contenOffset artificially
        //TODO: chceck x and y separately
        scrollView.contentSize = CGSize(width: 3000, height: 3000)
        scrollView.contentOffset = CGPoint(x: 100, y: 100)
        XCTAssertNotEqual(scrollView.verticalScrollIndicator.frame, CGRect.zero)
        XCTAssertNotEqual(scrollView.horizontalScrollIndicator.frame, CGRect.zero)

        // settingContentOffset with a drag
        // NOTE: scrollIndicators currently never fade out,
        // so this will always pass because they were already showing before
        mockTouch(toPoint: CGPoint(x: 100, y: 100), inScrollView: scrollView)
        XCTAssertNotEqual(scrollView.verticalScrollIndicator.frame, CGRect.zero)
        XCTAssertNotEqual(scrollView.horizontalScrollIndicator.frame, CGRect.zero)
        
        // XXX: test only one dimension at a time
        
        // TODO: test fading out after it's implelented in scrollView
    }
    
    func testScrollIndicatorsInitialAndFinalPositions() {
        scrollView.contentSize = CGSize(width: 3000, height: 3000)
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
        let expectedHorizontalIndicatorStartPosition = CGPoint(x: 0, y: scrollView.bounds.size.height - scrollView.indicatorThickness - scrollView.indicatorDistanceFromScrollViewFrame)
        let expectedVerticalIndicatorStartPosition = CGPoint(x: scrollView.bounds.size.width - scrollView.indicatorThickness - scrollView.indicatorDistanceFromScrollViewFrame, y: 0 )

        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame.origin, expectedHorizontalIndicatorStartPosition)
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame.origin, expectedVerticalIndicatorStartPosition)

        //TODO: final position. [blocked by setting contentOffset programatically - test behaviour in iOS]
    }
    

    func testIfScrollIndicatorsAreAccurate() {
        // TODO: how?
    }
    
    func testIfScrollViewBouncesBackAferPullIfNeeded() {
        // TODO: test setting inset and bouncing after it's implented in ScrollView
    }

    func testScrollViewIndicatorStyles() {
        // XXX: set style, test bgr -> does this need to be tested?
    }
    
    func testDelegateMethods() {
        class DelegationTestScrollView: UIScrollView, UIScrollViewDelegate {

            var beginDraggingExpectation: XCTestExpectation?
            var didScrollExpectation: XCTestExpectation?
            var didEndDraggingExpectation: XCTestExpectation?

            init(
                beginDraggingExpectation: XCTestExpectation?,
                didScrollExpectation: XCTestExpectation?,
                didEndDraggingExpectation: XCTestExpectation?
            ) {
                self.beginDraggingExpectation = beginDraggingExpectation
                self.didScrollExpectation = didScrollExpectation
                self.didEndDraggingExpectation = didEndDraggingExpectation
                super.init(frame: .zero)
                self.delegate = self
            }

            func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
                self.beginDraggingExpectation?.fulfill()
            }

            func scrollViewDidScroll(_ scrollView: UIScrollView) {
                self.didScrollExpectation?.fulfill()
                self.didScrollExpectation = nil //  assign nil to avoid multiple calls to didScrollExpectation?.fulfill
            }

            func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
                self.didEndDraggingExpectation?.fulfill()
            }
        }

        let beginDraggingExpectation = expectation(description: "scrollViewWillBeginDragging was called")
        let didScrollExpectation = expectation(description: "scrollViewDidScroll was called")
        let didEndDraggingExpectation = expectation(description: "scrollViewDidEndDragging was called")

        let scrollView = DelegationTestScrollView(
            beginDraggingExpectation: beginDraggingExpectation,
            didScrollExpectation: didScrollExpectation,
            didEndDraggingExpectation: didEndDraggingExpectation
        )

        mockTouch(toPoint: CGPoint(x: 100, y: 100), inScrollView: scrollView)

        wait(for: [beginDraggingExpectation, didScrollExpectation, didEndDraggingExpectation], timeout: 1.0)
    }
    
    func mockTouch(toPoint: CGPoint, inScrollView scrollView: UIScrollView) {
        let mockTouch = UITouch(touchId: 0, at: CGPoint(x: 0, y: 0), in: UIWindow(), timestamp: 0)
        
        scrollView.panGestureRecognizer.touchesBegan([mockTouch], with: UIEvent())
        mockTouch.updateAbsoluteLocation(CGPoint(x: 100, y: 100))
        scrollView.panGestureRecognizer.touchesMoved([mockTouch], with: UIEvent())
        scrollView.panGestureRecognizer.touchesEnded([mockTouch], with: UIEvent())
    }
}
