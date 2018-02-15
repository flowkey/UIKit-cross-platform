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
    final func sdlRender(parentOpacity: Float = 1) {
        let opacity = parentOpacity * self.opacity
        if isHidden || opacity < 0.01 { return }

        // Make translate matrix, multiply by current matrix
        // XXXXXX `frame` already includes current transform, maybe we actually need bounds, position, anchorPoint?
        let parentBoundsOrigin = superlayer?.bounds.origin ?? .zero
        let offset = frame.origin.offsetBy(-parentBoundsOrigin)

        let translation = CATransform3DMakeTranslation(offset.x, offset.y, 0)
        let parentTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())
        let parentTransformTranslatedByParentCoordinates = translation.concat(parentTransform)

        // multiply that result by layer's transform
        let modelViewTransform = parentTransformTranslatedByParentCoordinates.concat(self.transform)
        modelViewTransform.setAsSDLgpuMatrix()

        // check that at least one of the points fall within UIScreen.main.bounds

        // absoluteFrame is now bounds, because of the transform that has been applied!!
        if SDL.window.printThisLoop {
            let transformedBounds = bounds.applying(modelViewTransform)
            print(self.delegate ?? self)
            print(transformedBounds)
            print("-----------------------------------------")
        }

        // Big performance optimization. Don't render anything that's entirely offscreen:
//        guard absoluteFrame.intersects(SDL.rootView.bounds) else { return }

        if let mask = mask, let maskContents = mask.contents {
            ShaderProgram.mask.activate() // must activate before setting parameters (below)!
            ShaderProgram.mask.set(maskImage: maskContents, frame: mask.bounds)
        }

        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alpha.toNormalisedFloat()
            SDL.window.fill(
                bounds,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            SDL.window.outline(
                bounds,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                SDL.window.fill(
                    shadowPath,
                    with: shadowColor.withAlphaComponent(CGFloat(absoluteShadowOpacity)),
                    cornerRadius: 2
                )
            }
        }

        if let contents = contents {
            SDL.window.blit(
                contents,
                at: .zero,
                scaleX: Float(1 / contentsScale),
                scaleY: Float(1 / contentsScale),
                opacity: opacity,
                clippingRect: (masksToBounds ? superlayer?.bounds : nil)
            )
        }

        if mask != nil {
            ShaderProgram.deactivateAll()
        }

        GPU_FlushBlitBuffer()

        sublayers?.forEach {
            ($0.presentation ?? $0).sdlRender(parentOpacity: opacity)
        }

        // Remove current transform from the stack
        parentTransform.setAsSDLgpuMatrix()
        GPU_FlushBlitBuffer()
    }
}
