//
//  UIWindow.swift
//  UIKit
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIWindow: UIView {
    public static var main: UIWindow {
        return SDL.rootView
    }

    public func sendEvent(_ event: UIEvent) {
        guard
            let allTouches = event.allTouches,
            let currentTouch = allTouches.first,
            let hitView = currentTouch.view ?? hitTest(currentTouch.location(in: nil), with: nil),
            !currentTouch.hasBeenCancelledByAGestureRecognizer
        else { return }

        switch currentTouch.phase {
        case .began:
            UIEvent.activeEvents.insert(event)

            currentTouch.view = hitView
            runRecognizerChain({ $0.touchesBegan(allTouches, with: event) }, on: hitView)
            hitView.touchesBegan(allTouches, with: event)

        case .moved:
            runRecognizerChain({ $0.touchesMoved(allTouches, with: event) }, on: hitView)
            hitView.touchesMoved(allTouches, with: event)

        case .ended:
            runRecognizerChain({ $0.touchesEnded(allTouches, with: event) }, on: hitView)
            hitView.touchesEnded(allTouches, with: event)

            UIEvent.activeEvents.remove(event)
        }
    }

    private func runRecognizerChain(_ action: (_ recognizer: UIGestureRecognizer)->Void, on view: UIView) {
        for recognizer in view.gestureRecognizers {
            action(recognizer)
        }

        if let superview = view.superview, view.gestureRecognizers.isEmpty {
            runRecognizerChain(action, on: superview)
        }
    }
}

private extension UITouch {
    var hasBeenCancelledByAGestureRecognizer: Bool {
        return gestureRecognizers.contains(where: { ($0.state == .changed) && $0.cancelsTouchesInView })
    }
}
