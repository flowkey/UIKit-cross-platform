//
//  SDL+TouchHandling.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// TODO: This urgently needs tests!

extension SDL {
    static func handleTouchDown(_ point: CGPoint) {
        guard let hitView = rootView.hitTest(point, with: UIEvent()) else { return }

        print("hit", hitView)

        let currentTouch = UITouch(at: point, touchId: 0)
        currentTouch.view = hitView
        UITouch.activeTouches.insert(currentTouch)

        hitView.gestureRecognizers.forEach { gestureRecognizer in
            gestureRecognizer.touchesBegan(UITouch.activeTouches, with: UIEvent())
            currentTouch.gestureRecognizers.append(gestureRecognizer)
        }

        if !currentTouch.hasBeenCancelledByAGestureRecognizer {
            for responder in hitView.responderChain {
                responder.touchesBegan([currentTouch], with: nil)
            }
        }
    }

    static func handleTouchMove(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: { $0.touchId == Int(0) }) else { return }

        touch.updateAbsoluteLocation(point)
        touch.gestureRecognizers.forEach { gestureRecognizer in
            gestureRecognizer.touchesMoved(UITouch.activeTouches, with: UIEvent())
        }

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            for responder in hitView.responderChain {
                responder.touchesMoved([touch], with: nil)
            }
        }
    }

    static func handleTouchUp(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: {$0.touchId == Int(0) }) else { return }

        touch.gestureRecognizers.forEach { gestureRecognizer in
            // TODO: make only the touches that have actually ended end, same with moved and started above
            gestureRecognizer.touchesEnded([touch], with: UIEvent())
        }

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            for responder in hitView.responderChain {
                responder.touchesEnded([touch], with: nil)
            }
        }
        
        UITouch.activeTouches.remove(touch)
    }
}

protocol SDLEventWithCoordinates {
    var x: Int32 { get }
    var y: Int32 { get }
}

extension SDL_MouseButtonEvent: SDLEventWithCoordinates {}
extension SDL_MouseMotionEvent: SDLEventWithCoordinates {}

extension CGPoint {
    static func from(_ event: SDLEventWithCoordinates) -> CGPoint {
        return SDL.window.absolutePointInOwnCoordinates(x: CGFloat(event.x), y: CGFloat(event.y))
    }
}

private extension UITouch {
    var hasBeenCancelledByAGestureRecognizer: Bool {
        return gestureRecognizers.contains(where: { ($0.state == .changed) && $0.cancelsTouchesInView })
    }
}


private extension UIView {
    var responderChain: UnfoldSequence<UIResponder, (UIResponder?, Bool)> {
        return sequence(first: self as UIResponder, next: { $0.next() })
    }
}
