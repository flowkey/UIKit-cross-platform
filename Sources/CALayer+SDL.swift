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

        // The basis for all our transformations is `position` (in parent coordinates), which in this layer's
        // coordinates is `anchorPoint`. To make this happen, we translate (in our parent's coordinate system
        // – which may in turn be affected by its parents, and so on) to `position`, and then render rectangles
        // which may (and often do) start at a negative `origin` based on our (bounds) `size` and `anchorPoint`:
        let parentOriginTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())
        let translationToPosition = CATransform3DMakeTranslation(position.x, position.y, zPosition)
        let transformAtPositionInParentCoordinates = parentOriginTransform * translationToPosition

        let modelViewTransform = transformAtPositionInParentCoordinates * self.transform

        // Now that we're in our own coordinate system based around `anchorPoint` (which is generally the middle of
        // bounds.size), we need to find the top left of the rectangle in order to be able to render rectangles.
        // Since we have already applied our own `transform`, we can work in our own (`bounds.size`) units.
        let deltaFromAnchorPointToOrigin = CGPoint(
            x: -(bounds.width * anchorPoint.x),
            y: -(bounds.height * anchorPoint.y)
        )
        let renderedBoundsRelativeToAnchorPoint = CGRect(origin: deltaFromAnchorPointToOrigin, size: bounds.size)


        // Big performance optimization. Don't render anything that's entirely offscreen:
        let absoluteFrame = renderedBoundsRelativeToAnchorPoint.applying(modelViewTransform)
        guard absoluteFrame.intersects(SDL.window.bounds) else {
            return
        }

        self.hasBeenRenderedInThisPartOfOverallLayerHierarchy = true


        // We only actually set the transform here to avoid unneccesary work if the guard above fails
        modelViewTransform.setAsSDLgpuMatrix()
        defer { // Queue this up here in case we return before the actual end of the function
            // We'll be done rendering this part of the tree by the time this is called.
            // To render further siblings we need to return to our parent's transform (at its `origin`).
            parentOriginTransform.setAsSDLgpuMatrix()
        }

        let previousClippingRect = SDL.glRenderer.clippingRect

        if masksToBounds {
            // If a previous clippingRect exists restrict it further, otherwise just set it:
            SDL.glRenderer.clippingRect = previousClippingRect?.intersection(absoluteFrame) ?? absoluteFrame
        }

        if let mask = mask {
            //If a mask exists, take it into account when rendering by combining your absoluteFrame with the mask's frame
            
            let areaOfInterest = (mask._presentation ?? mask)
            
            let desiredOrigin = CGPoint(x: absoluteFrame.origin.x + areaOfInterest.frame.origin.x, y: absoluteFrame.origin.y + areaOfInterest.frame.origin.y)
            let desiredSize = areaOfInterest.frame.size
            let absoluteFrameOfMaskedArea = CGRect(origin: desiredOrigin, size: desiredSize)
            
            //Do not intersect with the previousClippingRect, because in a case where both masksToBounds and mask are present,
            //using previousClippingRect would not constrain the area further (or not constrain as much as it could)
            SDL.glRenderer.clippingRect = SDL.glRenderer.clippingRect?.intersection(absoluteFrameOfMaskedArea) ?? absoluteFrameOfMaskedArea

            if let maskContents = mask.contents {
                ShaderProgram.mask.activate() // must activate before setting parameters (below)!
                ShaderProgram.mask.set(maskImage: maskContents, frame: mask.bounds)
            }
        }
        
        defer {
            // Reset clipping bounds no matter what happens between now and the end of this function
            SDL.glRenderer.clippingRect = previousClippingRect
        }
        
        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alpha.toNormalisedFloat()
            SDL.glRenderer.fill(
                renderedBoundsRelativeToAnchorPoint,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            SDL.glRenderer.outline(
                renderedBoundsRelativeToAnchorPoint,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                SDL.glRenderer.fill(
                    shadowPath.offsetBy(deltaFromAnchorPointToOrigin),
                    with: shadowColor.withAlphaComponent(CGFloat(absoluteShadowOpacity)),
                    cornerRadius: 2
                )
            }
        }

        if let contents = contents {
            SDL.glRenderer.blit(
                contents,
                anchorPoint: anchorPoint,
                contentsScale: contentsScale,
                contentsGravity: ContentsGravityTransformation(for: self),
                opacity: opacity
            )
        }

        if mask != nil {
            ShaderProgram.deactivateAll()
        }

        if let sublayers = sublayers {
            // `position` is always relative from the parent's origin, but the global GPU matrix is currently
            // focused on `self.position` rather than the `origin` we calculated to render rectangles.
            // We need to be at `origin` here though so we can translate to the next `position` in each sublayer.
            //
            // We also subtract `bounds` to get the strange but useful scrolling effect as on iOS.
            let translationFromAnchorPointToOrigin = CATransform3DMakeTranslation(
                deltaFromAnchorPointToOrigin.x - bounds.origin.x,
                deltaFromAnchorPointToOrigin.y - bounds.origin.y,
                0 // If we moved (e.g.) forward to render `self`, all sublayers should start at the same zIndex
            )

            // This transform is referred to as the `parentOriginTransform` in our sublayers (see above):
            let transformAtSelfOrigin = modelViewTransform * translationFromAnchorPointToOrigin
            transformAtSelfOrigin.setAsSDLgpuMatrix()

            for sublayer in sublayers {
                (sublayer._presentation ?? sublayer).sdlRender(parentAbsoluteOpacity: opacity)
            }
        }

        // Defer blocks (above) reset the global `transform` and `clippingRect`s here
        // to those that were set before we started rendering `self`.
    }
}
