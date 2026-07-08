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

    /// Snap only a transform's translation (m41/m42) to whole device pixels, leaving scale/rotation
    /// untouched. Used for solid fills so abutting fills land on the same physical pixel (no seam);
    /// animating/scrolling content keeps its exact sub-pixel transform so motion stays smooth.
    func pixelSnappingTranslation(of transform: CATransform3D) -> CATransform3D {
        let scale = deviceScale
        var snapped = transform
        snapped.m41 = Float(snapToPixel(CGFloat(transform.m41), scale: scale.x))
        snapped.m42 = Float(snapToPixel(CGFloat(transform.m42), scale: scale.y))
        return snapped
    }

    func fill(_ rect: CGRect, with color: UIColor, cornerRadius: CGFloat) {
        if cornerRadius >= 1 {
            let previousProgram = ShaderProgram.currentlyActive
            ShaderProgram.roundedRect.activate()
            ShaderProgram.roundedRect.setFill(rect: rect, cornerRadius: cornerRadius)
            GPU_RectangleFilled(rawPointer, roundedShaderQuad(for: rect), color: color.sdlColor)
            restoreShaderProgram(previousProgram)
        } else {
            GPU_RectangleFilled(rawPointer, gpuRect(rect), color: color.sdlColor)
        }
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
            let previousProgram = ShaderProgram.currentlyActive
            ShaderProgram.roundedRect.activate()
            ShaderProgram.roundedRect.setStroke(rect: rect, cornerRadius: cornerRadius, borderWidth: lineThickness)
            GPU_RectangleFilled(rawPointer, roundedShaderQuad(for: rect), color: lineColor.sdlColor)
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

    // The rounded-rect shader anti-aliases just *outside* the shape, over a band up to ~2 device
    // pixels wide at a corner (`fwidth`), so the quad we draw must extend past `rect` by that band
    // or the fade gets clipped. Pad by 2 device pixels per side (converted to points via the scale);
    // the SDF still uses the original `rect`, so these extra fragments simply shade to zero.
    func roundedShaderQuad(for rect: CGRect) -> GPU_Rect {
        let scale = deviceScale
        let padX = 2 / scale.x
        let padY = 2 / scale.y
        return gpuRect(CGRect(
            x: rect.minX - padX,
            y: rect.minY - padY,
            width: rect.width + 2 * padX,
            height: rect.height + 2 * padY
        ))
    }

    // Snap the *edges* to physical pixels rather than origin + size independently: rounding size on
    // its own can render a view up to 1px shorter than its frame, opening a gap that shows the dark
    // area behind the background-less PlayerView on Android as a thin line (e.g. above the progress
    // bar). Rounding edges instead lands a rect's far edge on the same physical pixel as an abutting
    // rect's near edge.
    func gpuRect(_ rect: CGRect) -> GPU_Rect {
        let scale = deviceScale
        let left = snapToPixel(rect.minX, scale: scale.x)
        let top = snapToPixel(rect.minY, scale: scale.y)
        let right = snapToPixel(rect.maxX, scale: scale.x)
        let bottom = snapToPixel(rect.maxY, scale: scale.y)
        return GPU_Rect(x: Float(left), y: Float(top), w: Float(right - left), h: Float(bottom - top))
    }
}
