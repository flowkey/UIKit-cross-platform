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

    open func makeKeyAndVisible() {
        self.safeAreaInsets = UIWindow.getRootWindowInsets()
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
            let allTouches = event.allTouches,
            let currentTouch = allTouches.first,
            let hitView = currentTouch.view ?? hitTest(currentTouch.location(in: nil), with: nil)
        else { return }

        switch currentTouch.phase {
        case .began:
            UIEvent.activeEvents.insert(event)
            currentTouch.view = hitView
            currentTouch.gestureRecognizers = hitView.getRecognizerHierachy()

            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesBegan(allTouches, with: event) }

            if !currentTouch.hasBeenCancelledByAGestureRecognizer {
                hitView.touchesBegan(allTouches, with: event)
            }

        case .moved:
            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesMoved(allTouches, with: event) }
            if !currentTouch.hasBeenCancelledByAGestureRecognizer {
                hitView.touchesMoved(allTouches, with: event)
            }

        case .ended:
            // compute the value before ending the touch on the recognizer hierachy
            // otherwise `hasBeenCancelledByAGestureRecognizer` will be false because the state was reset already
            let hasBeenCancelledByAGestureRecognizer = currentTouch.hasBeenCancelledByAGestureRecognizer

            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesEnded(allTouches, with: event) }

            if !hasBeenCancelledByAGestureRecognizer {
                hitView.touchesEnded(allTouches, with: event)
            }

            UIEvent.activeEvents.remove(event)
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
