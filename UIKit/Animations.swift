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

        animations[key] = animation
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    func onWillSet(_ newOpacity: CGFloat) {
        if let prototype = UIView.animationPrototype, shouldAnimate, newOpacity != opacity {
            let animation = prototype.createAnimation(keyPath: .opacity)
            animation.fromValue = (presentation ?? self).opacity
            animation.toValue = newOpacity

            self.add(animation, forKey: "opacity")
        }
    }

    func onWillSet(_ newFrame: CGRect) {
        if let prototype = UIView.animationPrototype, shouldAnimate, newFrame != frame {
            let animation = prototype.createAnimation(keyPath: .frame)
            animation.fromValue = (presentation ?? self).frame
            animation.toValue = newFrame

            self.add(animation, forKey: "frame")
        }
    }

    func onWillSet(newBounds: CGRect) {
        if let prototype = UIView.animationPrototype, shouldAnimate, newBounds != bounds {
            let animation =  prototype.createAnimation(keyPath: .bounds)
            animation.fromValue = (presentation ?? self).bounds
            animation.toValue = newBounds

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

            switch keypath as AnimationProperty {
            case .frame:
                guard
                    let startFrame = animation.fromValue as? CGRect,
                    let endFrame = animation.toValue as? CGRect
                    else { return }

                presentation?.frame = startFrame + (endFrame - startFrame).multiply(animation.progress)

            case .bounds: // animate origin only, because bounds.size updates frame.size
                guard
                    let startBounds = animation.fromValue as? CGRect,
                    let endBounds = animation.toValue as? CGRect
                    else { return }

                presentation?.bounds.origin = (startBounds + (endBounds - startBounds).multiply(animation.progress)).origin

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

fileprivate extension CALayer {
    func clone() -> CALayerWithoutAnimation {
        return CALayerWithoutAnimation(layer: self)
    }
}

fileprivate class CALayerWithoutAnimation: CALayer {
    convenience init(layer: CALayer) {
        self.init()

        shouldAnimate = false
        link.isPaused = true
        link.callback = nil

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
