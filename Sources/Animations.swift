//
//  Animations.swift
//  UIKit
//
//  Created by Michael Knoch on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {
    open func add(_ animation: CABasicAnimation, forKey key: String) {
        // use previous fromValue when animation already exists
        // this is necessary when onWillSet is called multiple times for one animation
        if let fromValue = animations[key]?.fromValue {
            animation.fromValue = fromValue
        }

        // fallback if fromValue is not provided
        if animation.fromValue == nil, let keypath = animation.keyPath {
            switch keypath as CABasicAnimation.AnimationProperty  {
            case .frame:
                animation.fromValue = animation.fromValue ?? frame
            case .opacity:
                animation.fromValue = animation.fromValue ?? opacity
            case .unknown: break
            }
        }

        animations[key] = animation
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    func onWillSet(_ newOpacity: CGFloat) {
        if UIView.animationDuration > 0 && newOpacity != opacity {
            let animation = CABasicAnimation(keyPath: .opacity)
            animation.fromValue = opacity
            animation.toValue = newOpacity
            animation.duration = CGFloat(UIView.animationDuration)
            animation.delay = CGFloat(UIView.animationDelay)

            self.add(animation, forKey: "opacity")
        }
    }

    func onWillSet(_ newFrame: CGRect) {
        if UIView.animationDuration > 0 && newFrame != frame {
            let animation = CABasicAnimation(keyPath: .frame)
            animation.fromValue = frame
            animation.toValue = newFrame
            animation.duration = CGFloat(UIView.animationDuration)
            animation.delay = CGFloat(UIView.animationDelay)

            self.add(animation, forKey: "frame")
        }
    }

    func onDidSetAnimations() {
        if animations.count != 0 {
            presentation = presentation ?? self.clone()
        } else {
            presentation = nil
        }

        link.isPaused = animations.count == 0
    }

    func animate() {
        animations.forEach { key, animation in
            guard let keypath = animation.keyPath, animation.duration > 0 else { return }

            switch keypath as CABasicAnimation.AnimationProperty {
            case .frame:
                guard
                    let startFrame = animation.fromValue as? CGRect,
                    let endFrame = animation.toValue as? CGRect
                    else { return }

                presentation?.frame = startFrame + startFrame.diff(endFrame).multiply(animation.progress)

            case .opacity:
                guard
                    let startOpacity = animation.fromValue as? CGFloat,
                    let endOpacity = animation.toValue as? CGFloat
                    else { return }

                let opacityDiff = (endOpacity - startOpacity) * animation.progress
                presentation?.opacity = startOpacity + opacityDiff

            case .unknown: print("unknown animation property")
            }

            if animation.progress == 1 && animation.isRemovedOnCompletion {
                removeAnimation(forKey: key)
            }
        }
    }

    fileprivate func clone() -> CALayer {
        let clone = CALayer()
        clone.frame = self.frame
        clone.opacity = self.opacity
        clone.backgroundColor = self.backgroundColor
        clone.isHidden = self.isHidden
        clone.cornerRadius = self.cornerRadius
        clone.borderWidth = self.borderWidth
        clone.borderColor = self.borderColor
        clone.shadowColor = self.shadowColor
        clone.shadowRadius = self.shadowRadius
        clone.shadowOpacity = self.shadowOpacity

        //clone.backgroundColor = UIColor.init(red: 255, green: 0, blue: 255, alpha: 0.1)

        return clone
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
