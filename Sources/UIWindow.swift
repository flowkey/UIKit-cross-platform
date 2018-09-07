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
        // NOTE: if it's not a touch event, we don't do anything
        guard
            let allTouches = event.allTouches,
            let currentTouch = allTouches.first,
            let hitView = currentTouch.view ?? hitTest(currentTouch.location(in: nil), with: nil)
        else { return }

        switch currentTouch.phase {
        case .began:
            // TODO: inserting event on every .began is conceptually wrong - we only ever have 'singleton' event
            // perhaps we're re-inserting that existing one? does that make it right? 
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
            // MARK: remove event
            UIEvent.activeEvents.remove(event)
            print("After removing, left with \(UIEvent.activeEvents.count)")
        }
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
