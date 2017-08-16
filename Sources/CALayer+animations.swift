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
        animations.append((key, animation))
    }

    func add(_ animation: CABasicAnimation) {
        ensureFromValueIsDefined(animation)

        UIView.currentAnimationGroup?.queuedAnimations += 1
        animations.append((nil, animation))
    }

    open func removeAnimation(forKey key: String) {
        animations = animations.filter { $0.key == key }
    }

    open func removeAndCallCompletion(animation: CABasicAnimation) {
        animation.animationGroup?.animationDidStop(finished: animation.isComplete)
        animations = animations.filter { $0.animation != animation }
    }

    func onWillSet(_ newOpacity: CGFloat) {
        if let prototype = UIView.animationPrototype, shouldAnimate {
            let animation = prototype.createAnimation(keyPath: .opacity)
            animation.fromValue = (presentation ?? self).opacity
            animation.toValue = newOpacity

            add(animation)
        }
    }

    func onWillSet(_ newFrame: CGRect) {
        if let prototype = UIView.animationPrototype, shouldAnimate {
            let animation = prototype.createAnimation(keyPath: .frame)
            animation.fromValue = (presentation ?? self).frame
            animation.toValue = newFrame

            add(animation)
        }
    }

    func onWillSet(newBounds: CGRect) {
        if let prototype = UIView.animationPrototype, shouldAnimate {
            let animation =  prototype.createAnimation(keyPath: .bounds)
            animation.fromValue = (presentation ?? self).bounds
            animation.toValue = newBounds

            add(animation)
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
        guard let keyPath = animation.keyPath, let presentation = presentation else { return }

        switch keyPath as AnimationProperty {
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
        var propertiesDidAnimate = PropertiesDidAnimate()

        animations.forEach { (_, animation) in
            guard let keyPath = animation.keyPath, animation.updateProgress(to: currentTime) > 0 else { return }

            if
                propertiesDidAnimate[keyPath],
                let firstAnimationForKeyPath = animations.getFirstElement(for: keyPath)
            {
                removeAndCallCompletion(animation: firstAnimationForKeyPath)
            }

            updatePresentation(for: animation, at: currentTime)
            propertiesDidAnimate[keyPath] = true

            if animation.isComplete && animation.isRemovedOnCompletion {
                removeAndCallCompletion(animation: animation)
            }
        }
    }
}

fileprivate struct PropertiesDidAnimate {
    var frame = false
    var bounds = false
    var opacity = false

    subscript(animationProperty: AnimationProperty) -> Bool {
        get {
            switch animationProperty {
            case .bounds: return self.bounds
            case .frame: return self.frame
            case .opacity: return self.opacity
            case .unknown: return false // throw error?
            }
        }
        set {
            switch animationProperty {
            case .bounds: self.bounds = newValue
            case .frame: self.frame  = newValue
            case .opacity: self.opacity = newValue
            case .unknown: break
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

extension Array where Iterator.Element == (key: String?, animation: CABasicAnimation) {
    func getFirstElement(for keyPath: AnimationProperty) -> CABasicAnimation? {
         return self.filter({ $0.animation.keyPath == keyPath }).first?.animation
    }
}
