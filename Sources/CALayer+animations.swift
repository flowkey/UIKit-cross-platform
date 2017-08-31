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
        copy.timer = Timer()

        if copy.fromValue == nil, let keyPath = copy.keyPath {
            let layer = presentation ?? self
            copy.fromValue = layer.value(forKeyPath: keyPath)
        }

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
        if let animation = action(forKey: .opacity), !disableAnimations {
            add(animation, forKey: "opacity")
        }
    }

    func onWillSet(newFrame: CGRect) {
        if let animation = action(forKey: .frame), !disableAnimations {
            add(animation, forKey: "frame")
        }
    }

    func onWillSet(newBounds: CGRect) {
        if let animation = action(forKey: .bounds), !disableAnimations {
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

extension CALayer {
    func action(forKey event: AnimationProperty) -> CABasicAnimation? {
        if let delegate = delegate {
            return delegate.action(forKey: event)
        }
        //return CALayer.defaultAction(forKey: event)
        return nil
    }

    static func defaultAction(forKey event: AnimationProperty) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: event)
        animation.duration = 0.25
        return animation
    }
}

extension CALayer {
    func value(forKeyPath: AnimationProperty) -> AnimatableProperty? {
        switch forKeyPath as AnimationProperty  {
        case .frame: return frame
        case .opacity: return opacity
        case .bounds: return bounds
        case .unknown: return nil
        }
    }
}
