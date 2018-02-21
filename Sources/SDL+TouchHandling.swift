//
//  SDL+TouchHandling.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// TODO: This urgently needs tests!

extension SDL {
    private static func run(
        responderAction: (_ responder: UIResponder)->Void,
        recognizerAction: (_ recognizer: UIGestureRecognizer)->Void,
        on responderChain: UnfoldSequence<UIResponder, (UIResponder?, Bool)>
    ) {
        for responder in responderChain {
            responderAction(responder)

            guard let view = responder as? UIView else { return }
            for recognizer in view.gestureRecognizers {
                recognizerAction(recognizer)
                if (recognizer.cancelsTouchesInView) { return }
            }
        }
    }

    static func handleTouchDown(_ point: CGPoint) {
        guard let hitView = rootView.hitTest(point, with: nil) else { return }

        print("hit", hitView)

        let currentTouch = UITouch(at: point, touchId: 0)
        currentTouch.view = hitView
        UITouch.activeTouches.insert(currentTouch)

        if currentTouch.hasBeenCancelledByAGestureRecognizer { return }

        run(
            responderAction: { $0.touchesBegan([currentTouch], with: nil) },
            recognizerAction: { $0.touchesBegan(UITouch.activeTouches, with: UIEvent()) },
            on: hitView.responderChain
        )
    }

    static func handleTouchMove(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: { $0.touchId == Int(0) }) else { return }

        touch.updateAbsoluteLocation(point)

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            run(
                responderAction: { $0.touchesMoved([touch], with: nil) },
                recognizerAction: { $0.touchesMoved(UITouch.activeTouches, with: UIEvent()) },
                on: hitView.responderChain
            )
        }
    }

    static func handleTouchUp(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: {$0.touchId == Int(0) }) else { return }

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            run(
                responderAction: { $0.touchesEnded([touch], with: nil) },
                recognizerAction: { $0.touchesEnded([touch], with: UIEvent()) },
                on: hitView.responderChain
            )
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
