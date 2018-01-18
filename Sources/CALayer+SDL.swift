//
//  CALayer+SDL.swift
//  UIKit
//
//  Created by Chris on 27.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL

extension CALayer {
    final func sdlRender(in parentAbsoluteFrame: CGRect = CGRect(), parentOpacity: Float = 1, clippingRect: CGRect?) {
        let opacity = parentOpacity * self.opacity
        if isHidden || opacity < 0.01 { return } // could be a hidden sublayer of a visible layer

        let absoluteFrame = frame.offsetBy(parentAbsoluteFrame.origin)
        
        // Big performance optimization. Don't render anything that's entirely offscreen:
        if !absoluteFrame.intersects(SDL.rootView.bounds) { return }

        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alpha.toNormalisedFloat()
            SDL.window.fill(
                absoluteFrame,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            SDL.window.outline(
                absoluteFrame,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                let absoluteShadowPath = shadowPath.offsetBy(absoluteFrame.origin)
                SDL.window.fill(
                    absoluteShadowPath,
                    with: shadowColor.withAlphaComponent(CGFloat(absoluteShadowOpacity)),
                    cornerRadius: 2
                )
            }
        }

        if let texture = texture {
            if transform.isIdentity {
                // Later use more advanced blit funcs (with rotation, scale etc)
                SDL.window.blit(texture, at: absoluteFrame.origin, opacity: opacity, clippingRect: clippingRect)
            } else {
                SDL.window.blitTransform(
                    texture,
                    at: absoluteFrame.origin,
                    opacity: opacity,
                    transform: transform
                )
            }
        }

        sublayers.forEach { ($0.presentation ?? $0).sdlRender(in: absoluteFrame.offsetBy(-bounds.origin), parentOpacity: opacity, clippingRect: clippingRect) }
    }
}
