//
//  UIView+SDL.swift
//  UIKit
//
//  Created by Geordie Jay on 17.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import SDL

extension UIView {
    final func sdlDrawAndLayoutTreeIfNeeded(parentAlpha: CGFloat = 1.0) {
        let visibleLayer = (layer.presentation ?? layer)

        let alpha = CGFloat(visibleLayer.opacity) * parentAlpha
        if visibleLayer.isHidden || alpha < 0.01 { return }

        if needsDisplay {
            draw()
            needsDisplay = false
        }

        layoutIfNeeded()

        subviews.forEach { $0.sdlDrawAndLayoutTreeIfNeeded(parentAlpha: alpha) }
    }
}

