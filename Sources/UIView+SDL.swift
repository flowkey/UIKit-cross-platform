//
//  UIView+SDL.swift
//  UIKit
//
//  Created by Geordie Jay on 17.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL

extension UIView {
    final func sdlDrawAndLayoutTreeIfNeeded(parentAlpha: CGFloat = 1.0) {
        let visibleLayer = (layer.presentation() ?? layer)

        let alpha = CGFloat(visibleLayer.opacity) * parentAlpha
        if visibleLayer.isHidden || alpha < 0.01 { return }

        if visibleLayer._needsDisplay {
            visibleLayer.display()
            visibleLayer._needsDisplay = false
        }

        if needsDisplay {
            draw()
            needsDisplay = false
        }

        if visibleLayer.mask?.needsDisplay() == true {
            visibleLayer.mask?.display()
            visibleLayer.mask?._needsDisplay = false
        }

        layoutIfNeeded()

        subviews.forEach { $0.sdlDrawAndLayoutTreeIfNeeded(parentAlpha: alpha) }
    }
}
