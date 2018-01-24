//
//  CALayer.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

open class CALayer {
    open weak var delegate: CALayerDelegate?

    var texture: Texture? {
        didSet {
            let newSize = texture?.size ?? .zero
            self.bounds.size = newSize
        }
    }

    internal (set) public weak var superlayer: CALayer?
    internal (set) public var sublayers: [CALayer]?

    // In iOS not public API!
    internal func insertSublayer(_ layer: CALayer, at index: Int) {
        layer.removeFromSuperlayer()
        if sublayers == nil { sublayers = [] }
        sublayers?.insert(layer, at: index) // optional in case of race conditions
        layer.superlayer = self
    }

    open func insertSublayer(_ layer: CALayer, above sibling: CALayer) {
        guard let sublayers = sublayers, let insertIndex = sublayers.index(of: sibling) else {
            preconditionFailure("self.sublayers must exist and contain sibling CALayer '\(sibling)'")
        }

        insertSublayer(layer, at: insertIndex.advanced(by: 1))
    }

    open func insertSublayer(_ layer: CALayer, below sibling: CALayer) {
        guard let sublayers = sublayers, let insertIndex = sublayers.index(of: sibling) else {
            preconditionFailure("self.sublayers must exist and contain sibling CALayer '\(sibling)'")
        }

        insertSublayer(layer, at: insertIndex)
    }

    open func addSublayer(_ layer: CALayer) {
        insertSublayer(layer, at: sublayers?.endIndex ?? 0)
    }

    open func removeFromSuperlayer() {
        if let superlayer = superlayer {
            superlayer.sublayers = superlayer.sublayers?.filter { $0 != self }
            if superlayer.sublayers?.isEmpty == true {
                superlayer.sublayers = nil
            }
        }

        superlayer = nil
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
            guard newFrame != frame else { return }
            onWillSet(keyPath: .frame)
        }
        didSet {
            if bounds.size != frame.size {
                bounds.size = frame.size
            }
        }
    }

    open var bounds: CGRect = .zero {
        willSet(newBounds) {
            guard newBounds != bounds else { return }
            onWillSet(keyPath: .bounds)
        }
        didSet {
            if frame.size != bounds.size {
                frame.size = bounds.size
            }
        }
    }

    public var opacity: Float = 1 {
        willSet(newOpacity) {
            guard newOpacity != opacity else { return }
            onWillSet(keyPath: .opacity)
        }
    }

    public var isHidden = false
    public var cornerRadius: CGFloat = 0

    // TODO: Implement these!
    public var borderWidth: CGFloat = 0
    public var borderColor: CGColor = UIColor.black.cgColor
    public var shadowPath: CGRect?
    public var shadowColor: CGColor?
    public var shadowOpacity: Float = 0
    public var shadowOffset: CGSize = .zero
    public var shadowRadius: CGFloat = 0

    public var masksToBounds = false

    public var transform: CGAffineTransform = .identity

    public required init() {}

    public required init(layer: Any) {
        guard let layer = layer as? CALayer else { fatalError() }
        frame = layer.frame
        bounds = layer.bounds
        opacity = layer.opacity
        backgroundColor = layer.backgroundColor
        isHidden = layer.isHidden
        cornerRadius = layer.cornerRadius
        borderWidth = layer.borderWidth
        borderColor = layer.borderColor
        shadowColor = layer.shadowColor
        shadowPath = layer.shadowPath
        shadowOffset = layer.shadowOffset
        shadowRadius = layer.shadowRadius
        shadowOpacity = layer.shadowOpacity
        texture = layer.texture
        sublayers = layer.sublayers
    }

    open func copy() -> Any {
        return CALayer(layer: self)
    }

    /// returns a non animating copy of the layer
    func createPresentation() -> CALayer {
        let copy = CALayer(layer: self)
        copy.disableAnimations = true
        return copy
    }

    open func action(forKey event: String) -> CAAction? {
        if let delegate = delegate {
            return delegate.action(forKey: event)
        }
        return CALayer.defaultAction(forKey: event)
    }

    // TODO: remove this function after implementing CGImage to get font texture in UIImage extension for fonts
    open func convertToUIImage() -> UIImage? {
        guard let texture = self.texture else { return nil }
        return UIImage(texture: texture)
    }

    var presentation: CALayer?
    var disableAnimations = false

    var animations = [String: CABasicAnimation]() {
        didSet { onDidSetAnimations(wasEmpty: oldValue.isEmpty) }
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

