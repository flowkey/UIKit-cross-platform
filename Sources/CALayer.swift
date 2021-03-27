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
        didSet { CALayer.layerTreeIsDirty = true }
    }

    /// Defaults to 1.0 but if the layer is associated with a view,
    /// the view sets this value to match the screen.
    open var contentsScale: CGFloat = 1.0

    open var contentsGravity: CALayerContentsGravity = .resize

    internal (set) public weak var superlayer: CALayer?
    internal (set) public var sublayers: [CALayer]? {
        didSet { CALayer.layerTreeIsDirty = true }
    }

    open func insertSublayer(_ layer: CALayer, at index: UInt32) {
        layer.removeFromSuperlayer()
        if sublayers == nil { sublayers = [] }

        let endIndex = sublayers?.endIndex ?? 0
        sublayers?.insert(layer, at: min(Int(index), endIndex))
        layer.superlayer = self
    }

    open func insertSublayer(_ layer: CALayer, above sibling: CALayer) {
        guard let sublayers = sublayers, let insertIndex = sublayers.firstIndex(of: sibling) else {
            preconditionFailure("self.sublayers must exist and contain sibling CALayer '\(sibling)'")
        }

        insertSublayer(layer, at: UInt32(insertIndex.advanced(by: 1)))
    }

    open func insertSublayer(_ layer: CALayer, below sibling: CALayer) {
        guard let sublayers = sublayers, let insertIndex = sublayers.firstIndex(of: sibling) else {
            preconditionFailure("self.sublayers must exist and contain sibling CALayer '\(sibling)'")
        }

        insertSublayer(layer, at: UInt32(insertIndex))
    }

    open func addSublayer(_ layer: CALayer) {
        insertSublayer(layer, at: UInt32(sublayers?.endIndex ?? 0))
    }

    open func removeFromSuperlayer() {
        hasBeenRenderedInThisPartOfOverallLayerHierarchy = false
        if let superlayer = superlayer {
            superlayer.sublayers = superlayer.sublayers?.filter { $0 != self }
            if superlayer.sublayers?.isEmpty == true {
                superlayer.sublayers = nil
            }
        }

        superlayer = nil
    }

    open var backgroundColor: CGColor? {
        willSet(newColor) {
            guard newColor != backgroundColor else { return }
            onWillSet(keyPath: .backgroundColor)
        }
    }

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
            // `position` is set untransformed because it is in the superview's coordinate system:
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

            if !isPresentationForAnotherLayer && bounds.size != newBounds.size {
                // It seems weird to access the superview here but it matches the iOS behaviour
                (self.superlayer?.delegate as? UIView)?.setNeedsLayout()
            }

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

    public var isHidden = false {
        didSet { CALayer.layerTreeIsDirty = true }
    }
    
    public var cornerRadius: CGFloat = 0

    // TODO: Implement these!
    public var borderWidth: CGFloat = 0
    public var borderColor: CGColor = UIColor.black.cgColor
    public var shadowPath: CGRect?
    public var shadowColor: CGColor?
    public var shadowOpacity: Float = 0
    public var shadowOffset: CGSize = .zero
    public var shadowRadius: CGFloat = 0

    public var mask: CALayer? {
        didSet {
            mask?.superlayer = self
        }
    }

    public var masksToBounds = false

    public required init() {}

    public required init(layer: Any) {
        guard let layer = layer as? CALayer else { fatalError() }
        bounds = layer.bounds
        delegate = layer.delegate
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
        masksToBounds = layer.masksToBounds
        contents = layer.contents // XXX: we should make a copy here
        contentsScale = layer.contentsScale
        superlayer = layer.superlayer
        sublayers = layer.sublayers
        contentsGravity = layer.contentsGravity
    }

    open func copy() -> Any {
        return CALayer(layer: self)
    }

    open func action(forKey event: String) -> CAAction? {
        if let delegate = delegate {
            return delegate.action(forKey: event)
        }
        return CALayer.defaultAction(forKey: event)
    }

    /// returns a non animating copy of the layer
    func createPresentation() -> CALayer {
        let copy = CALayer(layer: self)
        copy.isPresentationForAnotherLayer = true
        return copy
    }

    internal var _presentation: CALayer?
    open func presentation() -> CALayer? { return _presentation }

    internal var isPresentationForAnotherLayer = false

    internal var animations = [String: CABasicAnimation]() {
        didSet { onDidSetAnimations(wasEmpty: oldValue.isEmpty) }
    }

    /// We disable animation on parameters of views / layers that haven't been rendered yet.
    /// This is both a performance optimization (avoids lots of animations at the start)
    /// as well as a correctness fix (matches iOS behaviour). Maybe there's a better way though?
    internal var hasBeenRenderedInThisPartOfOverallLayerHierarchy = false

    internal var _needsDisplay = true
    open func needsDisplay() -> Bool { return _needsDisplay }
    open func setNeedsDisplay() { _needsDisplay = true }
    open func display() {
        delegate?.display(self)
    }
}

private extension CGPoint {
    static let defaultAnchorPoint = CGPoint(x: 0.5, y: 0.5)
}

extension CALayer: CustomStringConvertible {
    public var description: String {
        let indent = "\n    - "
        let anchorPointDescription =
            (anchorPoint != .defaultAnchorPoint) ? "\(indent)anchorPoint: \(anchorPoint)" : ""

        let colourDescription =
            (backgroundColor != nil) ? "\(indent)backgroundColor: \(backgroundColor!)" : ""

        return """
            \(type(of: self))
                - frame: \(frame),
                - bounds: \(bounds),
                - position: \(position)\(anchorPointDescription)\(colourDescription)
            """
    }
}

extension CALayer {
    /**
     Indicates whether a layer somewhere has changed since the last render pass.

     The current implementation of this is quite simple and doesn't check whether the layer is actually in
     the layer hierarchy or not. In theory this means that we're wasting render passes if users frequently
     update layers that aren't in the tree. In practice it's not expected that UIKit users would do that
     often enough for us to care about it.
    **/
    public static var layerTreeIsDirty = true
}

extension CALayer: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    public static func == (lhs: CALayer, rhs: CALayer) -> Bool {
        return lhs === rhs
    }
}

public protocol CALayerDelegate: class {
    func action(forKey event: String) -> CABasicAnimation?
    func display(_ layer: CALayer)
}
