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

    public var backgroundColor: CGColor? {
        didSet { presentation?.backgroundColor = backgroundColor }
    }

    public var position: CGPoint {
        // Note: this should be based on the CALayer's anchor point: (midX, midY) is just the default (0.5, 0.5) point:
        get { return CGPoint(x: frame.midX, y: frame.midY) }
        set { frame.midX = newValue.x; frame.midY = newValue.y }
    }

    /// Frame is what is actually rendered, regardless of the texture size (we don't do any stretching etc)
    open var frame: CGRect = .zero {
        willSet (newFrame) {
            onWillSet(newFrame: newFrame)
        }
        didSet {
            if bounds.size != frame.size {
                bounds.size = frame.size
            }
        }
    }

    open var bounds: CGRect = .zero {
        willSet(newBounds) {
            onWillSet(newBounds: newBounds)
        }
        didSet {
            if frame.size != bounds.size {
                frame.size = bounds.size
            }
        }
    }

    public var isHidden = false {
        didSet { presentation?.isHidden = isHidden }
    }
    public var opacity: Float = 1 {
        willSet(newOpacity) {
            onWillSet(newOpacity: newOpacity)
        }
    }

    public var cornerRadius: CGFloat = 0 {
        didSet { presentation?.cornerRadius = cornerRadius }
    }

    // TODO: Implement these!
    public var borderWidth: CGFloat = 0 {
        didSet { presentation?.borderWidth = borderWidth }
    }
    public var borderColor: CGColor = UIColor.black.cgColor {
        didSet { presentation?.borderColor = borderColor }
    }

    public var shadowPath: CGRect? {
        didSet { presentation?.shadowPath = shadowPath }
    }
    public var shadowColor: CGColor?{
        didSet { presentation?.shadowColor = shadowColor }
    }
    public var shadowOpacity: Float = 0{
        didSet { presentation?.shadowOpacity = shadowOpacity }
    }
    public var shadowOffset: CGSize = .zero {
        didSet { presentation?.shadowOffset = shadowOffset }
    }
    public var shadowRadius: CGFloat = 0 {
        didSet { presentation?.shadowRadius = shadowRadius }
    }


    public required init() {}

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

    var presentation: CALayer?
    var disableAnimations = false

    var animations = [(key: String?, animation: CABasicAnimation)]() {
        didSet {
            onDidSetAnimations(wasEmpty: oldValue.isEmpty)
        }
    }
}

extension CALayer: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (lhs: CALayer, rhs: CALayer) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

