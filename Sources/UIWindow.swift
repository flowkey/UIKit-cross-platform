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
        guard let allTouches = event.allTouches else { return }
        UIEvent.activeEvents.insert(event)

        for touch in allTouches {
            guard let hitView = touch.view ?? hitTest(touch.location(in: nil), with: nil) else { return }

            switch touch.phase {
            case .began:
                touch.view = hitView
                touch.gestureRecognizers = hitView.getRecognizerHierachy()

                touch.runTouchActionOnRecognizerHierachy { $0.touchesBegan([touch], with: event) }
                hitView.touchesBegan([touch], with: event)

            case .moved:
                touch.runTouchActionOnRecognizerHierachy { $0.touchesMoved([touch], with: event) }
                if !touch.hasBeenCancelledByAGestureRecognizer {
                    hitView.touchesMoved([touch], with: event)
                }

            case .ended:
                touch.runTouchActionOnRecognizerHierachy { $0.touchesEnded([touch], with: event) }
                if !touch.hasBeenCancelledByAGestureRecognizer {
                    hitView.touchesEnded([touch], with: event)
                }

                event.allTouches?.remove(touch)
                if event.allTouches?.isEmpty == true {
                    UIEvent.activeEvents.remove(event)
                }
            }
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
