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
        guard let renderer = UIApplication.shared?.glRenderer else { return }
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
        guard absoluteFrame.intersects(UIScreen.main.bounds) else {
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

            if let maskContents = mask.contents {
                ShaderProgram.mask.activate() // must activate before setting parameters (below)!
                ShaderProgram.mask.set(maskImage: maskContents, frame: mask.bounds)
            }
        }

        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alpha.toNormalisedFloat()
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

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                renderer.fill(
                    shadowPath.offsetBy(deltaFromAnchorPointToOrigin),
                    with: shadowColor.withAlphaComponent(CGFloat(absoluteShadowOpacity)),
                    cornerRadius: 2
                )
            }
        }

        if let contents = contents {
            renderer.blit(
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

        // We're done rendering this part of the tree
        // To render further siblings we need to return to our parent's transform (at its `origin`).
        parentOriginTransform.setAsSDLgpuMatrix()

        renderer.clippingRect = previousClippingRect
    }
}
