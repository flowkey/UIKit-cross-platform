//
//  UIScrollViewTests.swift
//  UIKitTests
//
//  Created by flowing erik on 25.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

let initialSize = CGSize(width: 100, height: 100)
let initialOrigin = CGPoint(x: 0, y: 0)

class TestScrollView: UIScrollView, UIScrollViewDelegate {

    init(){
        super.init(frame: CGRect(origin: initialOrigin, size: initialSize))
        self.delegate = self
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("began dragging")
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("didScroll")
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        print("ended dragging")
    }
}

class UIScrollViewTests: XCTestCase {

    func testInitialProperties() {
        let scrollView = TestScrollView()

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
}
