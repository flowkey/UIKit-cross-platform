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
            viewController.view.backgroundColor = nil
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
            cancelTapGestureRecognizersIfTouchReachesPanGestureRecognizers(for: currentTouch)


            var gestureRecognizers = currentTouch.gestureRecognizers.filter { !($0 is UITapGestureRecognizer) }
            if !gestureRecognizers.isEmpty {
                gestureRecognizers.removeFirst()

                gestureRecognizers.filter { $0.state != .cancelled } .forEach {
                    $0.touchesCancelled(allTouches, with: event)
                }
            }

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

    private func cancelTapGestureRecognizersIfTouchReachesPanGestureRecognizers(for touch: UITouch) {
        let cancelTapGestureRecognizers = touch.gestureRecognizers.contains(where: {
            $0 is UIPanGestureRecognizer && $0.state == .changed
        })

        if cancelTapGestureRecognizers {
            touch.gestureRecognizers.filter { $0 is UITapGestureRecognizer } .forEach {
                $0.touchesCancelled([touch], with: UIEvent())
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
