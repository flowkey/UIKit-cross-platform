//
//  CALayer+SDL.swift
//  UIKit
//
//  Created by Chris on 27.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import SDL

extension CALayer {
    final func sdlRender(at parentAbsoluteOrigin: CGPoint = .zero, parentOpacity: Float = 1) {
        let opacity = parentOpacity * self.opacity
        if isHidden || opacity < 0.01 { return }

        let absoluteFrame = frame.offsetBy(parentAbsoluteOrigin)
        
        // Big performance optimization. Don't render anything that's entirely offscreen:
        guard absoluteFrame.intersects(SDL.rootView.bounds) else { return }

        if let mask = mask, let maskContents = mask.contents {
            ShaderProgram.mask.activate()
            ShaderProgram.mask.set(maskImage: maskContents, frame: absoluteFrame) // must be set after activation
        }

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

        if let contents = contents {
            SDL.window.blit(
                contents,
                at: absoluteFrame.origin,
                scaleX: Float((1 / contentsScale) * transform.m11),
                scaleY: Float((1 / contentsScale) * transform.m22),
                opacity: opacity,
                clippingRect: (masksToBounds ? superlayer?.bounds : nil)
            )
        }

        if mask != nil {
            ShaderProgram.deactivateAll()
        }

        sublayers?.forEach {
            ($0.presentation ?? $0).sdlRender(
                at: absoluteFrame.origin.offsetBy(-bounds.origin),
                parentOpacity: opacity
            )
        }
    }
}
