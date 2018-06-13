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

    internal func indicatorOffsetsInContentSpace() -> (horizontal: CGFloat, vertical: CGFloat) {
        let totalContentArea = (
            horizontal: contentInset.left + contentSize.width + contentInset.right,
            vertical: contentInset.top + contentSize.height + contentInset.bottom
        )

        let scrollViewProgress = (
            horizontal: (contentInset.left + contentOffset.x) / totalContentArea.horizontal,
            vertical: (contentInset.top + contentOffset.y) / totalContentArea.vertical
        )

        let indicatorOffsetInAvailableSpace = (
            horizontal: scrollViewProgress.horizontal * (bounds.size.width - (totalScrollIndicatorInsets.left + totalScrollIndicatorInsets.right)),
            vertical: scrollViewProgress.vertical * (bounds.size.height - (totalScrollIndicatorInsets.top + totalScrollIndicatorInsets.bottom))
        )

        return (
            horizontal: contentOffset.x  + totalScrollIndicatorInsets.left + indicatorOffsetInAvailableSpace.horizontal,
            vertical: contentOffset.y + totalScrollIndicatorInsets.top + indicatorOffsetInAvailableSpace.vertical
        )
    }

    internal var shouldLayoutHorizontalScrollIndicator: Bool {
        return showsHorizontalScrollIndicator && contentSize.width > bounds.width
    }

    internal var shouldLayoutVerticalScrollIndicator: Bool {
        return showsVerticalScrollIndicator && contentSize.height > bounds.height
    }


    internal func layoutScrollIndicatorsIfNeeded() {
        guard shouldLayoutHorizontalScrollIndicator || shouldLayoutVerticalScrollIndicator else { return }


        let indicatorOffsets = indicatorOffsetsInContentSpace()
        let indicatorLengths = (horizontal: (bounds.width / contentSize.width) * bounds.width,
                                vertical: (bounds.height / contentSize.height) * bounds.height)

        if shouldLayoutHorizontalScrollIndicator {
            horizontalScrollIndicator.frame = CGRect(
                x: indicatorOffsets.horizontal,
                y: bounds.height - (2*indicatorThickness),
                width: indicatorLengths.horizontal,
                height: indicatorThickness
            )
        }

        if shouldLayoutVerticalScrollIndicator { // |
            verticalScrollIndicator.frame = CGRect(
                x: bounds.width - (2*indicatorThickness),
                y: indicatorOffsets.vertical,
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
