//
//  Animations.swift
//  UIKit
//
//  Created by Michael Knoch on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {

    func onWillSet(_ newOpacity: CGFloat) {
        if UIView.animationDuration > 0 && newOpacity != opacity {
            let animation = CABasicAnimation(keyPath: .opacity)
            animation.fromValue = opacity
            animation.toValue = newOpacity
            animation.duration = CGFloat(UIView.animationDuration)

            self.add(animation, forKey: "opacity")
        }
    }

    func onWillSet(_ newFrame: CGRect) {
        if UIView.animationDuration > 0 && newFrame != frame {
            let animation = CABasicAnimation(keyPath: .frame)
            animation.fromValue = frame
            animation.toValue = newFrame
            animation.duration = CGFloat(UIView.animationDuration)

            self.add(animation, forKey: "frame")
        }
    }

    open func add(_ animation: CABasicAnimation, forKey key: String) {
        // use previous fromValue when animation already exists
        // this is necessary when onWillSet is called multiple times for one animation
        if let fromValue = animations[key]?.fromValue {
            animation.fromValue = fromValue
        }
        animations[key] = animation
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    func ensurePresenTationExists() {
        guard presentation == nil else { return }

        presentation = CALayer()
        presentation?.frame = self.frame
        presentation?.opacity = self.opacity
    }

    func animate() {
        animations.forEach { key, animation in
            guard let keypath = animation.keyPath, animation.duration > 0 else { return }
            switch keypath as CABasicAnimation.AnimationProperty {
            case .frame:

                let endFrame = animation.toValue as! CGRect
                let startFrame = animation.fromValue as! CGRect

                let multipliedDiff = startFrame.diff(endFrame).multiply(animation.progress)
                presentation?.frame = startFrame + multipliedDiff

            case .opacity:
                guard
                    let startOpacity = animation.fromValue as? CGFloat,
                    let endOpacity = animation.toValue as? CGFloat
                    else { return }

                let opacityDiff = (endOpacity - startOpacity) * animation.progress
                presentation?.opacity = startOpacity + opacityDiff

            default: break
            }

            if animation.progress == 1 && animation.isRemovedOnCompletion {
                removeAnimation(forKey: key)
            }
        }
    }
}

fileprivate extension CGRect {
    func diff(_ otherRect: CGRect) -> CGRect {
        return CGRect(
            x: otherRect.origin.x - self.origin.x,
            y: otherRect.origin.y - self.origin.y,
            width: otherRect.width - self.width,
            height: otherRect.height - self.height
        )
    }

    func multiply(_ multiplier: CGFloat) -> CGRect {
        return CGRect(
            x: self.origin.x * multiplier,
            y: self.origin.y * multiplier,
            width: self.width * multiplier,
            height: self.height * multiplier
        )
    }

    static func +(lhs: CGRect, rhs: CGRect) -> CGRect {
        return CGRect(
            x: lhs.origin.x + rhs.origin.x,
            y: lhs.origin.y + rhs.origin.y,
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
}
