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

        animations[key]?.stop(finished: false)
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

    func animate(at currentTime: Timer) {
        animations.forEach { key, animation in
            guard let keypath = animation.keyPath else { return }

            let animationProgress = animation.progress(at: currentTime)

            switch keypath as AnimationProperty {
            case .frame:
                guard
                    let startFrame = animation.fromValue as? CGRect,
                    let endFrame = animation.toValue as? CGRect
                    else { return }

                presentation?.frame = startFrame + (endFrame - startFrame).multiply(animationProgress)

            case .bounds: // animate origin only, because bounds.size updates frame.size
                guard
                    let startBounds = animation.fromValue as? CGRect,
                    let endBounds = animation.toValue as? CGRect
                    else { return }

                presentation?.bounds.origin = (startBounds + (endBounds - startBounds).multiply(animationProgress)).origin

            case .opacity:
                guard
                    let startOpacity = animation.fromValue as? CGFloat,
                    let endOpacity = animation.toValue as? CGFloat
                    else { return }

                let opacityDiff = (endOpacity - startOpacity) * animationProgress
                presentation?.opacity = startOpacity + opacityDiff

            case .unknown: print("unknown animation property")
            }

            if animationProgress == 1 {
                animation.stop(finished: true)
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
