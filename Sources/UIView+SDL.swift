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

        if needsLayout {
            layoutSubviews()
            needsLayout = false
        }

        let absoluteFrame = frame.in(parentAbsoluteFrame).offsetBy(bounds.origin)

        // Render layer and all sublayers
        layer.sdlRender(in: parentAbsoluteFrame)

        // Render subviews and their sublayers
        subviews.forEach { $0.sdlRender(in: absoluteFrame) }
    }
}


extension CALayer {
    final func sdlRender(in parentAbsoluteFrame: CGRect = CGRect()) {
        if isHidden || opacity < 0.01 { return } // could be a hidden sublayer of a visible layer
        let absoluteFrame = frame.in(parentAbsoluteFrame).offsetBy(bounds.origin)

        // Big performance optimization. Don't render anything that's entirely offscreen.
        // Buggy
        let rootViewFrame = SDL.rootView.frame
        if
            absoluteFrame.minX > rootViewFrame.maxX || absoluteFrame.maxX < rootViewFrame.minX ||
            absoluteFrame.minY > rootViewFrame.maxY || absoluteFrame.maxY < rootViewFrame.minY {
            return
        }

        if let backgroundColor = backgroundColor {
            SDL.window.fill(absoluteFrame, with: backgroundColor, cornerRadius: cornerRadius)
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                let absoluteShadowPath = shadowPath.offsetBy(absoluteFrame.origin)
                SDL.window.fill(absoluteShadowPath, with: shadowColor.withAlphaComponent(absoluteShadowOpacity), cornerRadius: 2)
            }
        }

        if let texture = texture {
            // Later use more advanced blit funcs (with rotation, scale etc)
            SDL.window.blit(texture, to: absoluteFrame.origin)
        }

        sublayers.forEach { $0.sdlRender(in: absoluteFrame) }
    }
}
