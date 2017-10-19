//
//  UIScrollView.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// values from iOS
let UIScrollViewDecelerationRateFast: CGFloat = 0.99
let UIScrollViewDecelerationRateNormal: CGFloat = 0.998

open class UIScrollView: UIView {
    open var delegate: UIScrollViewDelegate? // TODO: change this to individually settable callbacks
    open var panGestureRecognizer = UIPanGestureRecognizer()

    private var verticalScrollIndicator = CALayer()
    public var indicatorStyle: UIScrollViewIndicatorStyle = .white

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = self.onPan
        panGestureRecognizer.onStateChanged = self.onPanGestureStateChanged
        addGestureRecognizer(panGestureRecognizer)
        clipsToBounds = true

        verticalScrollIndicator.disableAnimations = true
        verticalScrollIndicator.backgroundColor = self.indicatorStyle.backgroundColor
        layer.addSublayer(verticalScrollIndicator)
    }

    open var isDecelerating: Bool = false

    private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        panGestureRecognizer.setTranslation(.zero, in: self)

<<<<<<< HEAD
        let newOffset = getBoundsCheckedContentOffset(
            x: contentOffset.x - translation.x,
            y: contentOffset.y - translation.y
=======
        let newX = contentOffset.x - translation.x
        let newY = contentOffset.y - translation.y

        // user can scroll starting at contentInset.left until contentInset.right
        // visible area starts at e.g. contentOffset.x and goes until contentOffset.x + bounds.width
        let newOffset = CGPoint(
            x: min(max(newX, -contentInset.left), (contentSize.width + contentInset.right) - bounds.width),
            y: min(max(newY, -contentInset.top), (contentSize.height + contentInset.bottom) - bounds.height)
>>>>>>> master
        )

        setContentOffset(newOffset, animated: false)
    }

    private func onPanGestureStateChanged() {
        switch panGestureRecognizer.state {
        case .began:
            delegate?.scrollViewWillBeginDragging(self)
            cancelDeceleratingIfNeccessary()
        case .ended:
            delegate?.scrollViewDidEndDragging(self, willDecelerate: false) // TODO: fix me
            startDecelerating()

            // XXX: Spring back with animation:
            //case .ended, .cancelled:
            //if contentOffset.x < contentInset.left {
            //    setContentOffset(CGPoint(x: contentInset.left, y: contentOffset.y), animated: true)
            //}
        default: break
        }
    }

    open var contentInset: UIEdgeInsets = .zero //{ didSet {updateBounds()} }
    open var contentSize: CGSize = .zero

    open var contentOffset: CGPoint = .zero {
        didSet {
            updateBounds()
            if showsVerticalScrollIndicator { layoutVerticalScrollIndicator() }
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

    open var showsVerticalScrollIndicator: Bool {
        get { return !verticalScrollIndicator.isHidden }
        set { verticalScrollIndicator.isHidden = !showsVerticalScrollIndicator }
    }
    // TODO: Implement these:
    open var showsHorizontalScrollIndicator = true

    open func setContentOffset(_ point: CGPoint, animated: Bool) {
        // TODO: animate
        contentOffset = point
        delegate?.scrollViewDidScroll(self)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        if showsVerticalScrollIndicator { layoutVerticalScrollIndicator() }
    }

    private func layoutVerticalScrollIndicator() {
        if contentSize.height == bounds.height {
            verticalScrollIndicator.isHidden = true
            return
        }

        let indicatorWidth: CGFloat = 2
        let indicatorHeight: CGFloat = (bounds.height / contentSize.height) * bounds.height
        let indicatorYOffset = contentOffset.y + (contentOffset.y / contentSize.height) * bounds.height

        verticalScrollIndicator.frame = CGRect(
            x: bounds.maxX,
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

public enum UIScrollViewIndicatorStyle {
    case `default`
    case black
    case white

    var backgroundColor: UIColor {
        switch self {
        case .`default`: return UIColor.black // TBD: default in iOS UIKit is "black with a white border"
        case .black: return UIColor.black
        case .white: return UIColor.white
        }
    }
}
