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
        SDL.window = self

        if let viewController = rootViewController {
            viewController.loadViewIfNeeded()
            viewController.view.frame = self.bounds
            addSubview(viewController.view)
            viewController.next = self // set responder
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
            hitView.touchesBegan(allTouches, with: event)

        case .moved:
            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesMoved(allTouches, with: event) }
            if !currentTouch.hasBeenCancelledByAGestureRecognizer {
                hitView.touchesMoved(allTouches, with: event)
            }

        case .ended:
            currentTouch.runTouchActionOnRecognizerHierachy { $0.touchesEnded(allTouches, with: event) }
            if !currentTouch.hasBeenCancelledByAGestureRecognizer {
                hitView.touchesEnded(allTouches, with: event)
            }

            UIEvent.activeEvents.remove(event)
        }
    }

    internal func deepestPresentedView() -> UIView {
        // We want to use the presented view controllers to catch pop-over views etc
        // that are not necessarily visible at the centre of the window.

        let deepestViewControllerView = (rootViewController?.deepestPresentedViewController.view) ?? self

        return deepestViewControllerView.deepestVisibleViewAtCenter()
    }
}

private extension UIView {
    func deepestVisibleViewAtCenter() -> UIView {
        return hitTest(CGPoint(x: bounds.midX, y: bounds.midY), with: nil) ?? self
    }
}

private extension UIViewController {
    var deepestPresentedViewController: UIViewController {
        var deepestViewController = self
        while let newDeepest = deepestViewController.presentedViewController {
            deepestViewController = newDeepest
        }
        return deepestViewController
    }
}

private extension UITouch {
    var hasBeenCancelledByAGestureRecognizer: Bool {
        return gestureRecognizers.contains(where: { ($0.state == .changed) && $0.cancelsTouchesInView })
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
