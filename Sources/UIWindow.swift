//
//  UIWindow.swift
//  UIKit
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIWindow: UIView {
    open var rootViewController: UIViewController? {
        didSet { rootViewController?.next = self }
    }

    override open func layoutIfNeeded() {
        super.layoutIfNeeded()
        subviews.forEach { subview in
            subview.frame = bounds
        }
    }

    open func makeKeyAndVisible() {
        UIApplication.shared?.keyWindow = self

        if let viewController = rootViewController {
            viewController.loadViewIfNeeded()
            viewController.next = self // set responder before viewWillAppear etc.
            viewController.view.frame = self.bounds
            viewController.viewWillAppear(false)
            addSubview(viewController.view)
            viewController.viewDidAppear(false)
        }
    }

    public func sendEvent(_ event: UIEvent) {
        guard let touch = event.changedTouch ?? event.allTouches?.first else { return }
        let touches: Set<UITouch> = [touch]
        touch.event = event

        switch touch.phase {
        case .began:
            guard let hitView = touch.view ?? hitTest(touch.location(in: nil), with: nil) else { return }
            UIEvent.activeEvents.insert(event)
            touch.view = hitView

            for recognizer in hitView.gestureRecognizerHierarchy()
                where recognizer.shouldReceive(touch) && recognizer.canTrackAnotherTouch
            {
                recognizer.add(touch)
            }

            deliver(touch) { $0.touchesBegan(touches, with: event) }
            touch.deliverToView()

        case .moved, .stationary:
            deliver(touch) { $0.touchesMoved(touches, with: event) }
            touch.deliverToView()

        case .ended, .cancelled:
            let recognizers = touch.gestureRecognizers
            if touch.phase == .ended {
                deliver(touch) { $0.touchesEnded(touches, with: event) }
            } else {
                deliver(touch) { $0.touchesCancelled(touches, with: event) }
            }
            touch.deliverToView()

            recognizers.forEach { $0.touchSequenceEnded() }
            recognizers.forEach { $0.failIfStillPending() }

            event.allTouches?.remove(touch)
            if event.allTouches?.isEmpty ?? true {
                UIEvent.activeEvents.remove(event)
                UIGestureRecognizer.resetFinishedRecognizers()
            }
        }
    }

    /// Recognizers can end (and stop tracking the touch) while others are still handling it.
    private func deliver(_ touch: UITouch, _ action: (UIGestureRecognizer) -> Void) {
        for recognizer in touch.gestureRecognizers where recognizer.touches.contains(where: { $0 === touch }) {
            action(recognizer)
        }
    }
}

private extension UIView {
    /// The hit view's recognizers first, then its ancestors', each view's in the order they were added.
    func gestureRecognizerHierarchy() -> [UIGestureRecognizer] {
        var recognizers: [UIGestureRecognizer] = []
        var currentView: UIView? = self
        while let view = currentView {
            recognizers.append(contentsOf: view.gestureRecognizers)
            currentView = view.superview
        }
        return recognizers
    }
}
