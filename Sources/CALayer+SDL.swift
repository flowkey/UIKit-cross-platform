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

        let deltaFromAnchorPointToOrigin = CGPoint(
            x: -(bounds.width * anchorPoint.x),
            y: -(bounds.height * anchorPoint.y)
        )

        let renderedBoundsRelativeToAnchorPoint = CGRect(origin: deltaFromAnchorPointToOrigin, size: bounds.size)

        // Big performance optimization. Don't render anything that's entirely offscreen:
        let absoluteFrame = renderedBoundsRelativeToAnchorPoint.applying(modelViewTransform)
        guard absoluteFrame.intersects(SDL.rootView.bounds) else { return }

        let previousClippingRect = SDL.window.clippingRect
        if masksToBounds {
            // If a previous one exists restrict it further, otherwise just set it:
            SDL.window.clippingRect = previousClippingRect?.intersection(absoluteFrame) ?? absoluteFrame
        }

        if SDL.window.printThisLoop {
            print("--------------------------------")
            print(self.delegate ?? self)
            print(modelViewTransform)
            print(renderedBoundsRelativeToAnchorPoint)
            print()
        }

        if let mask = mask, let maskContents = mask.contents {
            ShaderProgram.mask.activate() // must activate before setting parameters (below)!
            ShaderProgram.mask.set(maskImage: maskContents, frame: mask.bounds)
        }

        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alpha.toNormalisedFloat()
            SDL.window.fill(
                renderedBoundsRelativeToAnchorPoint,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            SDL.window.outline(
                renderedBoundsRelativeToAnchorPoint,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                SDL.window.fill(
                    shadowPath.offsetBy(deltaFromAnchorPointToOrigin),
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
                offset: contentsOffsetForGravity()
            )
        }

        if mask != nil {
            ShaderProgram.deactivateAll()
        }

        if let sublayers = sublayers {
            // `position` is always relative from the parent's origin, but the global GPU matrix is currently
            // focused on `self.position` rather than `self.origin` (which in turn is relative to `anchorPoint`).
            // Translating back to `origin` here allows us to translate to the next `position` in each sublayer.
            //
            // We also subtract `bounds` to get the scrolling effect as usual.
            let translationFromAnchorPointToOrigin = CATransform3DMakeTranslation(
                deltaFromAnchorPointToOrigin.x - bounds.origin.x,
                deltaFromAnchorPointToOrigin.y - bounds.origin.y,
                -zPosition // XXX: not sure if this is correct
            )

            let matrixAtFrameOrigin = modelViewTransform * translationFromAnchorPointToOrigin
            matrixAtFrameOrigin.setAsSDLgpuMatrix()

            for sublayer in sublayers {
                (sublayer.presentation ?? sublayer).sdlRender(parentAbsoluteOpacity: opacity)
            }
        }

        if masksToBounds {
            SDL.window.clippingRect = previousClippingRect
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
        case "left", "center", "right": // we don't scale for these values
            return (1.0, 1.0)
        default:
            preconditionFailure("Tried to render a cgImage with an unimplemented contentsGravity value")
        }
    }

    private func contentsOffsetForGravity() -> CGPoint {
        switch contentsGravity {
        case "resize", "resizeAspectFill", "resizeAspect", "center":
            return .zero // centred
        case "left":
            let scaledWidth = (contents!.size.width / contentsScale)
            let distanceToMinX = -(bounds.width - scaledWidth) * anchorPoint.x
            return CGPoint(x: distanceToMinX, y: 0.0)
        case "right":
            let distanceToMaxX = bounds.width * (1 - anchorPoint.x)
            let scaledWidth = (contents!.size.width / contentsScale)
            return CGPoint(x: distanceToMaxX - scaledWidth, y: 0.0)
        default:
            preconditionFailure("Tried to render a cgImage with an unimplemented contentsGravity value")
        }
    }
}
