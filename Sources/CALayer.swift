//
//  CALayer.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

open class CALayer {
    var texture: Texture? {
        didSet {
            let newSize = texture?.size ?? .zero
            self.bounds.size = newSize
        }
    }

    public var superlayer: CALayer?
    internal (set) public var sublayers: [CALayer] = []
    public func addSublayer(_ layer: CALayer) {
        layer.removeFromSuperlayer()
        sublayers.append(layer)
    }

    public func removeFromSuperlayer() {
        if let superlayer = superlayer {
            superlayer.sublayers = superlayer.sublayers.filter { $0 != self }
        }
    }

    public var backgroundColor: CGColor?

    public var position: CGPoint {
        // Note: this should be based on the CALayer's anchor point: (midX, midY) is just the default (0.5, 0.5) point:
        get { return CGPoint(x: frame.midX, y: frame.midY) }
        set { frame.midX = newValue.x; frame.midY = newValue.y }
    }

    /// Frame is what is actually rendered, regardless of the texture size (we don't do any stretching etc)
    open var frame: CGRect = .zero {
        willSet (newFrame) {

            if UIView.animationDuration > 0 {
                if newFrame != frame {

                    let animation = CABasicAnimation(keyPath: "frame")
                    animation.fromValue = frame
                    animation.toValue = newFrame
                    animation.duration = CGFloat(UIView.animationDuration)

                    self.add(animation, forKey: animation.keyPath!, addToAnimations: true)
                }
            }
        }
        didSet {
            if bounds.size != frame.size {
                bounds.size = frame.size
            }
        }
    }

    open var bounds: CGRect = .zero {
        didSet {
            if frame.size != bounds.size {
                frame.size = bounds.size
            }
        }
    }

    public var isHidden = false
    public var opacity: CGFloat = 1 {
        willSet(newOpacity) {
            if UIView.animationDuration > 0 {
                if newOpacity != opacity {
                    ensurePresenTationLayerExists()

                    let animation = CABasicAnimation(keyPath: "opacity")
                    animation.fromValue = opacity
                    animation.toValue = newOpacity
                    animation.duration = CGFloat(UIView.animationDuration)
                    self.add(animation, forKey: animation.keyPath!, addToAnimations: true)
                }
            }
        }
    }

    public var cornerRadius: CGFloat = 0

    // TODO: Implement these!
    public var borderWidth: CGFloat = 0
    public var borderColor: CGColor = UIColor.black.cgColor

    public var shadowPath: CGRect?
    public var shadowColor: CGColor?
    public var shadowOpacity: CGFloat = 0
    public var shadowOffset: CGSize = .zero
    public var shadowRadius: CGFloat = 0


    public init() {
        link.callback = animate
    }

    // Match UIKit by providing this initializer to override
    public init(layer: Any) {}

    open func action(forKey event: String) -> CAAction? {
        return nil // TODO: Return the default CABasicAnimation of 0.25 seconds of all animatable properties
    }
    
    // TODO: remove this function after implementing CGImage to get font texture in UIImage extension for fonts
    open func convertToUIImage() -> UIImage? {
        guard let texture = self.texture else { return nil }
        return UIImage(texture: texture)
    }

    private var presentationLayer: CALayer?
    private let link = DisplayLink()

    private var animations = [String: CABasicAnimation]() {
        didSet(oldAnimations) {
            link.isPaused = animations.count == 0

            guard animations.count != animations.count else { return }

            if animations.count != 0 {
                ensurePresenTationLayerExists()
            } else {
                presentationLayer = nil
            }
        }
    }
}

extension CALayer: Equatable {
    public static func == (lhs: CALayer, rhs: CALayer) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

extension CALayer { // animations
    open func add(_ animation: CABasicAnimation, forKey key: String, addToAnimations: Bool? = false) {
        if addToAnimations! {
            animations[key] = animation
        }
    }

    open func removeAnimation(forKey key: String) {
        animations.removeValue(forKey: key)
    }

    func presentation() -> CALayer? {
        return presentationLayer
    }

    private func ensurePresenTationLayerExists() {
        guard presentationLayer == nil else { return }

        // TODO: is there a nicer way for a copy of self?
        presentationLayer = CALayer()
        presentationLayer?.frame = self.frame
        presentationLayer?.opacity = self.opacity
    }

    private func animate() {
        animations.forEach { _, animation in
            if (animation.duration <= 0) { return }

            switch animation.keyPath {
            case "frame"?:
                let endFrame = animation.toValue as! CGRect
                let startFrame = animation.fromValue as! CGRect

                let xDiff = (endFrame.origin.x - startFrame.origin.x) * animation.multiplier
                let yDiff = (endFrame.origin.y - startFrame.origin.y) * animation.multiplier

                let widthDiff = (endFrame.width - startFrame.width) * animation.multiplier
                let heightDiff = (endFrame.height - startFrame.height) * animation.multiplier


                presentation()?.frame.origin = CGPoint(x: startFrame.origin.x + xDiff, y: startFrame.origin.y + yDiff)
                presentation()?.frame.size = CGSize(width: startFrame.width + widthDiff, height: startFrame.height + heightDiff)

            case "opacity"?:
                let endOpacity = animation.toValue as! CGFloat
                let startOpacity = animation.fromValue as! CGFloat

                let opacityDiff = (endOpacity - startOpacity) * animation.multiplier
                presentation()?.opacity = startOpacity + opacityDiff

            default: break
            }

            if animation.multiplier == 1 && animation.isRemovedOnCompletion {
                removeAnimation(forKey: animation.keyPath!)
            }
        }
    }
}
