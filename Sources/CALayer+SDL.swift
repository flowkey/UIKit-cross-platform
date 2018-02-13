//
//  CALayer+SDL.swift
//  UIKit
//
//  Created by Chris on 27.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import SDL
import SDL_gpu

extension CALayer {
    final func sdlRender(at parentAbsoluteOrigin: CGPoint = .zero, parentOpacity: Float = 1) {
        let opacity = parentOpacity * self.opacity
        if isHidden || opacity < 0.01 { return }

        // Make translate matrix, multiply by current matrix

        // XXXXXX `frame` already includes current transform, maybe we actually need bounds, position, anchorPoint?
//        let parentBoundsOrigin = superlayer?.bounds.origin ?? .zero
//        let offset = frame.offsetBy(-parentBoundsOrigin)


        // multiply that result by layer's transform
        // check that at least one of the points fall within UIScreen.main.bounds

        // absoluteFrame is then bounds, because of the transform that has been applied!!

        let absoluteFrame = frame.offsetBy(parentAbsoluteOrigin) // frame already includes transform

        // Big performance optimization. Don't render anything that's entirely offscreen:
        guard absoluteFrame.intersects(SDL.rootView.bounds) else { return }

        if let mask = mask, let maskContents = mask.contents {
            ShaderProgram.mask.activate() // must activate before setting parameters (below)!
            ShaderProgram.mask.set(maskImage: maskContents, frame: absoluteFrame)
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

        if transform != CATransform3DIdentity {
            transform.withUnsafeMutablePointer(GPU_MultMatrix)
        }

        if let contents = contents {
            SDL.window.blit(
                contents,
                at: absoluteFrame.origin,
                scaleX: Float(1 / contentsScale),
                scaleY: Float(1 / contentsScale),
                opacity: opacity,
                clippingRect: (masksToBounds ? superlayer?.bounds : nil)
            )
        }

        if mask != nil {
            ShaderProgram.deactivateAll()
        }

        sublayers?.forEach {
            var currentTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())

            ($0.presentation ?? $0).sdlRender(
                at: absoluteFrame.origin.offsetBy(-bounds.origin),
                parentOpacity: opacity
            )

            currentTransform.withUnsafeMutablePointer { currentTransformPointer in
                GPU_MatrixCopy(GPU_GetCurrentMatrix(), currentTransformPointer)
            }
        }
    }
}
