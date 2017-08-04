//
//  Animations.swift
//  UIKit
//
//  Created by Michael Knoch on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {
    open func add(_ animation: CABasicAnimation, forKey key: String) {

        // fallback if fromValue is not provided
        if animation.fromValue == nil, let keypath = animation.keyPath {
            switch keypath as CABasicAnimation.AnimationProperty  {
            case .frame:
                animation.fromValue = animation.fromValue ?? frame
            case .opacity:
                animation.fromValue = animation.fromValue ?? opacity
            case .bounds:
                animation.fromValue = animation.fromValue ?? bounds
            case .unknown: break
            }
        }

        animations[key] = animation
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    func onWillSet(_ newOpacity: CGFloat) {
        if shouldAnimate && UIView.animationDuration > 0 && newOpacity != opacity {

            let animation = CABasicAnimation(keyPath: .opacity)
            animation.fromValue = (presentation ?? self).opacity
            animation.toValue = newOpacity
            animation.duration = CGFloat(UIView.animationDuration)
            animation.delay = CGFloat(UIView.animationDelay)
            animation.isRemovedOnCompletion = true

            animation.timer = UIView.timer

            self.add(animation, forKey: "opacity")
        }
    }

    func onWillSet(_ newFrame: CGRect) {
        if shouldAnimate && UIView.animationDuration > 0 && newFrame != frame {
            let animation = CABasicAnimation(keyPath: .frame)
            animation.fromValue = (presentation ?? self).frame
            animation.toValue = newFrame
            animation.duration = CGFloat(UIView.animationDuration)
            animation.delay = CGFloat(UIView.animationDelay)
            animation.isRemovedOnCompletion = true

            animation.timer = UIView.timer

            self.add(animation, forKey: "frame")
        }
    }

    func onWillSet(newBounds: CGRect) {
        if shouldAnimate && UIView.animationDuration > 0 && newBounds != bounds {
            let animation = CABasicAnimation(keyPath: .bounds)
            animation.fromValue = (presentation ?? self).bounds
            animation.toValue = newBounds
            animation.duration = CGFloat(UIView.animationDuration)
            animation.delay = CGFloat(UIView.animationDelay)
            animation.isRemovedOnCompletion = true

            animation.timer = UIView.timer

            self.add(animation, forKey: "bounds")
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

            case .bounds: // animate origin only, because bounds.size updates frame.size
                guard
                    let startBounds = animation.fromValue as? CGRect,
                    let endBounds = animation.toValue as? CGRect
                    else { return }

                print("animate bounds")
                presentation?.bounds.origin = (startBounds + startBounds.diff(endBounds).multiply(animation.progress)).origin


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


fileprivate extension CALayer {
    fileprivate func clone() -> CALayerWithoutAnimation {
        let clone = CALayerWithoutAnimation()

        clone.frame = self.frame
        clone.bounds = self.bounds
        clone.opacity = self.opacity
        clone.backgroundColor = self.backgroundColor
        clone.isHidden = self.isHidden
        clone.cornerRadius = self.cornerRadius
        clone.borderWidth = self.borderWidth
        clone.borderColor = self.borderColor
        clone.shadowColor = self.shadowColor
        clone.shadowRadius = self.shadowRadius
        clone.shadowOpacity = self.shadowOpacity
        //clone.texture = self.texture // macht komische sachen
        clone.sublayers = self.sublayers

        //clone.backgroundColor = UIColor.init(red: 255, green: 0, blue: 255, alpha: 0.1)

        return clone
    }
}

fileprivate class CALayerWithoutAnimation: CALayer {
    public required init() {
        super.init()
        shouldAnimate = false
        link.isPaused = true
        link.callback = nil
    }
}
