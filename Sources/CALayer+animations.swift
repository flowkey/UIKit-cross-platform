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

    open func removeAllAnimations() {
        animations = []
    }

    func onWillSet(newOpacity: Float) {
        if !self.disableAnimations, UIView.shouldAnimate,
            let prototype = UIView.currentAnimationPrototype {
            let animation = prototype.createAnimation(
                keyPath: .opacity,
                fromValue: getCurrentState(for: prototype.options).opacity
            )
            add(animation)
        }
    }

    func onWillSet(newFrame: CGRect) {
        if !self.disableAnimations, UIView.shouldAnimate,
            let prototype = UIView.currentAnimationPrototype {
            let animation = prototype.createAnimation(
                keyPath: .frame,
                fromValue: getCurrentState(for: prototype.options).frame
            )
            add(animation)
        }
    }

    func onWillSet(newBounds: CGRect) {
        if !self.disableAnimations,
            let prototype = UIView.currentAnimationPrototype {
            let animation =  prototype.createAnimation(
                keyPath: .bounds,
                fromValue: getCurrentState(for: prototype.options).bounds
            )
            add(animation)
        }
    }

    func onDidSetAnimations(wasEmpty: Bool) {
        if wasEmpty && !animations.isEmpty {
            UIView.layersWithAnimations.insert(self)
        } else if animations.isEmpty && !wasEmpty {
            UIView.layersWithAnimations.remove(self)
        }
    }

    func update(_ presentation: CALayer, for animation: CABasicAnimation, at currentTime: Timer) {

        guard let keyPath = animation.keyPath else { return }

        switch keyPath {
        case .frame:
            guard let startFrame = animation.fromValue as? CGRect else { break }
            let endFrame = animation.toValue as? CGRect ?? self.frame
            presentation.frame = startFrame + (endFrame - startFrame) * animation.progress

        case .bounds:
            guard let startBounds = animation.fromValue as? CGRect else { break }
            let endBounds = animation.toValue as? CGRect ?? self.bounds
            // animate origin only, because setting bounds.size updates frame.size
            presentation.bounds.origin = (startBounds + (endBounds - startBounds) * animation.progress).origin

        case .opacity:
            guard let startOpacity = animation.fromValue as? Float else { break }
            let endOpacity = animation.toValue as? Float ?? self.opacity
            presentation.opacity = startOpacity + ((endOpacity - startOpacity)) * Float(animation.progress)

        case .unknown:
            print("unknown animation property")
            break
        }

    }

    func animate(at currentTime: Timer) {
        // reset state on each animationLoop
        var propertiesDidAnimate = AnimationLoopState()

        let presentation = self.copy()
        presentation.disableAnimations = true

        animations.forEach { (_, animation) in
            animation.updateProgress(to: currentTime)
            guard let keyPath = animation.keyPath, animation.progress > 0 else { return }

            if // if a property will animate twice during one animationLoop, cancel first animation
                propertiesDidAnimate[keyPath],
                let firstAnimationForKeyPath = animations.getFirstElement(for: keyPath)
            {
                removeAnimationAndNotifyGroup(animation: firstAnimationForKeyPath)
            }

            update(presentation, for: animation, at: currentTime)
            propertiesDidAnimate[keyPath] = true

            if animation.isComplete && animation.isRemovedOnCompletion {
                removeAnimationAndNotifyGroup(animation: animation)
            }
        }

        self.presentation = animations.isEmpty ? nil : presentation
    }
}

fileprivate extension CABasicAnimation {
    var isUIViewAnimation: Bool {
        return animationGroup != nil
    }
}

fileprivate extension CALayer {
    private func add(_ animation: CABasicAnimation) {
        animation.animationGroup?.queuedAnimations += 1
        animations.append((nil, animation))
    }

    private func removeAnimationAndNotifyGroup(animation: CABasicAnimation) {
        animation.animationGroup?.animationDidStop(finished: animation.isComplete)
        animations = animations.filter { $0.animation != animation }
    }

    private func getCurrentState(for options: UIViewAnimationOptions) -> CALayer {
        return options.contains(.beginFromCurrentState) ? (presentation ?? self) : self
    }

    private func ensureFromValueIsDefined(_ animation: CABasicAnimation) {
        if animation.fromValue == nil, let keypath = animation.keyPath {
            switch keypath as AnimationProperty  {
            case .frame:
                animation.fromValue = presentation?.frame ?? frame
            case .opacity:
                animation.fromValue = presentation?.opacity ?? opacity
            case .bounds:
                animation.fromValue = presentation?.bounds ?? bounds
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
