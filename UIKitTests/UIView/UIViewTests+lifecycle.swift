//
//  UIViewTests+lifecycle.swift
//  UIKit
//
//  Created by Janek Szynal on 10.08.2018.
//  Copyright © 2018 flowkey. All rights reserved.
//

import XCTest

private let layoutSubviews: [UIViewLifecycleMoment]  = [.beforeLayoutSubviews, .afterLayoutSubviews]
private let sizeToFit: [UIViewLifecycleMoment] = [.beforeSizeToFit, .beforeSizeThatFits, .afterSizeThatFits, .afterSizeToFit]



class UIViewLifecycleTests: XCTestCase {
    static var globalLifecycleLog = [UIViewLifecycleMoment]()

    var view = UIView(frame: .zero)

    override func setUp() {
        super.setUp()
        UIViewLifecycleTests.globalLifecycleLog = []


        view = UIView(frame: .zero)
    }

    func testSizeToFitOnSingleView() {
        let childView = LifecycleLoggingView(frame: .zero)
        view.addSubview(childView)
        childView.sizeToFit()

        XCTAssert(childView.lifecycleLog == sizeToFit)
        XCTAssert(UIViewLifecycleTests.globalLifecycleLog == sizeToFit)
    }

    func testSizeToFitOnViewWithLabel() {
        let childView = LifecycleLoggingView(frame: .zero)
        let grandchildLabel = LifecycleLoggingLabel(frame: .zero)

        grandchildLabel.text = "Test"
        
        view.addSubview(childView)
        childView.addSubview(grandchildLabel)

        childView.sizeToFit()

        XCTAssert(childView.lifecycleLog == sizeToFit)
        XCTAssert(grandchildLabel.lifecycleLog == [])

        XCTAssert(UIViewLifecycleTests.globalLifecycleLog == sizeToFit)
    }
    
}


class LifecycleLoggingView: UIView, LifecycleLogging {

    var lifecycleLog: [UIViewLifecycleMoment] = []

    override func layoutSubviews() {
        logMoment(.beforeLayoutSubviews)
        super.layoutSubviews()
        logMoment(.afterLayoutSubviews)
    }

    override func sizeToFit() {
        logMoment(.beforeSizeToFit)
        super.sizeToFit()
        logMoment(.afterSizeToFit)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        logMoment(.beforeSizeThatFits)
        let result = super.sizeThatFits(size)
        logMoment(.afterSizeThatFits)
        return result
    }
}

class LifecycleLoggingLabel: UILabel, LifecycleLogging {

    var lifecycleLog: [UIViewLifecycleMoment] = []


    convenience init(withFrame frame: CGRect) {
        self.init(frame: frame)
    }

    override func layoutSubviews() {
        logMoment(.beforeLayoutSubviews)
        super.layoutSubviews()
        logMoment(.afterLayoutSubviews)
    }

    override func sizeToFit() {
        logMoment(.beforeSizeToFit)
        super.sizeToFit()
        logMoment(.afterSizeToFit)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        logMoment(.beforeSizeThatFits)
        let result = super.sizeThatFits(size)
        logMoment(.afterSizeThatFits)
        return result
    }
}

protocol LifecycleLogging: class {
    var lifecycleLog: [UIViewLifecycleMoment] {get set}
    func logMoment(_ : UIViewLifecycleMoment)
}

extension LifecycleLogging {
    func logMoment(_ moment: UIViewLifecycleMoment) {
        lifecycleLog.append(moment)
        UIViewLifecycleTests.globalLifecycleLog.append(moment)
    }
}

enum UIViewLifecycleMoment {
    case beforeSizeToFit
    case afterSizeToFit
    case beforeSizeThatFits
    case afterSizeThatFits
    case beforeLayoutSubviews
    case afterLayoutSubviews
}
