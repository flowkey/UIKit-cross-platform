internal import SDL

@MainActor
open class UIView: UIResponder, CALayerDelegate, UIAccessibilityIdentification {
    open class var layerClass: CALayer.Type {
        return CALayer.self
    }

    public let layer: CALayer

    open var frame: CGRect {
        get { return layer.frame }
        set {
            if frame.size != newValue.size {
                needsLayout = true
            }
            layer.frame = newValue
        }
    }

    open var bounds: CGRect {
        get { return layer.bounds }
        set {
            if bounds.size != newValue.size {
                needsLayout = true
            }
            layer.bounds = newValue
        }
    }

    open var center: CGPoint {
        get { return CGPoint(x: frame.midX, y: frame.midY) }
        set { frame.midX = newValue.x; frame.midY = newValue.y }
    }

    open var transform: CGAffineTransform {
        get { return layer.affineTransform() }
        set {
            layer.setAffineTransform(newValue)

            // XXX: This doesn't actually happen on iOS but the subviews get layouted somehow anyway
            needsLayout = true
        }
    }

    public var safeAreaInsets: UIEdgeInsets {
        return UIWindow.getSafeAreaInsets()
    }

    open var mask: UIView? {
        didSet {
            layer.mask = mask?.layer
            mask?.superview = self
        }
    }

    open var isHidden: Bool {
        get { return layer.isHidden }
        set { layer.isHidden = newValue }
    }

    open var isUserInteractionEnabled = true

    /// returns true if any animation was started with allowUserInteraction
    /// or if no animation is currently running
    var anyCurrentlyRunningAnimationsAllowUserInteraction: Bool {
        return layer.animations.isEmpty || layer.animations.values.contains {
            $0.animationGroup?.options.contains(.allowUserInteraction) ?? false
        }
    }

    internal var needsLayout = true
    internal var needsDisplay = true

    /// Override this to draw to the layer's texture whenever `self.needsDisplay`
    open func draw() {}
    open func display(_ layer: CALayer) {}

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

    open var tintColor: UIColor! // mocked

    public var isOpaque: Bool = false // mocked
    // TODO: implement with relation to drawing system: https://developer.apple.com/documentation/uikit/uiview/1622622-isopaque

    public var clipsToBounds: Bool{
        get { return layer.masksToBounds }
        set { layer.masksToBounds = newValue }
    }

    public internal(set) weak var superview: UIView? {
        // willSet {
        // XXX: We should call willMoveToSuperview(newValue) here, but we haven't implemented it yet
        // }
        didSet {
            didMoveToSuperview()
            if !(self.next is UIViewController) {
                self.next = superview
            }
        }
    }

    internal(set) public var subviews: [UIView] = [] {
        didSet {
            assert(subviews.contains(self) == false, "A view's subviews cannot contain itself!")
        }
    }

    override public convenience init() {
        self.init(frame: .zero)
    }

    public init(frame: CGRect) {
        self.layer = type(of: self).layerClass.init()
        self.layer.contentsScale = UIScreen.main.scale
        super.init()

        self.layer.delegate = self
        self.frame = frame
    }


    // MARK: Subviews, Superviews

    open func addSubview(_ view: UIView) {
        self.setNeedsLayout()
        layer.addSublayer(view.layer)
        insertSubviewWithoutTouchingLayer(view, at: subviews.endIndex)
    }

    open func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        // CALayer traps when trying to add below / above a non-existent sibling, so we need to double up some logic:
        if let layerIndex = layer.sublayers?.firstIndex(of: siblingSubview.layer) {
            layer.insertSublayer(view.layer, at: UInt32(layerIndex + 1))
        } else {
            layer.addSublayer(view.layer)
        }

        // If sibling is not found, just add to end of array
        let index = subviews.firstIndex(of: siblingSubview)?.advanced(by: 1) ?? subviews.endIndex
        insertSubviewWithoutTouchingLayer(view, at: index)
    }

    open func insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        // CALayer traps when trying to add below / above a non-existent sibling, so we need to double up some logic:
        if let layerIndex = layer.sublayers?.firstIndex(of: siblingSubview.layer) {
            layer.insertSublayer(view.layer, at: UInt32(layerIndex))
        } else {
            layer.addSublayer(view.layer)
        }

        // Inserting an object at index 0 pushes the existing object at index 0 to index 1
        // If sibling is not found, just add to end of array
        let index = subviews.firstIndex(of: siblingSubview) ?? subviews.endIndex
        insertSubviewWithoutTouchingLayer(view, at: index)
    }

    open func insertSubview(_ view: UIView, at index: Int) {
        // XXX: This might not cover all cases yet. Managing these two hierarchies is complex...
        if index == 0 {
            layer.insertSublayer(view.layer, at: 0)
        } else if let currentSubview = safeGetSubview(index: index) {
            layer.insertSublayer(view.layer, below: currentSubview.layer)
        } else {
            // The given index was greater than that of any existing subview, meaning:
            // We didn't replace any view. Just push the new layer to the end of the sublayers array.
            layer.addSublayer(view.layer)
        }

        insertSubviewWithoutTouchingLayer(view, at: index)
    }

    private func safeGetSubview(index: Int) -> UIView? {
        guard index >= subviews.startIndex, index < subviews.endIndex else { return nil }
        return subviews[index]
    }

    /// Adds a subview without touching the view's layer or any of its sublayers.
    /// We need to be able to add layers at an index that isn't directly related to its subview index.
    private func insertSubviewWithoutTouchingLayer(_ view: UIView, at index: Int) {
        // remove from superview without removing from superlayer
        if let oldSuperview = view.superview {
            oldSuperview.subviews.removeAll(where: { $0 == view })
            view.superview = nil
            oldSuperview.setNeedsLayout()
        }

        // ensure index is always in bounds:
        let index = max(subviews.startIndex, min(index, subviews.endIndex))
        subviews.insert(view, at: index)
        view.superview = self
    }

    open func removeFromSuperview() {
        guard let superview = superview else { return }
        self.layer.removeFromSuperlayer()

        superview.subviews.removeAll(where: { $0 == self })
        self.superview = nil
        superview.setNeedsLayout()
    }

    /// Called when the view was added to a non-nil subview
    open func didMoveToSuperview() {}

    internal var parentViewController: UIViewController? {
        return next as? UIViewController
    }

    open func layoutSubviews() {
        needsLayout = false
        parentViewController?.viewWillLayoutSubviews()
        parentViewController?.viewDidLayoutSubviews()
    }


    // `public` not `open` because I'm not sure it makes sense to override these:

    /// Converts the given point from `self`'s bounds to the bounds of another UIView.
    /// If the other view is `nil` or is not in the same view hierarchy as `self`,
    /// the original point will be return unchanged.
    public func convert(_ point: CGPoint, to otherView: UIView?) -> CGPoint {
        // Fastest path is doing no work :)
        guard let otherView, otherView != self else { return point }

        // Fast paths:
        if self == otherView.superview {
            return convertToSubview(point, subview: otherView)
        } else if let superview = self.superview, superview == otherView {
            return convertToSuperview(point)
        }

        // Slow path:
        let selfAbsoluteOrigin = self.absoluteOrigin()
        let otherAbsoluteOrigin = otherView.absoluteOrigin()

        let originDifference = (otherAbsoluteOrigin - selfAbsoluteOrigin)

        // TODO: This is a hack. We don't properly incorporate all transforms up the tree.
        return (point - originDifference).applying(otherView.superview?.transform.inverted() ?? .identity)
    }

    private func convertToSuperview(_ point: CGPoint) -> CGPoint {
        return (point - bounds.origin).applying(transform) + frame.origin
    }

    /// `point` is in self.bounds.size coordinates
    private func convertToSubview(_ point: CGPoint, subview: UIView) -> CGPoint {
        precondition(subview.superview == self)
        guard let invertedSubviewTransform = subview.transform.inverted() else {
            assertionFailure("Tried to convert a point to a subview whose transfrom could not be inverted")
            return point
        }

        return (point - subview.frame.origin).applying(invertedSubviewTransform) + subview.bounds.origin
    }

    /// Returns `self.frame.origin` in `window.bounds` coordinates
    internal func absoluteOrigin() -> CGPoint {
        var result: CGPoint = .zero
        var view = self
        while let superview = view.superview {
            let translatedFrameOrigin = view.convert(.zero, to: superview)

            // This is the important step:
            // We start deep in the hierarchy and at every level multiply the total result by the parent transform
            // Without this, we would be ignoring the fact that a transform in (e.g.) the UIWindow affects ALL
            // its subviews and their subviews, rather than just one level at a time.
            result = (result + translatedFrameOrigin).applying(superview.transform)
            view = superview
        }

        return result
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
        guard !isHidden, isUserInteractionEnabled, anyCurrentlyRunningAnimationsAllowUserInteraction,
            alpha > 0.01, self.point(inside: point, with: event) else { return nil }

        // reversing allows us to return the view with the highest z-index in the shortest amount of time:
        for subview in subviews.reversed() {
            if let hitView = subview.hitTest(subview.convert(point, from: self), with: event) {
                return hitView
            }
        }

        return self
    }

    /// Checks whether `point` is in the view's bounds (meaning it is affected by `self.bounds.origin`)
    /// It would be easier to understand this if it was called `contains(_ point: CGPoint, with event:)`
    open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.contains(point)
    }

    open func sizeThatFits(_ size: CGSize) -> CGSize {
        return bounds.size
    }

    open func sizeToFit() {
        let originalOrigin = self.frame.origin
        self.bounds.size = sizeThatFits(bounds.size)
        self.frame.origin = originalOrigin
    }

    // We originally had this in an extension but Swift functions in extensions cannot be overridden (as of Swift 4)
    open func action(forKey event: String) -> CABasicAnimation? {
        guard let prototype = UIView.currentAnimationPrototype else { return nil }

        let keyPath = AnimationKeyPath(stringLiteral: event)
        let beginFromCurrentState = prototype.animationGroup.options.contains(.beginFromCurrentState)
        let state = beginFromCurrentState ? (layer._presentation ?? layer) : layer

        if let fromValue = state.value(forKeyPath: keyPath) {
            return prototype.createAnimation(keyPath: keyPath, fromValue: fromValue)
        }

        return nil
    }

    // MARK: Accessibility
    open var accessibilityIdentifier: String?
}

extension UIView: CustomStringConvertible {
    public var description: String {
        return """
            \(type(of: self))
            - transform: \(transform.description)
            - layer: \(layer.description)
            """
    }
}


extension UIView: Equatable {
    nonisolated public static func == (lhs: UIView, rhs: UIView) -> Bool {
        return lhs === rhs
    }
}

extension UIView: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}
