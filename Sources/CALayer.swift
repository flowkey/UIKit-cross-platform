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

    open var contents: CGImage? {
        didSet {
            if let contents = self.contents {
                self.bounds.size = contents.size / contentsScale
            }
        }
    }

    /// Defaults to 1.0 but if the layer is associated with a view,
    /// the view sets this value to match the screen.
    open var contentsScale: CGFloat = 1.0

    open var contentsGravity: String = "resize" {
        didSet {
            if !CALayer.validContentsGravityOptions.contains(contentsGravity) {
                contentsGravity = "center"
            }
        }
    }

    internal (set) public weak var superlayer: CALayer?
    internal (set) public var sublayers: [CALayer]?

    open func insertSublayer(_ layer: CALayer, at index: UInt32) {
        layer.removeFromSuperlayer()
        if sublayers == nil { sublayers = [] }

        let endIndex = sublayers?.endIndex ?? 0
        sublayers?.insert(layer, at: min(Int(index), endIndex))
        layer.superlayer = self
    }

    open func insertSublayer(_ layer: CALayer, above sibling: CALayer) {
        guard let sublayers = sublayers, let insertIndex = sublayers.index(of: sibling) else {
            preconditionFailure("self.sublayers must exist and contain sibling CALayer '\(sibling)'")
        }

        insertSublayer(layer, at: UInt32(insertIndex.advanced(by: 1)))
    }

    open func insertSublayer(_ layer: CALayer, below sibling: CALayer) {
        guard let sublayers = sublayers, let insertIndex = sublayers.index(of: sibling) else {
            preconditionFailure("self.sublayers must exist and contain sibling CALayer '\(sibling)'")
        }

        insertSublayer(layer, at: UInt32(insertIndex))
    }

    open func addSublayer(_ layer: CALayer) {
        insertSublayer(layer, at: UInt32(sublayers?.endIndex ?? 0))
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

    open var backgroundColor: CGColor?

    open var frame: CGRect {
        get {
            // Create a rectangle based on `bounds.size` * `transform` at `position` offset by `anchorPoint`
            let transformedBounds = bounds.applying(transform)

            let anchorPointOffset = CGPoint(
                x: transformedBounds.width * anchorPoint.x,
                y: transformedBounds.height * anchorPoint.y
            )

            return CGRect(
                x: position.x - anchorPointOffset.x,
                y: position.y - anchorPointOffset.y,
                width: transformedBounds.width,
                height: transformedBounds.height
            )
        }
        set {
            // Position is unscaled, because `position` is in the superview's coordinate
            // system and so can be set regardless of the current transform.
            position = CGPoint(
                x: newValue.origin.x + (newValue.width * anchorPoint.x),
                y: newValue.origin.y + (newValue.height * anchorPoint.y)
            )

            guard let inverseTransform = affineTransform().inverted() else {
                assertionFailure("You tried to set the frame of a CALayer whose transform cannot be inverted. This is undefined behaviour.")
                return
            }

            // If we are shrinking the view with a transform and then setting a
            // new frame, the layer's actual `bounds` is bigger (and vice-versa):
            let nonTransformedBoundSize = newValue.applying(inverseTransform).size
            bounds.size = nonTransformedBoundSize
        }
    }

    open var position: CGPoint = .zero {
        willSet(newPosition) {
            guard newPosition != position else { return }
            onWillSet(keyPath: .position)
        }
    }

    open var zPosition: CGFloat = 0.0

    open var anchorPoint = CGPoint.defaultAnchorPoint {
        willSet(newAnchorPoint) {
            guard newAnchorPoint != anchorPoint else { return }
            onWillSet(keyPath: .anchorPoint)
        }
    }

    open var anchorPointZ: CGFloat = 0.0

    open var bounds: CGRect = .zero {
        willSet(newBounds) {
            guard newBounds != bounds else { return }
            onWillSet(keyPath: .bounds)
        }
    }

    public var opacity: Float = 1 {
        willSet(newOpacity) {
            guard newOpacity != opacity else { return }
            onWillSet(keyPath: .opacity)
        }
    }

    public var transform: CATransform3D = CATransform3DIdentity {
        willSet(newTransform) {
            if newTransform == transform { return }
            onWillSet(keyPath: .transform)
        }
    }

    final public func setAffineTransform(_ t: CGAffineTransform) {
        self.transform = CATransform3DMakeAffineTransform(t)
    }

    final public func affineTransform() -> CGAffineTransform {
        return CATransform3DGetAffineTransform(transform)
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

    public var mask: CALayer?
    public var masksToBounds = false

    public required init() {}

    public required init(layer: Any) {
        guard let layer = layer as? CALayer else { fatalError() }
        bounds = layer.bounds
        transform = layer.transform
        position = layer.position
        anchorPoint = layer.anchorPoint
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
        mask = layer.mask
        contents = layer.contents // XXX: we should make a copy here
        contentsScale = layer.contentsScale
        superlayer = layer.superlayer
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
        guard let contents = self.contents else { return nil }
        return UIImage(cgImage: contents, scale: contentsScale)
    }

    var presentation: CALayer?
    var disableAnimations = false

    var animations = [String: CABasicAnimation]() {
        didSet { onDidSetAnimations(wasEmpty: oldValue.isEmpty) }
    }
}

extension CGPoint {
    static let defaultAnchorPoint = CGPoint(x: 0.5, y: 0.5)
}

extension CALayer: CustomStringConvertible {
    public var description: String {
        let anchorPointDescription = (anchorPoint != .defaultAnchorPoint) ? "\n- anchorPoint: \(anchorPoint)" : ""
        let colourDescription = (backgroundColor != nil) ? "\n- backgroundColor: \(backgroundColor!)" : ""
        return """
            \(type(of: self))
                - frame: \(frame),
                - bounds: \(bounds),
                - position: \(position)\(anchorPointDescription)\(colourDescription)
            """
    }
}

extension CALayer: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (lhs: CALayer, rhs: CALayer) -> Bool {
        return lhs === rhs
    }
}
