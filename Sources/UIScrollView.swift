//
//  UIScrollView.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class UIScrollView: UIView {
    open var delegate: UIScrollViewDelegate? // TODO: change this to individually settable callbacks
    open var panGestureRecognizer = UIPanGestureRecognizer()

    public var scrollViewWillBeginDragging: (() -> Void)?
    public var scrollViewDidScroll: (() -> Void)?
    public var scrollViewDidEndDragging: ((_ willDecelerate: Bool) -> Void)?

    private var verticalScrollIndicator = CALayer()
    public var indicatorStyle: UIColor = .white

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = self.onPan
        panGestureRecognizer.onStateChanged = onPanGestureStateChanged
        addGestureRecognizer(panGestureRecognizer)
        clipsToBounds = true

        verticalScrollIndicator.backgroundColor = self.indicatorStyle
        layer.addSublayer(verticalScrollIndicator)
    }

    var lastOnPanTimestamp: Double = 0
    private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        panGestureRecognizer.setTranslation(.zero, in: self)

        let newX = contentOffset.x - translation.x
        let newY = contentOffset.y - translation.y

        let newOffset = CGPoint(
            x: min(max(newX, -contentInset.left), contentSize.width - bounds.width + contentInset.right),
            y: min(max(newY, -contentInset.top), contentSize.height - bounds.height + contentInset.bottom)
        )

        setContentOffset(newOffset, animated: false)
        delegate?.scrollViewDidScroll(self)
    }

    private func onPanGestureStateChanged() {
        switch panGestureRecognizer.state {
        case .began:
            delegate?.scrollViewWillBeginDragging(self)
        case .ended:
            delegate?.scrollViewDidEndDragging(self, willDecelerate: false) // TODO: fix me
            // XXX: Spring back with animation:
            //case .ended, .cancelled:
            //if contentOffset.x < contentInset.left {
            //    setContentOffset(CGPoint(x: contentInset.left, y: contentOffset.y), animated: true)
            //}
        default: break
        }
    }

    open var contentInset = UIEdgeInsets() //{ didSet {updateBounds()} }
    open var contentSize: CGSize = .zero

    open var contentOffset: CGPoint = .zero {
        didSet {
            updateBounds()
            setNeedsLayout()
        }
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extendedBounds = CGRect(
            x: -contentInset.left,
            y: -contentInset.top,
            width: max(bounds.width, contentInset.left + contentSize.width + contentInset.right),
            height: max(bounds.height, contentInset.top + contentSize.height + contentInset.bottom)
        )

        return extendedBounds.contains(point)
    }

    private func updateBounds() {
        // logically it'd make sense for origin to be `inset + offset` but
        // the original implementation seems to do what we have here instead:
        bounds.origin = contentOffset
    }

    // TODO: Implement these:
    open var showsVerticalScrollIndicator = true {
        didSet { verticalScrollIndicator.isHidden = !showsVerticalScrollIndicator }
    }
    open var showsHorizontalScrollIndicator = true

    open func setContentOffset(_ point: CGPoint, animated: Bool) {
        // TODO: animate
        contentOffset = point
    }

    override open func layoutSubviews() {
        if showsVerticalScrollIndicator { layoutVerticalScrollIndicator() }
    }

    private func layoutVerticalScrollIndicator() {

        if contentSize.height == bounds.height {
            showsVerticalScrollIndicator = false
            return
        }

        let indicatorWidth: CGFloat = 2
        let indicatorHeight: CGFloat = (bounds.height / contentSize.height) * bounds.height
        let indicatorYOffset = contentOffset.y + (contentOffset.y / contentSize.height) * bounds.height

        verticalScrollIndicator.frame = CGRect(
            x: bounds.maxX + 5,
            y: indicatorYOffset,
            width: indicatorWidth,
            height: indicatorHeight
        )
    }

    open func flashScrollIndicators() {

    }
}

public protocol UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
}
