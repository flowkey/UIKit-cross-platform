//
//  UIScreen+render.swift
//  UIKit
//
//  Created by Chris on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL
internal import SDL_gpu

extension UIScreen {
    @MainActor
    func render(window: UIWindow?, atTime frameTimer: Timer) {
        guard let window = window else {
            print("Not rendering because `window` was `nil`")
            return
        }

        DisplayLink.activeDisplayLinks.forEach { $0.callback() }
        UIView.animateIfNeeded(at: frameTimer)
        // XXX: It's possible for drawing to crash if the context is invalid:
        window.sdlDrawAndLayoutTreeIfNeeded()

        guard CALayer.layerTreeIsDirty else {
            // Nothing changed, so we can leave the existing image on the screen.
            return
        }

        // Layer tree can be made dirty again in layer.sdlRender
        // So set this here and only reset it if the .flip fails
        CALayer.layerTreeIsDirty = false

        self.clear()
        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_LoadIdentity()

        self.clippingRect = window.bounds
        window.layer.sdlRender()

        do {
            try self.flip()
        } catch {
            CALayer.layerTreeIsDirty = true
            assertionFailure("UIScreen failed to render. This shouldn't happen anymore since we added more error handling when rendering the layer tree! Error: \(error)")
        }
    }

    func blit(
        _ image: CGImage,
        anchorPoint: CGPoint,
        contentsScale: CGFloat,
        contentsGravity: ContentsGravityTransformation,
        opacity: Float
    ) throws {
        GPU_SetAnchor(image.rawPointer, Float(anchorPoint.x), Float(anchorPoint.y))
        GPU_SetRGBA(image.rawPointer, 255, 255, 255, opacity.normalisedToUInt8())

        GPU_BlitTransform(
            image.rawPointer,
            nil,
            self.rawPointer,
            Float(contentsGravity.offset.x),
            Float(contentsGravity.offset.y),
            0, // rotation in degrees
            Float(contentsGravity.scale.width / contentsScale),
            Float(contentsGravity.scale.height / contentsScale)
        )

        try throwOnErrors(ofType: [GPU_ERROR_USER_ERROR])
    }

    func setShapeBlending(_ newValue: Bool) {
        GPU_SetShapeBlending(newValue)
    }

    func setShapeBlendMode(_ newValue: GPU_BlendPresetEnum) {
        GPU_SetShapeBlendMode(newValue)
    }

    func clear() {
        GPU_Clear(rawPointer)
    }

    func fill(_ rect: CGRect, with color: UIColor, cornerRadius: CGFloat) {
        if cornerRadius >= 1 {
            let snappedRect = pixelSnapped(rect)
            let previousProgram = ShaderProgram.currentlyActive
            ShaderProgram.roundedRect.activate()
            ShaderProgram.roundedRect.setFill(rect: snappedRect, cornerRadius: cornerRadius)
            GPU_RectangleFilled(rawPointer, roundedShaderQuad(for: snappedRect), color: color.sdlColor)
            restoreShaderProgram(previousProgram)
        } else {
            GPU_RectangleFilled(rawPointer, gpuRect(rect), color: color.sdlColor)
        }
    }

    /// Draw a feathered drop shadow: opaque inside `shapeRect`, fading to zero over `blurRadius`
    /// pixels outside it (and up over the same distance inside). The draw quad is expanded by
    /// `blurRadius` so the feathered edge isn't clipped.
    func shadow(_ shapeRect: CGRect, color: UIColor, cornerRadius: CGFloat, blurRadius: CGFloat) {
        let previousProgram = ShaderProgram.currentlyActive
        ShaderProgram.shadow.activate()
        ShaderProgram.shadow.setShadow(rect: shapeRect, cornerRadius: cornerRadius, blurRadius: blurRadius)
        GPU_RectangleFilled(rawPointer, gpuRect(shapeRect.insetBy(dx: -blurRadius, dy: -blurRadius)), color: color.sdlColor)
        restoreShaderProgram(previousProgram)
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat) {
        // we want to render the outline 'inside' the rect rather
        // than exceeding the bounds when lineThickness is bigger than 1
        let offset = lineThickness / 2
        let scaledGpuRect = gpuRect(CGRect(
            x: rect.origin.x + offset,
            y: rect.origin.y + offset,
            width: rect.size.width - offset,
            height: rect.size.height - offset
        ))

        GPU_SetLineThickness(Float(lineThickness))
        GPU_Rectangle(rawPointer, scaledGpuRect, color: lineColor.sdlColor)
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat, cornerRadius: CGFloat) {
        if cornerRadius > 1 {
            // SDF ring: stroke is drawn from the rect boundary inward by `lineThickness`,
            // which matches CSS/iOS "border" semantics.
            let snappedRect = pixelSnapped(rect)
            let previousProgram = ShaderProgram.currentlyActive
            ShaderProgram.roundedRect.activate()
            ShaderProgram.roundedRect.setStroke(rect: snappedRect, cornerRadius: cornerRadius, borderWidth: lineThickness)
            GPU_RectangleFilled(rawPointer, roundedShaderQuad(for: snappedRect), color: lineColor.sdlColor)
            restoreShaderProgram(previousProgram)
        } else {
            outline(rect, lineColor: lineColor, lineThickness: lineThickness)
        }
    }

    private func restoreShaderProgram(_ program: ShaderProgram?) {
        if let program = program {
            program.activate()
        } else {
            ShaderProgram.deactivateAll()
        }
    }

    func flip() throws {
        GPU_Flip(rawPointer)
        try throwOnErrors(ofType: [GPU_ERROR_USER_ERROR, GPU_ERROR_BACKEND_ERROR])
    }

    // Called when clippingRect was set.
    // The function is separated out because that stored property can't be in this extension.
    func didSetClippingRect() {
        guard let clippingRect = clippingRect else {
            return GPU_UnsetClip(rawPointer)
        }

        GPU_SetClipRect(rawPointer, gpuRect(clippingRect))
    }
}

private extension UIScreen {
    /// The GPU target's device-pixel ratio per axis (drawable / target). Per-axis because a single
    /// `UIScreen.scale` is wrong when the two axes round differently at fractional densities.
    var deviceScale: (x: CGFloat, y: CGFloat) {
        (CGFloat(rawPointer.pointee.context.pointee.drawable_w) / CGFloat(rawPointer.pointee.w),
         CGFloat(rawPointer.pointee.context.pointee.drawable_h) / CGFloat(rawPointer.pointee.h))
    }

    func snapToPixel(_ value: CGFloat, scale: CGFloat) -> CGFloat {
        (value * scale).rounded() / scale
    }

    // Snap a rounded-rect's *edges* to physical pixels (only the SDF path uses this). The edges are
    // snapped in *screen* space — the shape's on-screen position is `rect` plus the current model-view
    // translation, and the sub-pixel part usually lives in that translation, so we fold it in, snap,
    // then subtract it back to return a local rect. With the shader's centred anti-aliasing, a straight
    // edge landing on a physical pixel line keeps every pixel centre out of the fade band, so the edge
    // stays crisp and two abutting fills land on the same line with no backdrop seam — and identically
    // regardless of where the menu sits. The corner arcs still cross pixel centres and get the fade.
    // Nothing else is snapped: plain fills, clip rects and content/animation keep their exact positions.
    func pixelSnapped(_ rect: CGRect) -> CGRect {
        let modelViewTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())
        let translationX = CGFloat(modelViewTransform.m41)
        let translationY = CGFloat(modelViewTransform.m42)
        let scale = deviceScale

        let left = snapToPixel(rect.minX + translationX, scale: scale.x) - translationX
        let top = snapToPixel(rect.minY + translationY, scale: scale.y) - translationY
        let right = snapToPixel(rect.maxX + translationX, scale: scale.x) - translationX
        let bottom = snapToPixel(rect.maxY + translationY, scale: scale.y) - translationY
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    // The rounded-rect shader's centred anti-aliasing straddles the boundary, so the fade extends ~half
    // a device pixel *outside* `rect`. Grow the draw quad by one device pixel per side so that outer
    // half of the fade has fragments to shade; the SDF still uses the original `rect`, so the extra
    // fragments shade to zero and the shape isn't enlarged.
    func roundedShaderQuad(for rect: CGRect) -> GPU_Rect {
        let scale = deviceScale
        return gpuRect(rect.insetBy(dx: -1 / scale.x, dy: -1 / scale.y))
    }

    // Straight conversion into GPU (point) coordinates — no pixel snapping. Coordinates pass through
    // exactly so abutting fills share the same edge and animating/scrolling content stays smooth.
    func gpuRect(_ rect: CGRect) -> GPU_Rect {
        GPU_Rect(x: Float(rect.minX), y: Float(rect.minY), w: Float(rect.width), h: Float(rect.height))
    }
}
