//
//  UIView+SDL.swift
//  UIKit
//
//  Created by Geordie Jay on 17.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import SDL

extension UIView {
    final func sdlRender(
        in parentAbsoluteFrame: CGRect = CGRect(),
        parentAlpha: CGFloat = 1.0
    ) {
        let alpha = self.alpha * parentAlpha
        if isHidden || alpha < 0.01 { return }

        if needsDisplay {
            draw()
            needsDisplay = false
        }

        if needsLayout {
            layoutSubviews()
            needsLayout = false
        }

        // Render layer and all sublayers
        layer.sdlRender(
            in: parentAbsoluteFrame.offsetBy(-bounds.origin),
            parentOpacity: Float(parentAlpha),
            // clip to superView bounds when clipsToBounds is truthy
            clip: ((superview?.clipsToBounds ?? false) ? superview?.bounds : nil)
        )

        // Render subviews and their sublayers
        let absoluteFrame = frame.offsetBy(parentAbsoluteFrame.origin)
        subviews.forEach { $0.sdlRender(
            in: absoluteFrame.offsetBy(-bounds.origin),
            parentAlpha: alpha
        ) }
    }
}

