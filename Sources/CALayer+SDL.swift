//
//  CALayer+SDL.swift
//  UIKit
//
//  Created by Chris on 27.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL_gpu

extension CALayer {
    @MainActor
    final func sdlRender(parentAbsoluteOpacity: Float = 1) {
        guard let renderer = UIScreen.main else { return }
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
        guard absoluteFrame.intersects(renderer.bounds) else {
            return
        }

        self.hasBeenRenderedInThisPartOfOverallLayerHierarchy = true

        // We only actually set the transform here to avoid unneccesary work if the guard above fails
        modelViewTransform.setAsSDLgpuMatrix()


        // MARK: Masking / clipping rect

        let previousClippingRect = renderer.clippingRect

        if masksToBounds {
            // If a previous clippingRect exists restrict it further, otherwise just set it:
            renderer.clippingRect = previousClippingRect?.intersection(absoluteFrame) ?? absoluteFrame
        }

        // If a mask exists, take it into account when rendering by combining absoluteFrame with the mask's frame
        if let mask = mask {
            // XXX: we're probably not doing exactly what iOS does if there is a transform on here somewhere
            let maskFrame = (mask._presentation ?? mask).frame
            let maskAbsoluteFrame = maskFrame.offsetBy(absoluteFrame.origin)

            // Don't intersect with previousClippingRect: in a case where both `masksToBounds` and `mask` are
            // present, using previousClippingRect would not constrain the area as much as it might otherwise
            renderer.clippingRect =
                renderer.clippingRect?.intersection(maskAbsoluteFrame) ?? maskAbsoluteFrame

            // The mask isn't in the sublayer tree, so render it here to populate its `contents`.
            if mask.contentsScale != contentsScale { mask.contentsScale = contentsScale }
            if mask.needsDisplay() { mask.display(); mask._needsDisplay = false }

            if let maskContents = mask.contents {
                // Use the image-sampling mask shader only when this layer has its own texture to mask;
                // otherwise the colour-masking shader (unchanged) handles solid-colour layers.
                let maskProgram = contents != nil ? ShaderProgram.maskImage : ShaderProgram.mask
                let maskShaderFrame = maskFrame.offsetBy(deltaFromAnchorPointToOrigin)
                maskProgram.activate() // must activate before setting parameters (below)!
                maskProgram.set(maskImage: maskContents, frame: maskShaderFrame)
            }
        }

        // Core Animation draws a layer's shadow automatically on iOS; the SDL renderer doesn't, so we
        // render a feathered fill *behind* the layer's own background, honouring shadowColor / Offset /
        // Radius / Opacity and shadowPath. The shadow follows `shadowPath` if set (its own rect and
        // corner radius, given in the layer's coordinate space), otherwise the layer's rounded bounds.
        let shadowAlpha = shadowColor == nil ? 0 : shadowOpacity * opacity
        if let shadowColor, shadowAlpha > 0.01 {
            let shadowShape = shadowPath?.boundingBox.offsetBy(deltaFromAnchorPointToOrigin) ?? renderedBoundsRelativeToAnchorPoint
            renderer.shadow(
                shadowShape.offsetBy(CGPoint(x: shadowOffset.width, y: shadowOffset.height)),
                color: shadowColor.withAlphaComponent(CGFloat(shadowAlpha)),
                cornerRadius: shadowPath?.cornerRadius ?? cornerRadius,
                blurRadius: shadowRadius
            )
        }

        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alphaValue.toNormalisedFloat()
            renderer.fill(
                renderedBoundsRelativeToAnchorPoint,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            renderer.outline(
                renderedBoundsRelativeToAnchorPoint,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if needsDisplay() {
            display()
            _needsDisplay = false
        }

        if let contents = contents {
            do {
                try renderer.blit(
                    contents,
                    anchorPoint: anchorPoint,
                    contentsScale: contentsScale,
                    contentsGravity: ContentsGravityTransformation(for: self),
                    opacity: opacity
                )
            } catch {
                // Try to recreate contents from source data if it exists
                if contents.reloadFromSourceData() == false {
                    // That failed, rely on the layer to re-render itself:
                    self.contents = nil
                    self.setNeedsDisplay()
                }
            }
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
                0 // If we moved (e.g.) forward to render `self`, all sublayers should start at that same zIndex
            )

            // This transform is referred to as the `parentOriginTransform` in our sublayers (see above):
            let transformAtSelfOrigin = modelViewTransform * translationFromAnchorPointToOrigin
            transformAtSelfOrigin.setAsSDLgpuMatrix()

            for sublayer in sublayers {
                (sublayer._presentation ?? sublayer).sdlRender(parentAbsoluteOpacity: opacity)
            }
        }

        // We're done rendering this part of the tree
        // To render further siblings we need to return to our parent's transform (at its `origin`).
        parentOriginTransform.setAsSDLgpuMatrix()

        renderer.clippingRect = previousClippingRect
    }
}
