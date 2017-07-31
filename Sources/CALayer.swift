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
            onWillSet(newFrame)
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
            self.onWillSet(newOpacity)
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


    public required init() {
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

    var presentation: CALayer?
    private let link = DisplayLink()

    var animations = [String: CABasicAnimation]() {
        didSet(oldAnimations) {
            guard animations.count != oldAnimations.count else { return }

            if animations.count != 0 {
                ensurePresenTationExists()
            } else {
                presentation = nil
            }

            link.isPaused = animations.count == 0
        }
    }
}

extension CALayer: Equatable {
    public static func == (lhs: CALayer, rhs: CALayer) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

