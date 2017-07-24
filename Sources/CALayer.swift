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
                copySelfToPresentationLayer()

                if newFrame.origin != frame.origin {
                    let animation = CABasicAnimation(keyPath: "position")
                    animation.fromValue = frame.origin
                    animation.toValue = newFrame.origin
                    self.add(animation, forKey: "position")

                } else if newFrame.size != frame.size {
                    let animation = CABasicAnimation(keyPath: "size")
                    animation.fromValue = frame.size
                    animation.toValue = newFrame.size
                    self.add(animation, forKey: "size")
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
    public var opacity: CGFloat = 1
    public var cornerRadius: CGFloat = 0

    // TODO: Implement these!
    public var borderWidth: CGFloat = 0
    public var borderColor: CGColor = UIColor.black.cgColor

    public var shadowPath: CGRect?
    public var shadowColor: CGColor?
    public var shadowOpacity: CGFloat = 0
    public var shadowOffset: CGSize = .zero
    public var shadowRadius: CGFloat = 0


    public init() {}

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


    private var animations: [CABasicAnimation] = []
    private var presentationLayer: CALayer?

    open func copySelfToPresentationLayer() {
        // TODO: is there a nicer way for a copy of self?
        presentationLayer = CALayer()
        presentationLayer?.frame = self.frame
        presentationLayer?.opacity = self.opacity
    }

    open func presentation() -> CALayer? {
        return presentationLayer
    }

    func updatePresentation(frame: CGRect) {
        presentationLayer?.frame = frame
    }

    open func add(_ animation: CABasicAnimation, forKey key: String) {
        animation.keyPath = key
        animations.append(animation)
    }

    open func removeAnimation(forKey key: String) {
        animations = animations.filter { $0.keyPath != key }
    }

}

extension CALayer: Equatable {
    public static func == (lhs: CALayer, rhs: CALayer) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
