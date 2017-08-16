//
//  CALayer+animations.swift
//  UIKit
//
//  Created by Michael Knoch on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {
    open func add(_ animation: CABasicAnimation, forKey key: String) {
        ensureFromValueIsDefined(animation)

        if let currentAnimationGroup = UIView.currentAnimationGroup {
            currentAnimationGroup.queuedAnimations += 1
        }

        animations[key]?.animationGroup?.animationDidStop(finished: false)
        animations[key] = animation
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    func onWillSet(_ newOpacity: CGFloat) {
        if let prototype = UIView.animationPrototype, shouldAnimate {
            let animation = prototype.createAnimation(keyPath: .opacity)
            animation.fromValue = (presentation ?? self).opacity
            animation.toValue = newOpacity

            add(animation, forKey: "opacity")
        }
    }

    func onWillSet(_ newFrame: CGRect) {
        if let prototype = UIView.animationPrototype, shouldAnimate {
            let animation = prototype.createAnimation(keyPath: .frame)
            animation.fromValue = (presentation ?? self).frame
            animation.toValue = newFrame

            add(animation, forKey: "frame")
        }
    }

    func onWillSet(newBounds: CGRect) {
        if let prototype = UIView.animationPrototype, shouldAnimate {
            let animation =  prototype.createAnimation(keyPath: .bounds)
            animation.fromValue = (presentation ?? self).bounds
            animation.toValue = newBounds

            add(animation, forKey: "bounds")
        }
    }

    func onDidSetAnimations() {
        if animations.count > 0 {
            presentation = presentation ?? self.clone()
            UIView.layersWithAnimations.insert(self)
        } else {
            presentation = nil
            UIView.layersWithAnimations.remove(self)
        }
    }

    func updatePresentation(for animation: CABasicAnimation, at currentTime: Timer) {
        guard let keypath = animation.keyPath, let presentation = presentation else { return }

        switch keypath as AnimationProperty {
        case .frame:
            guard
                let startFrame = animation.fromValue as? CGRect,
                let endFrame = animation.toValue as? CGRect
                else { return }

            presentation.frame = startFrame + (endFrame - startFrame) * animation.progress

        case .bounds:
            guard
                let startBounds = animation.fromValue as? CGRect,
                let endBounds = animation.toValue as? CGRect
                else { return }

            // animate origin only, because setting bounds.size updates frame.size
            presentation.bounds.origin = (startBounds + (endBounds - startBounds) * animation.progress).origin

        case .opacity:
            guard
                let startOpacity = animation.fromValue as? CGFloat,
                let endOpacity = animation.toValue as? CGFloat
                else { return }

            presentation.opacity = startOpacity + ((endOpacity - startOpacity) * animation.progress)

        case .unknown: print("unknown animation property")
        }
    }

    func animate(at currentTime: Timer) {
        animations.forEach { key, animation in
            if animation.updateProgress(to: currentTime) == 0 { return }

            updatePresentation(for: animation, at: currentTime)

            if animation.progress == 1 {
                animation.animationGroup?.animationDidStop(finished: true)
                if animation.isRemovedOnCompletion {
                    removeAnimation(forKey: key)
                }
            }
        }
    }
}

fileprivate extension CALayer {
    func clone() -> CALayerWithoutAnimation {
        return CALayerWithoutAnimation(layer: self)
    }

    private func ensureFromValueIsDefined(_ animation: CABasicAnimation) {
        if animation.fromValue == nil, let keypath = animation.keyPath {
            switch keypath as AnimationProperty  {
            case .frame:
                animation.fromValue = animation.fromValue ?? frame
            case .opacity:
                animation.fromValue = animation.fromValue ?? opacity
            case .bounds:
                animation.fromValue = animation.fromValue ?? bounds
            case .unknown: break
            }
        }
    }
}

fileprivate class CALayerWithoutAnimation: CALayer {
    convenience init(layer: CALayer) {
        self.init()

        shouldAnimate = false

        frame = layer.frame
        bounds = layer.bounds
        opacity = layer.opacity
        backgroundColor = layer.backgroundColor
        isHidden = layer.isHidden
        cornerRadius = layer.cornerRadius
        borderWidth = layer.borderWidth
        borderColor = layer.borderColor
        shadowColor = layer.shadowColor
        shadowRadius = layer.shadowRadius
        shadowOpacity = layer.shadowOpacity
        //clone.texture = self.texture // macht komische sachen
        sublayers = layer.sublayers
    }
}
