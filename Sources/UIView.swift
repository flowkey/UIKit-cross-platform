//
//  UIView.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 11.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

open class UIView: UIResponder {
    open class var layerClass: CALayer.Type {
        return CALayer.self
    }

    open let layer: CALayer

    // mocked for parentViewController.present function in AlertContainer
    open let parentViewController: UIViewController? = UIViewController()

    open var frame: CGRect {
        get { return layer.frame }
        set { layer.frame = newValue }
    }

    open var bounds: CGRect {
        get { return layer.bounds }
        set { layer.bounds = newValue }
    }

    open var center: CGPoint {
        get { return CGPoint(x: frame.midX, y: frame.midY) }
        set { frame.midX = newValue.x; frame.midY = newValue.y }
    }

    open var transform: CGAffineTransform {
        get { return layer.transform }
        set { layer.transform = newValue }
    }

    open var mask: UIView?

    open var isHidden: Bool {
        get { return layer.isHidden }
        set { layer.isHidden = newValue }
    }

    open var isUserInteractionEnabled = true

    /// returns true if any animation was started with allowUserInteraction
    /// or if no animation is currently running
    var animationsAllowUserInteraction: Bool {
        return layer.animations.isEmpty || layer.animations.values.contains {
            $0.animationGroup?.options.contains(.allowUserInteraction) ?? false
        }
    }

    internal var needsLayout = true
    internal var needsDisplay = true

    /// Override this to draw to the layer's texture whenever `self.needsDisplay`
    open func draw() {
        needsDisplay = false
    }

    public func setNeedsDisplay() {
        needsDisplay = true
    }

    public func setNeedsLayout() {
        needsLayout = true
    }

    public func layoutIfNeeded() {
        if needsLayout {
            layoutSubviews()
            needsLayout = false
        }
    }

    public var backgroundColor: UIColor? {
        get { return layer.backgroundColor }
        set { layer.backgroundColor = newValue }
    }

    public var alpha: CGFloat {
        get { return CGFloat(layer.opacity) }
        set { layer.opacity = Float(newValue) }
    }

    public var tintColor: UIColor! // mocked

    public var isOpaque: Bool = false // mocked
    // TODO: implement with relation to drawing system: https://developer.apple.com/documentation/uikit/uiview/1622622-isopaque

    public var clipsToBounds: Bool{
        get { return layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }

    private weak var _superview: UIView?
    public internal(set) var superview: UIView? {
        get { return _superview }
        set {
            removeFromSuperview()
            _superview = newValue
            layer.superlayer = newValue?.layer
            if superview != nil { didMoveToSuperview() } // XXX: should this always be called?
        }
    }

    internal(set) public var subviews: [UIView] = [] {
        didSet {
            assert(subviews.contains(self) == false, "A view's subviews cannot contain itself!")
        }
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public init(frame: CGRect) {
        self.layer = type(of: self).layerClass.init()
        self.layer.delegate = self
        self.frame = frame
    }


    // MARK: Subviews, Superviews

    open func addSubview(_ view: UIView) {
        insertSubviewWithoutTouchingLayer(view, at: subviews.endIndex)
        layer.addSublayer(view.layer)
    }

    open func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        // If sibling is not found, just add to end of array
        let index = subviews.index(of: siblingSubview)?.advanced(by: 1) ?? subviews.endIndex
        insertSubviewWithoutTouchingLayer(view, at: index)
        layer.insertSublayer(view.layer, above: siblingSubview.layer)
    }

    open func insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        // Inserting an object at index 0 pushes the existing object at index 0 to index 1
        // If sibling is not found, just add to end of array
        let index = subviews.index(of: siblingSubview) ?? subviews.endIndex
        insertSubviewWithoutTouchingLayer(view, at: index)
        layer.insertSublayer(view.layer, below: siblingSubview.layer)
    }

    open func insertSubview(_ view: UIView, at index: Int) {
        insertSubviewWithoutTouchingLayer(view, at: index)

        // XXX: This might not cover all cases yet. Managing these two hierarchies is complex...
        let indexOfViewWeJustPushedForwardInArray = index + 1
        if index == 0 {
            layer.insertSublayer(view.layer, at: 0)
        } else if let currentSubview = safeGetSubview(index: indexOfViewWeJustPushedForwardInArray) {
            layer.insertSublayer(view.layer, below: currentSubview.layer)
        } else {
            // The given index was greater than that of any existing subview, meaning:
            // We didn't replace any view. Just push the new layer to the end of the sublayers array.
            // XXX: Maybe we should assert instead, not sure of iOS behaviour if `index` is out of bounds
            layer.addSublayer(view.layer)
        }
    }

    private func safeGetSubview(index: Int) -> UIView? {
        guard index >= subviews.startIndex, index < subviews.endIndex else { return nil }
        return subviews[index]
    }

    /// Adds a subview without touching the view's layer or any of its sublayers.
    /// We need to be able to add layers at an index that isn't directly related to its subview index.
    private func insertSubviewWithoutTouchingLayer(_ view: UIView, at index: Int) {
        // ensure index is always in bounds:
        let index = max(subviews.startIndex, min(index, subviews.endIndex))
        subviews.insert(view, at: index)
        view.superview = self
    }

    open func removeFromSuperview() {
        guard let superview = superview else { return }
        superview.subviews = superview.subviews.filter { $0 != self }
        _superview = nil // NOTE: we directly access the storage here to avoid an infinite loop

        self.layer.removeFromSuperlayer()
    }

    /// Called when the view was added to a non-nil subview
    open func didMoveToSuperview() {}

    open func layoutSubviews() {
        needsLayout = false
        subviews.forEach { $0.setNeedsLayout() }
    }


    // `public` not `open` because I'm not sure it makes sense to override these:

    /// Converts the given point from `self`'s bounds to the bounds of another UIView.
    /// If the other view is `nil` or is not in the same view hierarchy as `self`,
    /// the original point will be return unchanged.
    public func convert(_ point: CGPoint, to view: UIView?) -> CGPoint {
        // Fastest path is doing no work :)
        guard let otherView = view, otherView != self else { return point }

        // Fast paths:
        if let superview = self.superview, superview == otherView {
            return frame.origin.offsetBy(-superview.bounds.origin).offsetBy(point)
        } else if otherView.superview == self {
            let otherViewOrigin = otherView.frame.origin.offsetBy(-self.bounds.origin)
            return CGPoint(x: point.x - otherViewOrigin.x, y: point.y - otherViewOrigin.y)
        }

        // Slow path:
        let selfAbsoluteOrigin = self.absoluteOrigin()
        let otherAbsoluteOrigin = otherView.absoluteOrigin()
        let originDifference = CGSize(
            width: otherAbsoluteOrigin.x - selfAbsoluteOrigin.x,
            height: otherAbsoluteOrigin.y - selfAbsoluteOrigin.y
        )

        return CGPoint(x: point.x - originDifference.width, y: point.y - originDifference.height)
    }

    func absoluteOrigin() -> CGPoint {
        var view = self
        var origin = frame.origin
        while let superview = view.superview {
            view = superview
            origin = superview.frame.origin.offsetBy(-superview.bounds.origin).offsetBy(origin)
        }
        return origin
    }

    public func convert(_ point: CGPoint, from view: UIView?) -> CGPoint {
        return view?.convert(point, to: self) ?? point
    }


    // MARK: Event handling
    // Reference: http://smnh.me/hit-testing-in-ios/

    internal var gestureRecognizers: Set<UIGestureRecognizer> = []
    open func addGestureRecognizer(_ recognizer: UIGestureRecognizer) {
        recognizer.view = self
        gestureRecognizers.insert(recognizer)
    }

    open func removeGestureRecognizer(_ recognizer: UIGestureRecognizer) {
        recognizer.view = nil
        gestureRecognizers.remove(recognizer)
    }

    open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, isUserInteractionEnabled, animationsAllowUserInteraction,
            alpha > 0.01, self.point(inside: point, with: event) else { return nil }

        // reversing allows us to return the view with the highest z-index in the shortest amount of time:
        for subview in subviews.reversed() {
            if let hitView = subview.hitTest(subview.convert(point, from: self), with: event) {
                return hitView
            }
        }

        return self
    }

    /// It would be easier to understand this if it was called `contains(_ point: CGPoint, with event:)`
    open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return CGRect(origin: .zero, size: bounds.size).contains(point)
    }

    open func sizeThatFits(_ size: CGSize) -> CGSize {
        return bounds.size
    }

    open func sizeToFit() {
        self.bounds.size = sizeThatFits(self.bounds.size)
        setNeedsLayout()
    }

    // MARK: UIResponder conformance:

    open func next() -> UIResponder? {
        return superview
    }

    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
}


// for some reason classes are not automatically equatable:
extension UIView: Equatable {
    public static func == (lhs: UIView, rhs: UIView) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

