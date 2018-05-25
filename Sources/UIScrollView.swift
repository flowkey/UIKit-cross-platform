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

    let indicatorThickness: CGFloat = 2.5
    let indicatorBaseInsets = UIEdgeInsets(top: 2.5, left: 2.5, bottom: 5.5, right: 8) // TODO: implement those values in layouting
    let indicatorDistanceFromScrollViewFrame: CGFloat = 2.5 // TODO: this is assumed, test with iOS


    public var indicatorStyle: UIScrollViewIndicatorStyle = .`default` {
        didSet {
            applyScrollIndicatorsStyle()
        }
    }

    // TODO: var scrollIndicatorInsets
    // TODO: func flashScrollIndicatores (stub below)

    // TODO: scroll indicators should fade immediately when drag is finger-stopped or with a delay when drag ends
    // TOOO: bouncing [not: blocked by animation update!]

    var weightedAverageVelocity: CGPoint = .zero

    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = { [weak self] in self?.onPan() }
        panGestureRecognizer.onStateChanged = { [weak self] in self?.onPanGestureStateChanged() }
        addGestureRecognizer(panGestureRecognizer)
        clipsToBounds = true
        addSubview(verticalScrollIndicator)
        addSubview(horizontalScrollIndicator)
        applyScrollIndicatorsStyle()
    }

    private func applyScrollIndicatorsStyle() {
        for scrollIndicator in [verticalScrollIndicator, horizontalScrollIndicator] {
            scrollIndicator.layer.cornerRadius = indicatorThickness / 2
            scrollIndicator.backgroundColor = self.indicatorStyle.backgroundColor
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

    // does some min/max checks to prevent newOffset being out of bounds
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


    open var showsVerticalScrollIndicator = true
    open var showsHorizontalScrollIndicator = true

    // TODO: should getBoundsCheckedContentOffset also be applied here or in setContentOffset? check again with iOS
    open var contentOffset: CGPoint {
        get { return bounds.origin }
        set {
            layer.removeAnimation(forKey: "bounds")
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


    internal func indicatorOffsetsInContentSpace() -> (horizontal: CGFloat, vertical: CGFloat) {
        let scrollViewProgress = (horizontal: (contentInset.left + contentOffset.x) / (contentInset.left + contentSize.width + contentInset.right),
                                  vertical: (contentInset.top + contentOffset.y) / (contentInset.top + contentSize.height + contentInset.bottom))

        let indicatorOffsetInBounds = (horizontal: scrollViewProgress.horizontal * bounds.size.width,
                                       vertical: scrollViewProgress.vertical * bounds.size.height)

        return (horizontal: contentOffset.x + indicatorOffsetInBounds.horizontal,
                vertical: contentOffset.y + indicatorOffsetInBounds.vertical)
    }


    public func layoutScrollIndicatorsIfNeeded() {
        let shouldLayoutHorizontalScrollIndicator = showsHorizontalScrollIndicator && contentSize.width > bounds.width
        let shouldLayoutVerticalScrollIndicator = showsVerticalScrollIndicator && contentSize.height > bounds.height
        if !shouldLayoutHorizontalScrollIndicator && !shouldLayoutVerticalScrollIndicator { return }


        // Q: since this only depends on bounds & size,can we avoid recalculating it here?
        let indicatorLengths = (horizontal: (bounds.width / contentSize.width) * bounds.width,
                                vertical: (bounds.height / contentSize.height) * bounds.height)

        // TODO: indicator lenghts and offsets are always rounded up to nearest 0.5 in iOS

        if shouldLayoutHorizontalScrollIndicator {

            horizontalScrollIndicator.frame = CGRect(
                x: indicatorOffsetsInContentSpace().horizontal,
                y: bounds.height - (indicatorThickness + indicatorDistanceFromScrollViewFrame),
                width: indicatorLengths.horizontal,
                height: indicatorThickness
            )
        }

        if shouldLayoutVerticalScrollIndicator {
            verticalScrollIndicator.frame = CGRect(
                x: bounds.width - (indicatorThickness + indicatorDistanceFromScrollViewFrame),
                y: indicatorOffsetsInContentSpace().horizontal,
                width: indicatorThickness,
                height: indicatorLengths.vertical
            )
        }

        // TODO: indicators might not be placed correctly when both of them should be present,
        // since at all times they both have one dimension represented in scrollView frame space, and not content space
    }

    open func flashScrollIndicators() {
        //TODO
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
            // Default according to iOS UIKit docs is "black with a white border",
        // but it's actually grey with no border/grey border (as observable in any default iOS app)
        case .`default`: return UIColor.lightGray
        case .black: return UIColor.black
        case .white: return UIColor.white
        }
    }

}




