//
//  UIScrollView.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// values from iOS
// Note these are actually acceleration rates (explains why Fast is a smaller value than Normal)
let UIScrollViewDecelerationRateNormal: CGFloat = 0.998
let UIScrollViewDecelerationRateFast: CGFloat = 0.99

open class UIScrollView: UIView {
    open weak var delegate: UIScrollViewDelegate? // TODO: change this to individually settable callbacks
    open var panGestureRecognizer = UIPanGestureRecognizer()

    private var verticalScrollIndicator = CALayer()
    private var horizontalScrollIndicator = CALayer()
    
    public var indicatorStyle: UIScrollViewIndicatorStyle = .`default` //TODO: implement and use `default`

    var weightedAverageVelocity: CGPoint = .zero

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = { [weak self] in self?.onPan() }
        panGestureRecognizer.onStateChanged = { [weak self] in self?.onPanGestureStateChanged() }
        addGestureRecognizer(panGestureRecognizer)
        clipsToBounds = true

        
        for scrollIndicator in [verticalScrollIndicator, horizontalScrollIndicator] {
            scrollIndicator.cornerRadius = 1
            scrollIndicator.disableAnimations = true
            scrollIndicator.backgroundColor = self.indicatorStyle.backgroundColor
            scrollIndicator.borderWidth = 0.5
            scrollIndicator.borderColor = self.indicatorStyle.borderColor
            layer.addSublayer(scrollIndicator)
        }

    }

    open var isDecelerating: Bool = false

    private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        panGestureRecognizer.setTranslation(.zero, in: self)

        let panGestureVelocity = panGestureRecognizer.velocity(in: self)
        self.weightedAverageVelocity = self.weightedAverageVelocity * 0.2 + panGestureVelocity * 0.8

        let visibleContentOffset = (layer._presentation ?? layer).bounds.origin
        let newOffset = getBoundsCheckedContentOffset(visibleContentOffset - translation)
        setContentOffset(newOffset, animated: false)
    }

    /// does some min/max checks to prevent newOffset being out of bounds
    func getBoundsCheckedContentOffset(_ newContentOffset: CGPoint) -> CGPoint {
        return CGPoint(
            x: min(max(newContentOffset.x, -contentInset.left), (contentSize.width + contentInset.right) - bounds.width),
            y: min(max(newContentOffset.y, -contentInset.top), (contentSize.height + contentInset.bottom) - bounds.height)
        )
    }

    private func onPanGestureStateChanged() {
        switch panGestureRecognizer.state {
        case .began:
            delegate?.scrollViewWillBeginDragging(self)
            cancelDeceleratingIfNeccessary()
        case .ended:
            startDeceleratingIfNecessary()
            weightedAverageVelocity = .zero

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

    open var contentOffset: CGPoint {
        get { return bounds.origin }
        set {
            layer.removeAnimation(forKey: "bounds")
            bounds.origin = newValue
            //TODO: how's this relate to layoutSubviews? abstract out to a func?
            //TODO: framing called twice, check it 
            if showsVerticalScrollIndicator { layoutVerticalScrollIndicator() }
            if showsHorizontalScrollIndicator { layoutHorizontalScrollIndicator() }
        }
    }

    
    open var showsVerticalScrollIndicator = true
    open var showsHorizontalScrollIndicator = true //TODO: implement this

    open func setContentOffset(_ point: CGPoint, animated: Bool) {
        precondition(point.x.isFinite)
        precondition(point.y.isFinite)

        contentOffset = point

        // otherwise everything subscribing to scrollViewDidScroll is implicitly animated from velocity scroll
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        delegate?.scrollViewDidScroll(self)
        CATransaction.commit()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        //TODO: implement as one func?
        if showsVerticalScrollIndicator { layoutVerticalScrollIndicator() }
        if showsHorizontalScrollIndicator { layoutHorizontalScrollIndicator() }
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
    
    private func layoutHorizontalScrollIndicator() {
        horizontalScrollIndicator.isHidden = (contentSize.width == bounds.width)
        if horizontalScrollIndicator.isHidden { return }
        
        
        let indicatorWidth: CGFloat = (bounds.width / contentSize.width) * bounds.width
        let indicatorHeight: CGFloat = 2
        let indicatorXOffset = contentOffset.x + (contentOffset.x / contentSize.width) * bounds.width
        
        horizontalScrollIndicator.frame = CGRect(
            x: indicatorXOffset,
            y: bounds.maxY - indicatorHeight,
            width: indicatorWidth,
            height: indicatorHeight
        )
    }

    open func flashScrollIndicators() {
        //
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
    
    var borderColor: UIColor {
        switch self {
        case .`default`: return UIColor.white // TBD: default in iOS UIKit is "black with a white border"
        case .black: return UIColor.black
        case .white: return UIColor.white
        }
    }
    
}
