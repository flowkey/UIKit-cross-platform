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
    
    var indicatorThickness: CGFloat = 3
    
    public var indicatorStyle: UIScrollViewIndicatorStyle = .`default`
    
    //TODO: var scrollIndicatorInsets
    
    //TODO: scroll indicators should fade immediately when drag is finger-stopped or with a delay when drag ends
    //TOOO: bouncing/contentInset
    
    var weightedAverageVelocity: CGPoint = .zero
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        panGestureRecognizer.onAction = { [weak self] in self?.onPan() }
        panGestureRecognizer.onStateChanged = { [weak self] in self?.onPanGestureStateChanged() }
        addGestureRecognizer(panGestureRecognizer)
        clipsToBounds = true
        
        
        for scrollIndicator in [verticalScrollIndicator, horizontalScrollIndicator] {
            scrollIndicator.layer.cornerRadius = indicatorThickness / 2
            scrollIndicator.backgroundColor = self.indicatorStyle.backgroundColor
            
            if let borderColor = self.indicatorStyle.borderColor {
                scrollIndicator.layer.borderWidth = 0.5
                scrollIndicator.layer.borderColor = borderColor
            }
            addSubview(scrollIndicator)
            //NOTE: should indicators be laid out here?
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
            if (showsVerticalScrollIndicator || showsHorizontalScrollIndicator) {
                layoutScrollIndicators()
            }
        }
    }
    
    
    open var showsVerticalScrollIndicator = true
    open var showsHorizontalScrollIndicator = true
    
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
    
    
    
    public func layoutScrollIndicators() {

        // all calculations are done for both dimensions at once
        let indicatorLengths = (bounds.size / contentSize) * bounds.size
        let scrollViewProgress = contentOffset / contentSize
        let indicatorProgress = scrollViewProgress * bounds.size
        let baseOffsetsOfScrollView = contentOffset
        
        let indicatorLenghtsCompensationTerm = scrollViewProgress * indicatorLengths - (indicatorLengths / 2)
        let indicatorOffsets =  baseOffsetsOfScrollView + indicatorProgress - indicatorLenghtsCompensationTerm
        
        // layout only the indicator(s) that should be visible
        if showsVerticalScrollIndicator && contentSize.height > bounds.height {
            verticalScrollIndicator.frame = CGRect(
                x: bounds.maxX - indicatorThickness,
                y: indicatorOffsets.y,
                width: indicatorThickness,
                height: indicatorLengths.height
            )
        }
        
        if showsHorizontalScrollIndicator && contentSize.width > bounds.width {
            horizontalScrollIndicator.frame = CGRect(
                x: indicatorOffsets.x,
                y: bounds.maxY - indicatorThickness,
                width: indicatorLengths.width,
                height: indicatorThickness
            )
        }
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
        case .`default`: return UIColor.lightGray // Default according to iOS UIKit docs is "black with a white border", but it's actually grey with no border/grey border (as observable in any default iOS app)
        case .black: return UIColor.black
        case .white: return UIColor.white
        }
    }
    
    var borderColor: UIColor? {
        switch self {
        case .`default`: return UIColor.white
        default : return nil
        }
    }
    
}


