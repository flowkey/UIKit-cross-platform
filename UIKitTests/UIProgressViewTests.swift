//
//  UIProgressViewTests.swift
//  UIKitTests
//
//  Created by Michael Knoch on 26.06.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest
@testable import UIKit

class UIProgressViewTests: XCTestCase {
    var progressView: UIProgressView!

    override func setUp() {
        progressView = UIProgressView()
        progressView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    }

    func testCanSetProgressWithoutAnimation() {
        let newProgress: Float = 0.5
        progressView.setProgress(newProgress, animated: false)

        XCTAssertEqual(progressView.progress, newProgress)
        XCTAssertNil(progressView.progressLayer._presentation)
    }

    func testCanSetProgressWithAnimation() {
        let newProgress: Float = 0.5
        progressView.setProgress(newProgress, animated: true)
        progressView.progressLayer.hasBeenRenderedInThisPartOfOverallLayerHierarchy = true
        progressView.layoutSubviews()

        XCTAssertEqual(progressView.progress, newProgress)
        XCTAssertNotNil(progressView.progressLayer._presentation)
    }

    func testCanSetProgressTintColor() {
        progressView.trackTintColor = .green
        XCTAssertEqual(progressView.backgroundColor, .green)
    }

    func testCanSetTrackTintColor() {
        let color: UIColor = .blue
        progressView.progressTintColor = color
        XCTAssertEqual(progressView.progressLayer.backgroundColor, color.cgColor)
    }
}
