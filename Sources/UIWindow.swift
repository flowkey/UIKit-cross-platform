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
        guard
            let currentTouch = event.changedTouch ?? event.allTouches?.first,
            let hitView = currentTouch.view ?? hitTest(currentTouch.location(in: nil), with: nil)
        else { return }

        // Deliver only the touch that changed for this event; `event.allTouches` still exposes every finger
        // down for multi-touch recognizers. For a single finger this is identical to before.
        let phaseTouches: Set<UITouch> = [currentTouch]

        switch currentTouch.phase {
        case .began:
            UIEvent.activeEvents.insert(event)
            currentTouch.view = hitView
            currentTouch.gestureRecognizers = hitView.getRecognizerHierachy()

            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesBegan(phaseTouches, with: event) }

            if !currentTouch.hasBeenCancelledByAGestureRecognizer {
                hitView.touchesBegan(phaseTouches, with: event)
            }

        case .moved:
            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesMoved(phaseTouches, with: event) }
            if !currentTouch.hasBeenCancelledByAGestureRecognizer {
                hitView.touchesMoved(phaseTouches, with: event)
            }

        case .ended:
            // compute the value before ending the touch on the recognizer hierachy
            // otherwise `hasBeenCancelledByAGestureRecognizer` will be false because the state was reset already
            let hasBeenCancelledByAGestureRecognizer = currentTouch.hasBeenCancelledByAGestureRecognizer

            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesEnded(phaseTouches, with: event) }

            if !hasBeenCancelledByAGestureRecognizer {
                hitView.touchesEnded(phaseTouches, with: event)
            }

            event.allTouches?.remove(currentTouch)
            if event.allTouches?.isEmpty ?? true {
                UIEvent.activeEvents.remove(event)
            }
        }
    }
}

private extension UIView {
    func getRecognizerHierachy() -> [UIGestureRecognizer] {
        var recognizerHierachy: [UIGestureRecognizer] = []
        var currentView = self

        while let superview = currentView.superview {
            recognizerHierachy.append(contentsOf: currentView.gestureRecognizers)
            currentView = superview
        }

        return recognizerHierachy
    }
}
