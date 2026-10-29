//
//  UIViewMiscellaneousTests
//  UIKitTests
//
//  Created by Geordie Jay on 21.02.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest

@MainActor
class UIViewMiscellaneousTests: XCTestCase {
    func testNeedsLayoutDefaultTrue() {
        class ParentView: UIView {
            override func layoutSubviews() {
                super.layoutSubviews()
                for view in subviews { view.frame.size = CGSize(width: 300, height: 100) }
            }
        }
        let parentView = ParentView()
        let subview = UIView(frame: .zero)
        parentView.addSubview(subview)
        parentView.layoutIfNeeded()

        XCTAssertEqual(subview.frame.width, 300)
        XCTAssertEqual(subview.frame.height, 100)
    }

    func testCenterIsTheLayerPosition() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
        view.layer.anchorPoint = CGPoint(x: 0.5, y: 0.8)
        view.transform = CGAffineTransform(rotationAngle: .pi / 4)

        view.center = CGPoint(x: 50, y: 60)

        XCTAssertEqual(view.layer.position, CGPoint(x: 50, y: 60))
        XCTAssertEqual(view.bounds.size, CGSize(width: 20, height: 10))
    }

    func testPreventStrongReferenceCyclesBetweenSubviews() {
        var view: UIView? = UIView()
        view!.addSubview(UIView())

        weak var subview = view?.subviews.first
        XCTAssertNotNil(subview)

        view = nil
        XCTAssertNil(subview)
    }

}
