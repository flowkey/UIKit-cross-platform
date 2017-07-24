//
//  CALayer+SDL.swift
//  UIKit
//
//  Created by Chris on 27.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

extension CALayer {
    final func sdlRender(in parentAbsoluteFrame: CGRect = CGRect()) {
        // UIView.animate updates the animated properties to their final value immediately
        // presentation() represents the state of the animation
        let layerForRender = presentation() ?? self

        if isHidden || opacity < 0.01 { return } // could be a hidden sublayer of a visible layer
        let absoluteFrame = layerForRender.frame.offsetBy(parentAbsoluteFrame.origin).offsetBy(bounds.origin)
        
        // Big performance optimization. Don't render anything that's entirely offscreen:
        if !absoluteFrame.intersects(SDL.rootView.bounds) { return }

        if let backgroundColor = backgroundColor {
            let opacity = layerForRender.opacity * backgroundColor.alpha.toNormalisedCGFloat()
            SDL.window.fill(absoluteFrame, with: backgroundColor.withAlphaComponent(opacity), cornerRadius: cornerRadius)
        }

        if borderWidth > 0 {
            SDL.window.outline(absoluteFrame, lineColor: borderColor, lineThickness: borderWidth, cornerRadius: cornerRadius)
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
