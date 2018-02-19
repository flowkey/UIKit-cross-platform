//
//  CALayer+animations.swift
//  UIKit
//
//  Created by Michael Knoch on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

extension CALayer {
    open func add(_ animation: CABasicAnimation, forKey key: String) {
        let copy = CABasicAnimation(from: animation)
        copy.animationGroup?.queuedAnimations += 1
        copy.creationTime = Timer()

        // animation.fromValue is optional, set it to currently visible state if nil
        if copy.fromValue == nil, let keyPath = copy.keyPath {
            copy.fromValue = (presentation ?? self).value(forKeyPath: keyPath)
        }

        animations[key]?.animationGroup?.animationDidStop(finished: false)
        animations[key] = copy
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    open func removeAllAnimations() {
        animations.removeAll()
    }

    func onWillSet(keyPath: AnimationKeyPath) {
        if let animation = action(forKey: keyPath.rawValue) as? CABasicAnimation,
            !disableAnimations,
            !CATransaction.disableActions
        {
            add(animation, forKey: keyPath.rawValue)
        }
    }

    func onDidSetAnimations(wasEmpty: Bool) {
        if !animations.isEmpty && wasEmpty {
            UIView.layersWithAnimations.insert(self)
            presentation = createPresentation()

        } else if animations.isEmpty && !wasEmpty {
            presentation = nil
            UIView.layersWithAnimations.remove(self)
        }
    }
}

extension CALayer {
    func animate(at currentTime: Timer) {
        let presentation = createPresentation()

        animations.forEach { (key, animation) in
            let animationProgress = animation.progress(for: currentTime)

            update(presentation, for: animation, with: animationProgress)

            if animationProgress == 1 && animation.isRemovedOnCompletion {
                animation.animationGroup?.animationDidStop(finished: true)
                removeAnimation(forKey: key)
            }
        }

        self.presentation = animations.isEmpty ? nil : presentation
    }

    private func update(_ presentation: CALayer, for animation: CABasicAnimation, with progress: CGFloat) {
        guard let keyPath = animation.keyPath else { return }

        switch keyPath {
        case .position:
            guard let start = animation.fromValue as? CGPoint else { return }
            let end = animation.toValue as? CGPoint ?? self.position
            presentation.position = start + (end - start) * progress

        case .anchorPoint:
            guard let start = animation.fromValue as? CGPoint else { return }
            let end = animation.toValue as? CGPoint ?? self.anchorPoint
            presentation.anchorPoint = start + (end - start) * progress

        case .bounds:
            guard let startBounds = animation.fromValue as? CGRect else { return }
            let endBounds = animation.toValue as? CGRect ?? self.bounds
            presentation.bounds = (startBounds + (endBounds - startBounds) * progress)

        case .opacity:
            guard let startOpacity = animation.fromValue as? Float else { return }
            let endOpacity = animation.toValue as? Float ?? self.opacity
            presentation.opacity = startOpacity + ((endOpacity - startOpacity)) * Float(progress)

        case .transform:
            guard let startTransform = animation.fromValue as? CATransform3D else { return }
            let endTransform = animation.toValue as? CATransform3D ?? self.transform
            presentation.transform = startTransform + ((endTransform - startTransform) * Float(progress))

        case .unknown: break
        }
    }
}

extension CALayer {
    static let defaultAnimationDuration: CGFloat = 0.25

    static func defaultAction(forKey event: String) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: AnimationKeyPath(stringLiteral: event))
        animation.duration = defaultAnimationDuration
        return animation
    }
}

extension CALayer {
    func value(forKeyPath: AnimationKeyPath) -> AnimatableProperty? {
        switch forKeyPath as AnimationKeyPath  {
        case .opacity: return opacity
        case .bounds: return bounds
        case .transform: return transform
        case .position: return position
        case .anchorPoint: return anchorPoint
        case .unknown: return nil
        }
    }
}
