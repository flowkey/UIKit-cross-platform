//
//  CALayer+SDL.swift
//  UIKit
//
//  Created by Chris on 27.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL_gpu

extension CALayer {
    final func sdlRender(parentAbsoluteOpacity: Float = 1) {
        let opacity = self.opacity * parentAbsoluteOpacity
        if isHidden || opacity < 0.01 { return }

        let parentTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())
        let matrixAtPosition = parentTransform * CATransform3DMakeTranslation(position.x, position.y, zPosition)
        let modelViewTransform = matrixAtPosition * transform
        modelViewTransform.setAsSDLgpuMatrix()


        // Untransformed origin in own coordinates
        let origin = CGPoint(
            x: -(bounds.width * anchorPoint.x),
            y: -(bounds.height * anchorPoint.y)
        )

        let rect = CGRect(origin: origin, size: bounds.size)

        // Big performance optimization. Don't render anything that's entirely offscreen:
//        guard absoluteFrame.intersects(SDL.rootView.bounds) else { return }

        if SDL.window.printThisLoop {
            print("--------------------------------")
            print(self.delegate ?? self)
            print(modelViewTransform)
            print(rect)
            print()
        }

        if let mask = mask, let maskContents = mask.contents {
            ShaderProgram.mask.activate() // must activate before setting parameters (below)!
            ShaderProgram.mask.set(maskImage: maskContents, frame: mask.bounds)
        }

        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alpha.toNormalisedFloat()
            SDL.window.fill(
                rect,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            SDL.window.outline(
                rect,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                SDL.window.fill(
                    shadowPath.offsetBy(origin),
                    with: shadowColor.withAlphaComponent(CGFloat(absoluteShadowOpacity)),
                    cornerRadius: 2
                )
            }
        }

        if let contents = contents {
            let gravityScale = contentsScaleForGravity()
            SDL.window.blit(
                contents,
                anchorPoint: anchorPoint,
                scaleX: Float(gravityScale.x / contentsScale),
                scaleY: Float(gravityScale.y / contentsScale),
                opacity: opacity,
                clippingRect: (masksToBounds ? superlayer?.bounds : nil)
            )
        }

        if mask != nil {
            ShaderProgram.deactivateAll()
        }

        if let sublayers = sublayers {
            // We have to put the absolute translation matrix back to `origin` so we can translate to the next `position` in the sublayers
            // We subtract `bounds` as usual to get the scrolling effect.
            let matrixAtFrameOrigin = modelViewTransform * CATransform3DMakeTranslation(origin.x - bounds.origin.x, origin.y - bounds.origin.y, -zPosition)
            matrixAtFrameOrigin.setAsSDLgpuMatrix()

            for sublayer in sublayers {
                (sublayer.presentation ?? sublayer).sdlRender(parentAbsoluteOpacity: opacity)
            }
        }

        // Essentially pops any transforms we added from the transform stack and returns to where we started
        parentTransform.setAsSDLgpuMatrix()
    }

    private func contentsScaleForGravity() -> (x: CGFloat, y: CGFloat) {
        let scaledContentsSize = CGSize(
            width: contents!.size.width / contentsScale,
            height: contents!.size.height / contentsScale
        )

        switch contentsGravity {
        case "resize":
            return (bounds.width / scaledContentsSize.width, bounds.height / scaledContentsSize.height)
        case "resizeAspectFill":
            let scale = max(bounds.width / scaledContentsSize.width, bounds.height / scaledContentsSize.height)
            return (scale, scale)
        case "resizeAspect":
            let scale = min(bounds.width / scaledContentsSize.width, bounds.height / scaledContentsSize.height)
            return (scale, scale)
        case "center":
            fallthrough // this is what we normally do anyway:
        default:
            return (1.0, 1.0)
        }
    }
}
