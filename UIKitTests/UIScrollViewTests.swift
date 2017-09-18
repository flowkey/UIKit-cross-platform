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

    func testDelegateMethods() {
        class DelegationTestScrollView: UIScrollView, UIScrollViewDelegate {

            let beginDraggingExpectation: XCTestExpectation?
            let didScrollExpectation: XCTestExpectation?
            let didEndDraggingExpectation: XCTestExpectation?

            init(beginDragginExpectation: XCTestExpectation?, didScrollExpectation: XCTestExpectation?, didEndDraggingExpectation: XCTestExpectation?){
                self.beginDraggingExpectation = beginDragginExpectation
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
            }

            func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
                self.didEndDraggingExpectation?.fulfill()
            }
        }

        let beginDragginExpectation = expectation(description: "scrollViewWillBeginDragging was called")
        let didScrollExpectation = expectation(description: "scrollViewDidScroll was called")
        let didEndDraggingExpectation = expectation(description: "scrollViewDidEndDragging was called")

        let scrollView = DelegationTestScrollView(
            beginDragginExpectation: beginDragginExpectation,
            didScrollExpectation: nil, // didScrollExpectation,
            didEndDraggingExpectation: nil // didEndDraggingExpectation
        )

        let mockView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        let mockTouch0 = UITouch(at: CGPoint(x: 0, y: 0), in: mockView, touchId: 0)
        let mockTouch1 = UITouch(at: CGPoint(x: 100, y: 100), in: mockView, touchId: 1)
        let mockTouch2 = UITouch(at: CGPoint(x: 200, y: 200), in: mockView, touchId: 2)

        scrollView.panGestureRecognizer.touchesBegan([mockTouch0], with: UIEvent())
        scrollView.panGestureRecognizer.touchesMoved([mockTouch1], with: UIEvent())
        scrollView.panGestureRecognizer.touchesEnded([mockTouch2], with: UIEvent())

        // ToDo: make test pass with didScrollExpectation and didEndDraggingExpectation !
        wait(for: [beginDragginExpectation, didScrollExpectation, didEndDraggingExpectation], timeout: 1.0)
    }
}
