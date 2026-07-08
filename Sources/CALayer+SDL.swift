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

        // We only actually set the transform here to avoid unneccesary work if the guard above fails.
        //
        // Draw this layer's fills (shadow / background / border) with the translation snapped to whole
        // device pixels, so abutting solid fills meet with no sub-pixel gap — which on Android shows the
        // dark area behind the background-less PlayerView as a thin black line. Content and sublayers
        // below restore the exact transform, so blitted images (e.g. the scrolling sheet) stay smooth.
        // (This closes fill-to-fill seams like the sheet/progress-bar; an image edge meeting a fill edge
        // isn't aligned this way.)
        renderer.pixelSnappingTranslation(of: modelViewTransform).setAsSDLgpuMatrix()


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

            if let maskContents = mask.contents {
                ShaderProgram.mask.activate() // must activate before setting parameters (below)!
                ShaderProgram.mask.set(maskImage: maskContents, frame: mask.bounds)
            }
        }

        // MARK: Drop shadow
        //
        // Core Animation draws a layer's shadow automatically on iOS; the SDL
        // renderer doesn't, so we render one here — a feathered fill drawn
        // *behind* the layer's own background, honouring shadowColor / Offset /
        // Radius / Opacity. When no explicit `shadowPath` is set we fall back to
        // the layer bounds (iOS shadows the layer's shape by default, and
        // `shadowPath` is only set under `#if os(iOS)` in our code).
        if let shadowColor = shadowColor, shadowOpacity > 0.01 {
            let shadowAlpha = shadowOpacity * opacity
            if shadowAlpha > 0.01 {
                let shadowShapeInRenderSpace = shadowPath?.offsetBy(deltaFromAnchorPointToOrigin)
                    ?? renderedBoundsRelativeToAnchorPoint
                renderer.shadow(
                    shadowShapeInRenderSpace.offsetBy(CGPoint(x: shadowOffset.width, y: shadowOffset.height)),
                    color: shadowColor.withAlphaComponent(CGFloat(shadowAlpha)),
                    cornerRadius: cornerRadius,
                    blurRadius: shadowRadius
                )
            }
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

        // Restore the exact (un-snapped) transform for this layer's content and its sublayers, so
        // blitted images and scrolling stay smooth (only the solid fills above are pixel-snapped).
        modelViewTransform.setAsSDLgpuMatrix()

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
