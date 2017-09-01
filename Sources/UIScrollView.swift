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

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = self.onPan
        panGestureRecognizer.onStateChanged = onPanGestureStateChanged
        addGestureRecognizer(panGestureRecognizer)
    }

    var lastOnPanTimestamp: Double = 0
    private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        panGestureRecognizer.setTranslation(.zero, in: self)

        let newX = contentOffset.x - translation.x
        let newY = contentOffset.y - translation.y
        let newOffset = CGPoint(
            // XXX: Change this to accommodate `bounce`
            x: min(max(newX, -contentInset.left), contentSize.width + contentInset.right),
            y: min(max(newY, -contentInset.top), contentInset.bottom) // XXX: logically incorrect
        )

        setContentOffset(newOffset, animated: false)
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
    open var contentSize: CGSize = .zero {
        didSet { bounds.size = contentSize }
    }
    open var contentOffset: CGPoint = .zero {
        didSet {
            updateBounds()
            delegate?.scrollViewDidScroll(self)
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
        bounds.origin = -contentOffset
    }

    // TODO: Implement these:
    open var showsVerticalScrollIndicator = true
    open var showsHorizontalScrollIndicator = true

    open func setContentOffset(_ point: CGPoint, animated: Bool) {
        // TODO: animate
        contentOffset = point
    }
}

public protocol UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
}
