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

    func onDidSetAnimations(wasEmpty: Bool) {
        if wasEmpty && !animations.isEmpty {
            presentation = self.copy()
            UIView.layersWithAnimations.insert(self)
        } else if animations.isEmpty && !wasEmpty {
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

            presentation.bounds = (startBounds + (endBounds - startBounds) * animation.progress)

        case .opacity:
            guard
                let startOpacity = animation.fromValue as? Float,
                let endOpacity = animation.toValue as? Float
                else { return }

            presentation.opacity = startOpacity + ((endOpacity - startOpacity)) * Float(animation.progress)

        case .unknown: print("unknown animation property")
        }

    }

    func animate(at currentTime: Timer) {
        // reset state on each animationLoop
        var propertiesDidAnimate = AnimationLoopState()

        animations.forEach { (_, animation) in
            animation.updateProgress(to: currentTime)
            guard let keyPath = animation.keyPath, animation.progress > 0 else { return }

            if // if a property will animate twice during one animationLoop, cancel first animation
                propertiesDidAnimate[keyPath],
                let firstAnimationForKeyPath = animations.getFirstElement(for: keyPath)
            {
                removeAnimationAndNotifyGroup(animation: firstAnimationForKeyPath)
            }

            updatePresentation(for: animation, at: currentTime)
            propertiesDidAnimate[keyPath] = true

            if animation.isComplete && animation.isRemovedOnCompletion {
                removeAnimationAndNotifyGroup(animation: animation)
            }
        }
    }
}

extension CALayer {
    func ensureFromValueIsDefined(_ animation: CABasicAnimation) {
        if animation.fromValue == nil, let keypath = animation.keyPath {
            switch keypath as AnimationProperty  {
            case .frame:
                animation.fromValue = animation.fromValue ?? presentation?.frame ?? frame
            case .opacity:
                animation.fromValue = animation.fromValue ?? presentation?.opacity ?? opacity
            case .bounds:
                animation.fromValue = animation.fromValue ?? presentation?.bounds ?? bounds
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
