//
//  UIView+SDL.swift
//  UIKit
//
//  Created by Geordie Jay on 17.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import SDL

extension UIView {
    final func sdlRender(in parentAbsoluteFrame: CGRect = CGRect(), parentAlpha: CGFloat = 1.0) {
        let visibleLayer = (layer.presentation ?? layer)
        
        let alpha = CGFloat(visibleLayer.opacity) * parentAlpha
        if visibleLayer.isHidden || alpha < 0.01 { return }

        if needsDisplay {
            draw()
            needsDisplay = false
        }

        if needsLayout {
            layoutSubviews()
            needsLayout = false
        }

        let absoluteFrame = visibleLayer.frame.offsetBy(parentAbsoluteFrame.origin).offsetBy(visibleLayer.bounds.origin)

        // Render layer and all sublayers
        layer.sdlRender(in: parentAbsoluteFrame, parentOpacity: Float(parentAlpha))

        // Render subviews and their sublayers
        subviews.forEach { $0.sdlRender(in: absoluteFrame, parentAlpha: alpha) }
    }
}

