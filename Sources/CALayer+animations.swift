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
        animation.timer = Timer()

        let copy = CABasicAnimation(from: animation)
        animations.append((key, copy))
    }

    open func removeAnimation(forKey key: String) {
        animations = animations.filter { $0.key == key }
    }

    private func add(_ animation: CABasicAnimation) {
        ensureFromValueIsDefined(animation)

        UIView.currentAnimationGroup?.queuedAnimations += 1
        animations.append((nil, animation))
    }

    private func removeAnimationAndRunCompletion(animation: CABasicAnimation) {
        animation.animationGroup?.animationDidStop(finished: animation.isComplete)
        animations = animations.filter { $0.animation != animation }
    }

    func onWillSet(_ newOpacity: CGFloat) {
        if let prototype = UIView.currentAnimationPrototype, shouldAnimate {
            let animation = prototype.createAnimation(keyPath: .opacity)
            animation.fromValue = (presentation ?? self).opacity
            animation.toValue = newOpacity

            add(animation)
        }
    }

    func onWillSet(_ newFrame: CGRect) {
        if let prototype = UIView.currentAnimationPrototype, shouldAnimate {
            let animation = prototype.createAnimation(keyPath: .frame)
            animation.fromValue = (presentation ?? self).frame
            animation.toValue = newFrame

            add(animation)
        }
    }

    func onWillSet(newBounds: CGRect) {
        if let prototype = UIView.currentAnimationPrototype, shouldAnimate {
            let animation =  prototype.createAnimation(keyPath: .bounds)
            animation.fromValue = (presentation ?? self).bounds
            animation.toValue = newBounds

            add(animation)
        }
    }

    func onDidSetAnimations() {
        if animations.count > 0 {
            presentation = presentation ?? self.createNonAnimatingCopy()
            UIView.layersWithAnimations.insert(self)
        } else {
            presentation = nil
            UIView.layersWithAnimations.remove(self)
        }
    }

    func updatePresentation(for animation: CABasicAnimation, at currentTime: Timer) {
        guard let keyPath = animation.keyPath, let presentation = presentation else { return }

        switch keyPath {
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
        // reset state on each animationLoop
        var propertiesDidAnimate = AnimationLoopState()

        animations.forEach { (_, animation) in
            guard let keyPath = animation.keyPath, animation.updateProgress(to: currentTime) > 0 else { return }

            if // if a property will animate twice during one animationLoop, cancel first animation
                propertiesDidAnimate[keyPath],
                let firstAnimationForKeyPath = animations.getFirstElement(for: keyPath)
            {
                removeAnimationAndRunCompletion(animation: firstAnimationForKeyPath)
            }

            updatePresentation(for: animation, at: currentTime)
            propertiesDidAnimate[keyPath] = true

            if animation.isComplete && animation.isRemovedOnCompletion {
                removeAnimationAndRunCompletion(animation: animation)
            }
        }
    }
}

fileprivate extension CALayer {
    func createNonAnimatingCopy() -> CALayer {
        return CALayer(layer: self, shouldAnimate: false)
    }

    convenience init(layer: CALayer, shouldAnimate: Bool) {
        self.init()
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

        self.shouldAnimate = shouldAnimate
    }
}

fileprivate extension CALayer {
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

fileprivate extension Array where Iterator.Element == (key: String?, animation: CABasicAnimation) {
    func getFirstElement(for keyPath: AnimationProperty) -> CABasicAnimation? {
         return self.filter({ $0.animation.keyPath == keyPath }).first?.animation
    }
}
