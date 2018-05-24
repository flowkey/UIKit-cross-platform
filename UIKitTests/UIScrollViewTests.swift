//
//  UIScrollViewTests.swift
//  UIKitTests
//
//  Created by flowing erik on 25.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

let initialSize = CGSize(width: 1000, height: 1000)
let initialOrigin = CGPoint(x: 0, y: 0)

class UIScrollViewTests: XCTestCase {
    // REVIEW NOTE: is there a way to run the same tests on iOS? would be pretty cool to ensure behaviour is the same or compare it

    func testDefaultValuesOfProperties() {
        // anything set by default: contentSize zero, shows both indicators, etc
    }
    
    func testInitialProperties() {
        let scrollView = UIScrollView(frame: CGRect(origin: initialOrigin, size: initialSize))
        
        XCTAssertEqual(scrollView.frame.origin, initialOrigin)
        XCTAssertEqual(scrollView.frame.size, initialSize)
        
        XCTAssertEqual(scrollView.contentOffset, CGPoint.zero)
        XCTAssertEqual(scrollView.contentSize, CGSize.zero)
        XCTAssertEqual(scrollView.contentInset, UIEdgeInsets.zero)
        
        let arbitraryContentOffset = CGPoint(x: 10, y: 20)
        scrollView.contentOffset = arbitraryContentOffset
        XCTAssertEqual(scrollView.contentOffset, arbitraryContentOffset)
        
        let arbitraryContentSize = CGSize(width: 5, height: 10)
        scrollView.contentSize = arbitraryContentSize
        XCTAssertEqual(scrollView.contentSize, arbitraryContentSize)
        
        let arbitraryContentInset = UIEdgeInsets(top: 12, left: 0, bottom: 2, right: 4)
        scrollView.contentInset = arbitraryContentInset
        XCTAssertEqual(scrollView.contentInset, arbitraryContentInset)
        
    }
    
    
    func testShowsIndicatorsProperties() {
        let scrollView = UIScrollView(frame: CGRect(origin: initialOrigin, size: initialSize))
        // REVIEW NOTE: this is testing sth very basic and might be unnecessary or too bloated
        // REVIEW NOTE: perhaps inclue in testInitial or testDefault
        
        // true by default
        XCTAssertTrue(scrollView.showsHorizontalScrollIndicator)
        XCTAssertTrue(scrollView.showsVerticalScrollIndicator)
        
        // reacts to setting to false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        XCTAssertFalse(scrollView.showsHorizontalScrollIndicator)
        XCTAssertFalse(scrollView.showsVerticalScrollIndicator)
        
        // reacts to setting to true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        
        XCTAssertTrue(scrollView.showsHorizontalScrollIndicator)
        XCTAssertTrue(scrollView.showsVerticalScrollIndicator)
    }
    

    
    func testScrollIndicatorsVisibility() {
        let scrollView = UIScrollView(frame: CGRect(origin: initialOrigin, size: initialSize))
        
        // initially not visible
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame, CGRect.zero)
        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame, CGRect.zero)
        XCTAssertEqual(scrollView.contentSize, CGSize.zero)

        // with touch, (but contentSize < bounds) - not visible. section can probably be removed later
        mockTouch(toPoint: CGPoint(x: 100, y: 100), inScrollView: scrollView)
        XCTAssertEqual(scrollView.contentSize, CGSize.zero)
        XCTAssertEqual(scrollView.verticalScrollIndicator.frame, CGRect.zero)
        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame, CGRect.zero)
        
        // setting contenOffset artificially
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
        // for now just test if they're not out of bounds
        let scrollView = UIScrollView(frame: CGRect(origin: initialOrigin, size: initialSize))
        scrollView.contentSize = CGSize(width: 3000, height: 3000)
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
        // note: `origin` in case of scrollViews is currently anchored in the middle
        let desiredVerticalIndicatorStartPosition = CGPoint(x: scrollView.bounds.size.width - scrollView.verticalScrollIndicator.frame.size.width,
                                                            y: 0 + scrollView.verticalScrollIndicator.frame.size.height / 2)
        let desiredHorizontalIndicatorStartPosition = CGPoint(x: 0 + scrollView.horizontalScrollIndicator.frame.size.width / 2,
                                                              y: scrollView.bounds.size.height - scrollView.horizontalScrollIndicator.frame.size.height)
        
        
        
        // TODO: scrollView should not be able to set it's contentoffset larger than size
        // test how this works in iOS and reimplement
        scrollView.contentOffset = CGPoint(x: 5000, y: 5000)
        let desiredVerticalIndicatorMaxPosition = CGPoint(x: scrollView.bounds.size.width - scrollView.verticalScrollIndicator.frame.size.width,
                                                            y: 0 + scrollView.verticalScrollIndicator.frame.size.height / 2)
        let desiredHorizontalIndicatorMaxPosition = CGPoint(x: 0 + scrollView.horizontalScrollIndicator.frame.size.width / 2,
                                                              y: scrollView.bounds.size.height - scrollView.horizontalScrollIndicator.frame.size.height)
        //would fail
//        XCTAssertEqual(scrollView.verticalScrollIndicator.frame.origin, desiredVerticalIndicatorMaxPosition)
//        XCTAssertEqual(scrollView.horizontalScrollIndicator.frame.origin, desiredHorizontalIndicatorMaxPosition)
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
