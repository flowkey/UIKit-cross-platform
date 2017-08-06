//
//  UIView+SDL.swift
//  UIKit
//
//  Created by Geordie Jay on 17.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import SDL

extension UIView {
    final func sdlRender(in parentAbsoluteFrame: CGRect = CGRect()) {
        if isHidden || alpha < 0.01 { return }

        if needsDisplay {
            draw()
            needsDisplay = false
        }

        if needsLayout {
            layoutSubviews()
            needsLayout = false
        }

        let visibleLayer = (layer.presentation ?? layer)
        let absoluteFrame = visibleLayer.frame.offsetBy(parentAbsoluteFrame.origin).offsetBy(visibleLayer.bounds.origin)

        // Render layer and all sublayers
        visibleLayer.sdlRender(in: parentAbsoluteFrame)

        // Render subviews and their sublayers
        subviews.forEach { $0.sdlRender(in: absoluteFrame) }
    }
}

