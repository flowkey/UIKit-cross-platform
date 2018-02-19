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
        guard let hitView = rootView.hitTest(point, with: nil) else { return }

        print("hit", hitView)

        let currentTouch = UITouch(at: point, touchId: 0)
        currentTouch.view = hitView
        UITouch.activeTouches.insert(currentTouch)

        if currentTouch.hasBeenCancelledByAGestureRecognizer { return }

        responderChainLoop: for responder in hitView.responderChain {
            responder.touchesBegan([currentTouch], with: nil)

            guard let responder = responder as? UIView else { return }
            for recognizer in responder.gestureRecognizers {
                recognizer.touchesBegan(UITouch.activeTouches, with: UIEvent())
                if (recognizer.cancelsTouchesInView) { break responderChainLoop }
            }
        }
    }

    static func handleTouchMove(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: { $0.touchId == Int(0) }) else { return }

        touch.updateAbsoluteLocation(point)

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            responderChainLoop: for responder in hitView.responderChain {
                responder.touchesMoved([touch], with: nil)

                guard let responder = responder as? UIView else { return }
                for recognizer in responder.gestureRecognizers {
                    recognizer.touchesMoved(UITouch.activeTouches, with: UIEvent())
                    if (recognizer.cancelsTouchesInView) { break responderChainLoop }
                }
            }
        }
    }

    static func handleTouchUp(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: {$0.touchId == Int(0) }) else { return }

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            responderChainLoop: for responder in hitView.responderChain {
                responder.touchesEnded([touch], with: nil)

                guard let responder = responder as? UIView else { return }
                for recognizer in responder.gestureRecognizers {
                    recognizer.touchesEnded(UITouch.activeTouches, with: UIEvent())
                    if (recognizer.cancelsTouchesInView) { break responderChainLoop }
                }
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
