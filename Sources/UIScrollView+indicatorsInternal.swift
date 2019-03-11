//
//  UIScrollView+indicatorsInternal.swift
//  UIKit
//
//  Created by Geordie Jay on 29.05.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

// NOTE: Everything in this file must be private or internal.
// You can't override methods that were defined in an extension.

extension UIScrollView {
    private var indicatorLengths: (horizontal: CGFloat, vertical: CGFloat) {
        let minIndicatorLength: CGFloat = 30.0
        return (
            horizontal: max(minIndicatorLength, (bounds.width / contentSize.width) * bounds.width),
            vertical: max(minIndicatorLength, (bounds.height / contentSize.height) * bounds.height)
        )
    }

    private var indicatorOffsetsInContentSpace: (horizontal: CGFloat, vertical: CGFloat) {
        let indicatorDistanceFromScrollViewFrame: CGFloat = 2.5

        let totalContentArea = (
            horizontal: contentInset.left + contentSize.width + contentInset.right,
            vertical: contentInset.top + contentSize.height + contentInset.bottom
        )

        let scrollViewProgress = (
            horizontal: (contentInset.left + contentOffset.x) / (totalContentArea.horizontal - bounds.width),
            vertical: (contentInset.top + contentOffset.y) / (totalContentArea.vertical - bounds.height)
        )

        let shouldShowBothIndicators = shouldLayoutHorizontalScrollIndicator && shouldLayoutVerticalScrollIndicator

        let additionalSpacingToPreventOverlap = (
            horizontal: shouldShowBothIndicators ? 2 * indicatorDistanceFromScrollViewFrame : 0,
            vertical: shouldShowBothIndicators ? indicatorDistanceFromScrollViewFrame : 0
        )

        let totalSpacingFromFrameSides = (
            horizontal: totalScrollIndicatorInsets.left + totalScrollIndicatorInsets.right + additionalSpacingToPreventOverlap.horizontal,
            vertical: totalScrollIndicatorInsets.bottom + totalScrollIndicatorInsets.top + additionalSpacingToPreventOverlap.vertical
        )

        let lengthOfAvailableSpaceForIndicators = (
            horizontal: bounds.width - (indicatorLengths.horizontal + totalSpacingFromFrameSides.horizontal),
            vertical: bounds.height - (indicatorLengths.vertical + totalSpacingFromFrameSides.vertical)
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

    private var shouldLayoutHorizontalScrollIndicator: Bool {
        return showsHorizontalScrollIndicator && contentSize.width > bounds.width
    }

    private var shouldLayoutVerticalScrollIndicator: Bool {
        return showsVerticalScrollIndicator && contentSize.height > bounds.height
    }

    internal func layoutScrollIndicatorsIfNeeded() {
        guard shouldLayoutHorizontalScrollIndicator || shouldLayoutVerticalScrollIndicator else { return }

        let distanceFromFrame = (
            horizontal: indicatorThickness + totalScrollIndicatorInsets.bottom,
            vertical: indicatorThickness + totalScrollIndicatorInsets.right
        )

        if shouldLayoutHorizontalScrollIndicator {
            horizontalScrollIndicator.frame = CGRect(
                x: totalScrollIndicatorInsets.left + indicatorOffsetsInContentSpace.horizontal,
                y: bounds.height + contentOffset.y - distanceFromFrame.horizontal,
                width: indicatorLengths.horizontal,
                height: indicatorThickness
            )
        }

        if shouldLayoutVerticalScrollIndicator {
            verticalScrollIndicator.frame = CGRect(
                x: bounds.width + contentOffset.x - distanceFromFrame.vertical,
                y: totalScrollIndicatorInsets.top + indicatorOffsetsInContentSpace.vertical,
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
