//
//  SDL+TouchHandling.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// TODO: This urgently needs tests!

extension SDL {
    private static func run(_ action: (_ responder: Touchable)->Void, on view: UIView) {
        action(view)

        for responder in view.responderChain {
            guard let view = responder as? UIView else { return }
            for recognizer in view.gestureRecognizers {
                action(recognizer)
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

        run({ $0.touchesBegan([currentTouch], with: nil) }, on: hitView)
    }

    static func handleTouchMove(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: { $0.touchId == Int(0) }) else { return }

        touch.updateAbsoluteLocation(point)

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            run({ $0.touchesMoved([touch], with: nil) }, on: hitView)
        }
    }

    static func handleTouchUp(_ point: CGPoint) {
        guard let touch = UITouch.activeTouches.first(where: {$0.touchId == Int(0) }) else { return }

        if let hitView = touch.view, !touch.hasBeenCancelledByAGestureRecognizer {
            run({ $0.touchesEnded([touch], with: nil) }, on: hitView)
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

protocol Touchable {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
}

extension UIView: Touchable {}
extension UIGestureRecognizer: Touchable {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesBegan(touches, with: event ?? UIEvent())
    }
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesMoved(touches, with: event ?? UIEvent())
    }
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesEnded(touches, with: event ?? UIEvent())
    }
}

