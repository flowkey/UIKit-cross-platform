internal import SDL_gpu

extension CALayer {
    @MainActor
    final func sdlRender(parentAbsoluteOpacity: Float = 1, renderTarget: RenderTarget) {
        let renderTarget = self.renderTarget ?? renderTarget
        let opacity = self.opacity * parentAbsoluteOpacity
        if isHidden || opacity < 0.01 { return }

        // The basis for all our transformations is `position` (in parent coordinates), which in this layer's
        // coordinates is `anchorPoint`. To make this happen, we translate (in our parent's coordinate system
        // – which may in turn be affected by its parents, and so on) to `position`, and then render rectangles
        // which may (and often do) start at a negative `origin` based on our (bounds) `size` and `anchorPoint`:
        let parentOriginTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())

        let translationToPosition = CATransform3DMakeTranslation(position.x, position.y, zPosition)
        let transformAtPositionInParentCoordinates = (
            self.renderTarget == nil ?
            parentOriginTransform :
            CATransform3DMakeTranslation(0, 0, 0) // start from (0,0) TODO: should this be based on layer.bounds?
        ) * translationToPosition

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
        guard absoluteFrame.intersects(renderTarget.bounds) else {
            return
        }

        self.hasBeenRenderedInThisPartOfOverallLayerHierarchy = true

        // We only actually set the transform here to avoid unneccesary work if the guard above fails
        modelViewTransform.setAsSDLgpuMatrix()


        // MARK: Masking / clipping rect

        let previousClippingRect = renderTarget.clippingRect

        if masksToBounds {
            // If a previous clippingRect exists restrict it further, otherwise just set it:
            renderTarget.clippingRect = previousClippingRect?.intersection(absoluteFrame) ?? absoluteFrame
        }

        // If a mask exists, take it into account when rendering by combining absoluteFrame with the mask's frame
        if let mask {
            let maskFrame = (mask.presentation() ?? mask).frame
            let maskAbsoluteFrame = maskFrame.offsetBy(absoluteFrame.origin)

            // Don't intersect with previousClippingRect: in a case where both `masksToBounds` and `mask` are
            // present, using previousClippingRect would not constrain the area as much as it might otherwise
            renderTarget.clippingRect =
            renderTarget.clippingRect?.intersection(maskAbsoluteFrame) ?? maskAbsoluteFrame

            if mask.needsDisplay() {
                mask.display()
                mask._needsDisplay = false
            }
            // the actual mask contents get applied separately during compositing
        }

        if let backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alphaValue.toNormalisedFloat()
            renderTarget.fill(
                renderedBoundsRelativeToAnchorPoint,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            renderTarget.outline(
                renderedBoundsRelativeToAnchorPoint,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                renderTarget.fill(
                    shadowPath.offsetBy(deltaFromAnchorPointToOrigin),
                    with: shadowColor.withAlphaComponent(CGFloat(absoluteShadowOpacity)),
                    cornerRadius: 2
                )
            }
        }

        if needsDisplay() {
            display()
            _needsDisplay = false
        }

        if let contents {
            do {
                try renderTarget.blit(
                    contents,
                    anchorPoint: anchorPoint,
                    contentsScale: contentsScale,
                    contentsGravity: ContentsGravityTransformation(for: self),
                    // if we have a render target, opacity is applied on blit below
                    opacity: self.renderTarget == nil ? opacity : 1
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

        if let sublayers {
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
                let layer = sublayer.presentation() ?? sublayer
                layer.sdlRender(parentAbsoluteOpacity: opacity, renderTarget: renderTarget)

                // A layer will render its subtree to a separate target if
                // it e.g. contains a mask or has a non-zero opacity.
                // This allows us to render the entire subtree and then apply
                // the opacity / mask to everything and not just the base layer.
                if let subtreeRenderTarget = layer.renderTarget {
                    if let mask = layer.mask, let maskContents = mask.contents {
                        ShaderProgram.maskCompositor.activate() // must activate before setting parameters
                        ShaderProgram.maskCompositor.set(maskImage: maskContents)
                    }
                    do {
                        try renderTarget.blit(
                            renderTarget: subtreeRenderTarget,
                            opacity: layer.opacity
                        )
                        subtreeRenderTarget.clear()
                    } catch {
                        print(error)
                    }

                    if layer.mask?.contents != nil {
                        ShaderProgram.deactivateAll()
                    }
                }
            }
        }

        // We're done rendering this part of the tree
        // To render further siblings we need to return to our parent's transform (at its `origin`).
        parentOriginTransform.setAsSDLgpuMatrix()
        renderTarget.clippingRect = previousClippingRect
    }
}
