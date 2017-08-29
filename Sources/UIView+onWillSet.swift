//
//  UIView+willSet.swift
//  UIKit
//
//  Created by Michael Knoch on 29.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension UIView {
    func onWillSet(newOpacity: Float) {
        if UIView.shouldAnimate,
            let prototype = UIView.currentAnimationPrototype {
            let animation = prototype.createAnimation(
                keyPath: .opacity,
                fromValue: layer.getCurrentState(for: prototype.options).opacity,
                toValue: newOpacity
            )
            layer.add(animation)
        } else {
            layer.removeAllAnimationsAndNotifyGroups(for: .opacity)
        }
    }

    func onWillSet(newFrame: CGRect) {
        if UIView.shouldAnimate,
            let prototype = UIView.currentAnimationPrototype {
            let animation = prototype.createAnimation(
                keyPath: .frame,
                fromValue: layer.getCurrentState(for: prototype.options).frame,
                toValue: newFrame
            )
            layer.add(animation)
        } else {
            layer.removeAllAnimationsAndNotifyGroups(for: .frame)
        }
    }

    func onWillSet(newBounds: CGRect) {
        if UIView.shouldAnimate,
            let prototype = UIView.currentAnimationPrototype {
            let animation =  prototype.createAnimation(
                keyPath: .bounds,
                fromValue: layer.getCurrentState(for: prototype.options).bounds,
                toValue: newBounds
            )
            layer.add(animation)
        } else {
            layer.removeAllAnimationsAndNotifyGroups(for: .bounds)
        }
    }
}

 extension CALayer {
    func add(_ animation: CABasicAnimation) {
        animation.animationGroup?.queuedAnimations += 1
        animations.append((nil, animation))
    }

    func removeAnimationAndNotifyGroup(animation: CABasicAnimation) {
        animation.animationGroup?.animationDidStop(finished: animation.isComplete)
        animations = animations.filter { $0.animation != animation }
    }

    fileprivate func removeAllAnimationsAndNotifyGroups(for keyPath: AnimationProperty) {
        animations
            .filter { $0.animation.keyPath == keyPath }
            .forEach { removeAnimationAndNotifyGroup(animation: $0.animation) }
    }

    fileprivate func getCurrentState(for options: UIViewAnimationOptions) -> CALayer {
        return options.contains(.beginFromCurrentState) ? (presentation ?? self) : self
    }
}
