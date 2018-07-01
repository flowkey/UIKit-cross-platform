//
//  UIScrollView+indicatorsInternal.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

// NOTE: Everything in this file must be private / internal-only.
// You can't override methods that were defined in an extension.

internal extension UIScrollView {
    internal static let indicatorDistanceFromScrollViewFrame: CGFloat = 2.5

    internal var indicatorLengths: (horizontal: CGFloat, vertical: CGFloat) {
        // XXX: restrict possible values with a minimum of ~30 (like iOS does it)
        get {
            return (horizontal: (bounds.width / contentSize.width) * bounds.width,
                    vertical: (bounds.height / contentSize.height) * bounds.height)
        }
    }

    internal var indicatorOffsetsInContentSpace: (horizontal: CGFloat, vertical: CGFloat) {
        get {
            let indicatorDistanceFromScrollViewFrame =  UIScrollView.indicatorDistanceFromScrollViewFrame

            let totalContentArea = (
                horizontal: contentInset.left + contentSize.width + contentInset.right,
                vertical: contentInset.top + contentSize.height + contentInset.bottom
            )

            let scrollViewProgress = (
                horizontal: (contentInset.left + contentOffset.x) / (totalContentArea.horizontal - bounds.width),
                vertical: (contentInset.top + contentOffset.y) / (totalContentArea.vertical - bounds.height)
            )

            let bothIndicatorsShowing = shouldLayoutHorizontalScrollIndicator && shouldLayoutVerticalScrollIndicator

            let additionalSpacingToPreventOverlap = (
                horizontal: bothIndicatorsShowing ? 2*indicatorDistanceFromScrollViewFrame : 0,
                vertical: bothIndicatorsShowing ? indicatorDistanceFromScrollViewFrame : 0
            )

            let totalSpacingFromFrameSides = (
                horizontal: scrollIndicatorInsets.left + scrollIndicatorInsets.right + additionalSpacingToPreventOverlap.horizontal,
                vertical: scrollIndicatorInsets.bottom + scrollIndicatorInsets.top + additionalSpacingToPreventOverlap.vertical
            )

            let lengthOfAvailableSpaceForIndicators = (
                horizontal: bounds.size.width - (indicatorLengths.horizontal + totalSpacingFromFrameSides.horizontal),
                vertical: bounds.size.height - (indicatorLengths.vertical + totalSpacingFromFrameSides.vertical)
            )

            let indicatorOffsetInBounds = (
                horizontal: scrollViewProgress.horizontal * lengthOfAvailableSpaceForIndicators.horizontal,
                vertical: scrollViewProgress.vertical * lengthOfAvailableSpaceForIndicators.vertical
            )

            return (
                horizontal: contentOffset.x + indicatorOffsetInBounds.horizontal,
                vertical: contentOffset.y + indicatorOffsetInBounds.vertical
            )
        }
    }

    internal var shouldLayoutHorizontalScrollIndicator: Bool {
        return showsHorizontalScrollIndicator && contentSize.width > bounds.width
    }

    internal var shouldLayoutVerticalScrollIndicator: Bool {
        return showsVerticalScrollIndicator && contentSize.height > bounds.height
    }

    internal func layoutScrollIndicatorsIfNeeded() {
        guard shouldLayoutHorizontalScrollIndicator || shouldLayoutVerticalScrollIndicator else { return }
        
        let distanceFromFrame = (
            horizontal: indicatorThickness + scrollIndicatorInsets.bottom,
            vertical: indicatorThickness + scrollIndicatorInsets.right
        )

        if shouldLayoutHorizontalScrollIndicator {
            horizontalScrollIndicator.frame = CGRect(
                x: scrollIndicatorInsets.left + indicatorOffsetsInContentSpace.horizontal, //scrolling direction
                y: bounds.size.height + contentOffset.y - distanceFromFrame.horizontal,
                width: indicatorLengths.horizontal,
                height: indicatorThickness
            )
        }

        if shouldLayoutVerticalScrollIndicator {
            verticalScrollIndicator.frame = CGRect(
                x: bounds.size.width + contentOffset.x - distanceFromFrame.vertical,
                y: scrollIndicatorInsets.top + indicatorOffsetsInContentSpace.vertical,
                width: indicatorThickness,
                height: indicatorLengths.vertical
            )
        }
    }

    // On iOS this seems to occur with no animation at all:
    internal func showScrollIndicators() {
        if shouldLayoutHorizontalScrollIndicator {
            horizontalScrollIndicator.alpha = 1
        }

        if shouldLayoutVerticalScrollIndicator {
            verticalScrollIndicator.alpha = 1
        }
    }

    internal func hideScrollIndicators() {
        UIView.animate(
            withDuration: 0.25,  // these values have been hand-tuned
            delay: 0.05,         // to match iOS
            options: [.beginFromCurrentState, .allowUserInteraction],
            animations: {
                horizontalScrollIndicator.alpha = 0
                verticalScrollIndicator.alpha = 0
            })
    }
}
