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

    var verticalScrollIndicator = UIView()
    var horizontalScrollIndicator = UIView()

    // TODO: should getBoundsCheckedContentOffset also be applied here or in setContentOffset? check again with iOS
    open var contentOffset: CGPoint {
        get { return bounds.origin }
        set {
            guard newValue != contentOffset else { return }
            cancelDecelerationAnimations()
            bounds.origin = newValue
            layoutScrollIndicatorsIfNeeded()
        }
    }

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

    /// The contentOffset that is currently shown on the screen
    /// We won't need this once we implement animations via DisplayLink instead of with UIView.animate
    var visibleContentOffset: CGPoint {
        return (layer._presentation ?? layer).bounds.origin
    }

    /// does some min/max checks to prevent newOffset being out of bounds
    func getBoundsCheckedContentOffset(_ newContentOffset: CGPoint) -> CGPoint {
        return CGPoint(
            x: min(max(newContentOffset.x, -contentInset.left), (contentSize.width + contentInset.right) - bounds.width),
            y: min(max(newContentOffset.y, -contentInset.top), (contentSize.height + contentInset.bottom) - bounds.height)
        )
    }

    var weightedAverageVelocity: CGPoint = .zero

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = { [weak self] in self?.onPan() }
        panGestureRecognizer.onStateChanged = { [weak self] in self?.onPanGestureStateChanged() }
        addGestureRecognizer(panGestureRecognizer)
        clipsToBounds = true

        applyScrollIndicatorsStyle()
        [horizontalScrollIndicator, verticalScrollIndicator].forEach {
            $0.alpha = 0
            addSubview($0)
        }
    }

    // When adding subviews, make sure that the scroll indicators stay on top.
    // Subview list goes back-to-front, so indicators need to take the last two positions.
    // We use the earliestIndicatorInSubviewHierarchy variable to make sure new views are always inserted below them.
    private lazy var firstIndicatorInSubviews: UIView? = {
        return subviews.first(where: { $0 === horizontalScrollIndicator || $0 === verticalScrollIndicator })
    }()


    open override func addSubview(_ view: UIView) {
        // Indicators should always stay on top of the view hierarchy (so the end of the subviews list, at two highest indexes)
        // we insert new views "below them" (so one position before the scroll indicator with the lower of two highest indexes)
        if
            view !== horizontalScrollIndicator,
            view !== verticalScrollIndicator,
            let firstIndicatorInSubviews = firstIndicatorInSubviews
        {
            super.insertSubview(view, belowSubview: firstIndicatorInSubviews)
        } else {
            super.addSubview(view)
        }
    }


    open override func insertSubview(_ view: UIView, at index: Int) {
        var indexOfLastIndicator = Int.max
        if let earliestIndicatorInSubviewHierarchy = earliestIndicatorInSubviewHierarchy {
            indexOfLastIndicator = subviews.index(of: earliestIndicatorInSubviewHierarchy)!
        }
        super.insertSubview(view, at: min(index, indexOfLastIndicator - 1))
    }

    open var isDecelerating = false {
        didSet {
            // Hide when we stop decelerating, but only when that wasn't because of a pan
            if !isDecelerating && panGestureRecognizer.state == .possible {
                hideScrollIndicators()
            }
        }
    }

    private func onPan() {
        let translation = panGestureRecognizer.translation(in: self)
        panGestureRecognizer.setTranslation(.zero, in: self)

        let panGestureVelocity = panGestureRecognizer.velocity(in: self)
        self.weightedAverageVelocity = self.weightedAverageVelocity * 0.2 + panGestureVelocity * 0.8

        let newOffset = getBoundsCheckedContentOffset(visibleContentOffset - translation)
        setContentOffset(newOffset, animated: false)
    }

    private func onPanGestureStateChanged() {
        switch panGestureRecognizer.state {
        case .began:
            showScrollIndicators()
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

    // MARK: Scroll Indicators

    // Matching Apple's value
    let indicatorThickness: CGFloat = 2.5

    // Determined experimentally to be as close as possible to Apple's (likely exactly matching)
    private let baseScrollIndicatorInsets = UIEdgeInsets(top: 2.5, left: 2.5, bottom: 2.5, right: 2.5)

    public var indicatorStyle: IndicatorStyle = .`default` {
        didSet { applyScrollIndicatorsStyle() }
    }

    public var scrollIndicatorInsets = UIEdgeInsets.zero

    var totalScrollIndicatorInsets: UIEdgeInsets {
        return UIEdgeInsets(top: baseScrollIndicatorInsets.top + scrollIndicatorInsets.top,
                            left: baseScrollIndicatorInsets.left + scrollIndicatorInsets.left,
                            bottom: baseScrollIndicatorInsets.bottom + scrollIndicatorInsets.bottom,
                            right: baseScrollIndicatorInsets.right + scrollIndicatorInsets.right)
    }

    private func applyScrollIndicatorsStyle() {
        for scrollIndicator in [verticalScrollIndicator, horizontalScrollIndicator] {
            scrollIndicator.layer.cornerRadius = indicatorThickness / 2
            scrollIndicator.backgroundColor = self.indicatorStyle.backgroundColor
        }
    }

    open var showsVerticalScrollIndicator = true
    open var showsHorizontalScrollIndicator = true

    open func flashScrollIndicators() {
        showScrollIndicators()
        hideScrollIndicators()
    }
}

public protocol UIScrollViewDelegate: class {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool)
}

extension UIScrollView {
    public enum IndicatorStyle {
        case `default`
        case black
        case white

        var backgroundColor: UIColor {
            switch self {
            // Default according to iOS UIKit docs is "black with a white border".
            // But actually it's a black stretchable image with a peak opacity of 0.35.
            // We render it differently, so we add a little opacity to get a similar effect:
            case .`default`: return UIColor.black.withAlphaComponent(0.37)
            case .black: return UIColor.black
            case .white: return UIColor.white
            }
        }
    }
}
