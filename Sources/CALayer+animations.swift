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

        let copy = CABasicAnimation(from: animation)
        copy.animationGroup?.queuedAnimations += 1
        copy.timer = Timer()

        animations[key]?.animationGroup?.animationDidStop(finished: false)
        animations[key] = copy
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    open func removeAllAnimations() {
        animations = [:]
    }

    func onWillSet(newOpacity: Float) {
        if !self.disableAnimations,
            let prototype = UIView.currentAnimationPrototype {
            let animation = prototype.createAnimation(
                keyPath: .opacity,
                fromValue: getCurrentState(for: prototype.options).opacity
            )
            add(animation, forKey: "opacity")
        }
    }

    func onWillSet(newFrame: CGRect) {
        if !self.disableAnimations,
            let prototype = UIView.currentAnimationPrototype {
            let animation = prototype.createAnimation(
                keyPath: .frame,
                fromValue: getCurrentState(for: prototype.options).frame
            )
            add(animation, forKey: "frame")
        }
    }

    func onWillSet(newBounds: CGRect) {
        if !self.disableAnimations,
            let prototype = UIView.currentAnimationPrototype {
            let animation =  prototype.createAnimation(
                keyPath: .bounds,
                fromValue: getCurrentState(for: prototype.options).bounds
            )
            add(animation, forKey: "bounds")
        }
    }

    func onDidSetAnimations(wasEmpty: Bool) {
        if wasEmpty && !animations.isEmpty {
            UIView.layersWithAnimations.insert(self)

            self.presentation = self.copy(disableAnimations: true)

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
        let presentation = self.copy(disableAnimations: true)

        animations.forEach { (key, animation) in
            animation.updateProgress(to: currentTime)

            update(presentation, for: animation, at: currentTime)

            if animation.isComplete && animation.isRemovedOnCompletion {
                animation.animationGroup?.animationDidStop(finished: true)
                removeAnimation(forKey: key)
            }
        }

        self.presentation = animations.isEmpty ? nil : presentation
    }
}

fileprivate extension CALayer {
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
