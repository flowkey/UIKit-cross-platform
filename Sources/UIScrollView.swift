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
    open weak var delegate: UIScrollViewDelegate? // TODO: change this to individually settable callbacks
    open var panGestureRecognizer = UIPanGestureRecognizer()

    private var verticalScrollIndicator = CALayer()
    public var indicatorStyle: UIScrollViewIndicatorStyle = .white

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = { [weak self] in self?.onPan() }
        panGestureRecognizer.onStateChanged = { [weak self] in self?.onPanGestureStateChanged() }
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

        let newOffset = getBoundsCheckedContentOffset(
            x: contentOffset.x - translation.x,
            y: contentOffset.y - translation.y
        )

        setContentOffset(newOffset, animated: false)
    }

    /// does some min/max checks to prevent newOffset being out of bounds
    func getBoundsCheckedContentOffset(x: CGFloat, y: CGFloat) -> CGPoint {
        return CGPoint(
            x: min(max(x, -contentInset.left), (contentSize.width + contentInset.right) - bounds.width),
            y: min(max(y, -contentInset.top), (contentSize.height + contentInset.bottom) - bounds.height)
        )
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

    open var contentInset: UIEdgeInsets = .zero
    open var contentSize: CGSize = .zero

    open var contentOffset: CGPoint = .zero {
        didSet {
            bounds.origin = contentOffset
            if showsVerticalScrollIndicator { layoutVerticalScrollIndicator() }
        }
    }

//    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        let extendedBounds = CGRect(
//            x: -contentInset.left,
//            y: -contentInset.top,
//            width: max(bounds.width, contentInset.left + contentSize.width + contentInset.right),
//            height: max(bounds.height, contentInset.top + contentSize.height + contentInset.bottom)
//        )
//
//        return extendedBounds.contains(point)
//    }

    open var showsVerticalScrollIndicator = true

    // TODO: Implement these:
    open var showsHorizontalScrollIndicator = true

    open func setContentOffset(_ point: CGPoint, animated: Bool) {
        // TODO: animate
        contentOffset = point

        // otherwise everything subscribing to scrollViewDidScroll is implicitly animated from velocity scroll
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        delegate?.scrollViewDidScroll(self)
        CATransaction.commit()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        if showsVerticalScrollIndicator { layoutVerticalScrollIndicator() }
    }

    private func layoutVerticalScrollIndicator() {
        verticalScrollIndicator.isHidden = (contentSize.height == bounds.height)
        if verticalScrollIndicator.isHidden { return }

        let indicatorWidth: CGFloat = 2
        let indicatorHeight: CGFloat = (bounds.height / contentSize.height) * bounds.height
        let indicatorYOffset = contentOffset.y + (contentOffset.y / contentSize.height) * bounds.height

        verticalScrollIndicator.frame = CGRect(
            x: bounds.maxX - indicatorWidth,
            y: indicatorYOffset,
            width: indicatorWidth,
            height: indicatorHeight
        )
    }

    open func flashScrollIndicators() {

    }
}

public protocol UIScrollViewDelegate: class {
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
