//
//  UIScrollViewTests.swift
//  UIKitTests
//
//  Created by flowing erik on 25.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

private let initialSize = CGSize(width: 800, height: 450)
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

    func testInitialProperties() { // name change
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

    func testScrollIndicatorsViewHierarchyPositions() {
        // subviews[0] is the back-most view, higher indexes are higher in layer hierarchy
        // we want scroll indicators to always remain on top of 'normal' subviews
        // and we want newer 'normal' subviews to be above older ones

        let label1 = UILabel()
        let label2 = UILabel()
        scrollView.addSubview(label1)
        scrollView.addSubview(label2)

        let horizontalIndicatorIndex = scrollView.subviews.index(of: scrollView.horizontalScrollIndicator)!
        let verticalIndicatorIndex = scrollView.subviews.index(of: scrollView.verticalScrollIndicator)!
        let label1Index = scrollView.subviews.index(of: label1)!
        let label2Index = scrollView.subviews.index(of: label2)!

        XCTAssert(horizontalIndicatorIndex > label1Index)
        XCTAssert(verticalIndicatorIndex > label1Index)

        XCTAssert(label2Index > label1Index)
        XCTAssertEqual(scrollView.subviews.count, 2)
    }

    func testScrollIndicatorsVisibility() {
        //TODO: update to match iOS behaviour:
        //1. frame is always there, alpha changes from 0 to 1
        //2. behaviour contentOffset set programatically yet to be thoroughly tested
        XCTAssertEqual(scrollView.contentSize, .zero)
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame, .zero)
        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame, .zero)

        mockTouch(toPoint: CGPoint(x: 100, y: 100), inScrollView: scrollView)
        XCTAssertEqual(scrollView.contentSize, .zero)
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame, .zero)
        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame, .zero)

        // setting contenOffset manually
        // TODO: check x and y separately
        scrollView.contentSize = CGSize(width: 3000, height: 3000)
        scrollView.contentOffset = CGPoint(x: 100, y: 100)
        XCTAssertNotEqual(scrollView.verticalScrollIndicator.frame, .zero)
        XCTAssertNotEqual(scrollView.horizontalScrollIndicator.frame, .zero)

        mockTouch(toPoint: CGPoint(x: 100, y: 100), inScrollView: scrollView)
        XCTAssertNotEqual(scrollView.verticalScrollIndicator.frame, .zero)
        XCTAssertNotEqual(scrollView.horizontalScrollIndicator.frame, .zero)

        // XXX: test only one dimension at a time
        // TODO: test fading out after it's implelented in scrollView
    }

    func testScrollIndicatorsPositionStart() {
        scrollView.contentSize = CGSize(width: 3000, height: 3000)
        scrollView.contentOffset = CGPoint(x: 0, y: 0)

        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame.origin, .zero)
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame.origin, .zero)
    }

    // Currently broken: the expected positions aren't correct
//    func testScrollIndicatorsPositionEnd() {
//        scrollView.contentSize = CGSize(width: 3000, height: 3000)
//        scrollView.contentOffset = CGPoint(x: 3000, y: 3000)
//
//        let indicatorInnerEdge = scrollView.indicatorThickness - UIScrollView.indicatorDistanceFromScrollViewFrame
//        let expectedHIndicatorPosition = CGPoint(x: 0, y: scrollView.bounds.height - indicatorInnerEdge)
//        let expectedVIndicatorPosition = CGPoint(x: scrollView.bounds.width - indicatorInnerEdge, y: 0)
//
//        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame.origin, expectedHIndicatorPosition)
//        XCTAssertEqual(scrollView.verticalScrollIndicator.frame.origin, expectedVIndicatorPosition)
//    }

    // TODO: test final position. [blocked by setting contentOffset programatically - test behaviour in iOS]

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
        let mockTouch = UITouch(touchId: 0, at: CGPoint(x: 0, y: 0), timestamp: 0)

        scrollView.panGestureRecognizer.touchesBegan([mockTouch], with: UIEvent())
        mockTouch.updateAbsoluteLocation(CGPoint(x: 100, y: 100))
        scrollView.panGestureRecognizer.touchesMoved([mockTouch], with: UIEvent())
        scrollView.panGestureRecognizer.touchesEnded([mockTouch], with: UIEvent())
    }
}
