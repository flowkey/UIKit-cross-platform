import XCTest
@testable import UIKit

class DraggableViews: XCTestCase {
    let windowFrame = CGRect(x: 0, y: 0, width: 800, height: 450)
    let draggableInitialFrame = CGRect(x: 180, y: 0, width: 20, height: 50)

    var touch = UITouch()
    let initialTouchPoint = CGPoint.zero
    let finalTouchPoint = CGPoint(x: 30, y: 5)

    lazy var expectedDraggableFrameOrigin: CGPoint = {
        return CGPoint(
            x: draggableInitialFrame.origin.x + finalTouchPoint.x - initialTouchPoint.x,
            y: draggableInitialFrame.origin.y + finalTouchPoint.y - initialTouchPoint.y
        )
    }()

    var window = UIWindow()

    override func setUp() {
        window = UIWindow(frame: windowFrame)
        touch = UITouch()
    }

    private func performPan(on draggable: Draggable) {
        draggable.frame = draggableInitialFrame
        window.addSubview(draggable)

        touch.window = window
        touch.view = draggable

        touch.move(to: initialTouchPoint)
        draggable.panHandler.touchesBegan([touch], with: UIEvent())

        touch.move(to: finalTouchPoint)
        draggable.panHandler.touchesMoved([touch], with: UIEvent())
    }


    func testDraggableWithSelfCoordinates() {
        let draggable = Draggable()
        performPan(on: draggable)
        XCTAssertEqual(draggable.frame.origin, expectedDraggableFrameOrigin)
    }

    func testDraggableWithSuperviewCoordinates() {
        let draggable = DraggableBasedInSuperview()
        performPan(on: draggable)
        XCTAssertEqual(draggable.frame.origin, expectedDraggableFrameOrigin)
    }
}

extension UITouch {
    func move(to point: CGPoint) {
        phase = .moved
        timestamp += 20.0
        updateAbsoluteLocation(point)
    }
}


/// This `Draggable` subclass moves based on its own coordinate system
private class Draggable: UIView {
    var panHandler: UIPanGestureRecognizer!

    /// Override this to set the coordinate system in which `panHandler.translation` is returned on `onDrag`
    var translationBaseView: UIView? {
        return self
    }

    convenience init() {
        self.init(frame: .zero)
        panHandler = UIPanGestureRecognizer(onAction: { [unowned self] in self.onDrag() })
        addGestureRecognizer(panHandler)
    }

    private func onDrag() {
        let translation = panHandler.translation(in: translationBaseView)
        self.frame.origin = CGPoint(x: frame.origin.x + translation.x, y: frame.origin.y + translation.y)
        panHandler.setTranslation(.zero, in: translationBaseView)
    }
}


/// This `Draggable` subclass moves based on its superview's coordinate system
private class DraggableBasedInSuperview: Draggable {
    override var translationBaseView: UIView? {
        return superview
    }
}
