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

        for displayLink in DisplayLink.activeDisplayLinks where !displayLink.isPaused {
            displayLink.callback?()
        }
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

    func blit(
        _ image: CGImage,
        in rect: CGRect,
        contentsCenter center: CGRect,
        contentsScale: CGFloat,
        opacity: Float
    ) throws {
        GPU_SetRGBA(image.rawPointer, 255, 255, 255, opacity.normalisedToUInt8())

        // Snapping rounds each slice on its own, which opens gaps between neighbouring slices.
        let snapMode = GPU_GetSnapMode(image.rawPointer)
        GPU_SetSnapMode(image.rawPointer, GPU_SNAP_NONE)
        defer { GPU_SetSnapMode(image.rawPointer, snapMode) }

        func slices(length: CGFloat, centerStart: CGFloat, centerEnd: CGFloat, from start: CGFloat, to end: CGFloat)
            -> (source: [CGFloat], destination: [CGFloat])
        {
            let source = [0, centerStart * length, centerEnd * length, length]
            let leadingCap = source[1] / contentsScale
            let trailingCap = (length - source[2]) / contentsScale
            let capScale = min(1, (end - start) / max(leadingCap + trailingCap, .leastNonzeroMagnitude))
            return (source, [start, start + leadingCap * capScale, end - trailingCap * capScale, end])
        }

        let columns = slices(length: CGFloat(image.width), centerStart: center.minX, centerEnd: center.maxX, from: rect.minX, to: rect.maxX)
        let rows = slices(length: CGFloat(image.height), centerStart: center.minY, centerEnd: center.maxY, from: rect.minY, to: rect.maxY)

        for row in 0 ..< 3 {
            for column in 0 ..< 3 {
                var source = GPU_Rect(
                    x: Float(columns.source[column]),
                    y: Float(rows.source[row]),
                    w: Float(columns.source[column + 1] - columns.source[column]),
                    h: Float(rows.source[row + 1] - rows.source[row])
                )
                var destination = GPU_Rect(
                    x: Float(columns.destination[column]),
                    y: Float(rows.destination[row]),
                    w: Float(columns.destination[column + 1] - columns.destination[column]),
                    h: Float(rows.destination[row + 1] - rows.destination[row])
                )
                if source.w <= 0 || source.h <= 0 || destination.w <= 0 || destination.h <= 0 { continue }
                GPU_BlitRect(image.rawPointer, &source, self.rawPointer, &destination)
            }
        }

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

    /// Draws `body` into `image` as an offscreen render target, then restores all touched GL state.
    /// Used to (re)build a layer's cached `contents` (e.g. `CAGradientLayer`).
    ///
    /// This runs *inside* the main render pass, where the projection/model-view and clip are configured
    /// for the screen. Rendering into a texture needs its own coordinate system, so we install an ortho +
    /// identity sized to the texture (and disable the target's camera, which is Y-inverted on image targets)
    /// so `body`'s draw maps 1:1 onto it — then pop everything back so the outer pass is untouched. The
    /// save/restore is `defer`-based so an early return in `body` can't leak state into the outer pass.
    @MainActor
    func drawIntoTexture(_ image: CGImage, _ body: (_ target: UnsafeMutablePointer<GPU_Target>) -> Void) {
        guard let target = GPU_GetTarget(image.rawPointer) else { return }
        let width = Float(image.width), height = Float(image.height)

        let savedClippingRect = clippingRect
        clippingRect = nil
        GPU_FlushBlitBuffer()
        GPU_MatrixMode(GPU_PROJECTION); GPU_PushMatrix()
        GPU_MatrixMode(GPU_MODELVIEW); GPU_PushMatrix()
        GPU_SetShapeBlending(false) // write the layer's own straight alpha, don't blend into the cleared texture
        defer {
            ShaderProgram.deactivateAll()
            GPU_FlushBlitBuffer()
            GPU_MatrixMode(GPU_MODELVIEW); GPU_PopMatrix()
            GPU_MatrixMode(GPU_PROJECTION); GPU_PopMatrix()
            GPU_MatrixMode(GPU_MODELVIEW) // leave the mode as the outer render pass expects it
            GPU_SetShapeBlending(true)
            clippingRect = savedClippingRect
        }

        GPU_EnableCamera(target, false)
        GPU_MatrixMode(GPU_PROJECTION); GPU_LoadIdentity()
        GPU_Ortho(0, width, height, 0, -1, 1)
        GPU_MatrixMode(GPU_MODELVIEW); GPU_LoadIdentity()
        GPU_SetViewport(target, GPU_Rect(x: 0, y: 0, w: width, h: height))
        GPU_Clear(target)

        body(target)
    }

    /// Only the window's target has a context, an image target doesn't.
    var isRenderingGroupOpacity: Bool { rawPointer.pointee.context == nil }

    /// Draws `body` into an offscreen copy of the screen and composites it with `opacity` once, as Core Animation's
    /// group opacity does, so overlapping translucent sublayers don't show through each other.
    @MainActor
    func renderWithGroupOpacity(_ opacity: Float, _ body: () -> Void) {
        guard
            let screenTarget = rawPointer,
            let context = screenTarget.pointee.context,
            let image = groupOpacityImage(width: Int(context.pointee.drawable_w), height: Int(context.pointee.drawable_h)),
            let target = GPU_GetTarget(image.rawPointer)
        else { return body() }

        GPU_SetVirtualResolution(target, screenTarget.pointee.w, screenTarget.pointee.h)
        let screenClippingRect = clippingRect
        rawPointer = target
        clippingRect = screenClippingRect
        GPU_Clear(target)
        body()
        rawPointer = screenTarget
        clippingRect = screenClippingRect

        let alpha = opacity.normalisedToUInt8()
        GPU_SetRGBA(image.rawPointer, alpha, alpha, alpha, alpha)
        var destination = GPU_Rect(x: 0, y: 0, w: Float(screenTarget.pointee.w), h: Float(screenTarget.pointee.h))
        GPU_MatrixMode(GPU_MODELVIEW)
        GPU_PushMatrix()
        GPU_LoadIdentity()
        GPU_BlitRect(image.rawPointer, nil, screenTarget, &destination)
        GPU_PopMatrix()
    }

    private func groupOpacityImage(width: Int, height: Int) -> CGImage? {
        if let (image, contextGeneration) = cachedGroupOpacityImage,
           contextGeneration == UIScreen.contextGeneration, image.width == width, image.height == height {
            return image
        }
        guard let image = CGImage(width: width, height: height) else { return nil }
        // Blending into the cleared image with `GPU_BLEND_NORMAL_FACTOR_ALPHA` leaves premultiplied colours.
        GPU_SetBlendMode(image.rawPointer, GPU_BLEND_PREMULTIPLIED_ALPHA)
        cachedGroupOpacityImage = (image, UIScreen.contextGeneration)
        return image
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

    func lines(_ segments: [(from: CGPoint, to: CGPoint)], offsetBy offset: CGPoint, color: UIColor, lineThickness: CGFloat) {
        let previousLineThickness = GPU_SetLineThickness(Float(lineThickness))
        defer { GPU_SetLineThickness(previousLineThickness) }
        let color = color.sdlColor
        for segment in segments {
            let from = segment.from + offset, to = segment.to + offset
            GPU_Line(rawPointer, Float(from.x), Float(from.y), Float(to.x), Float(to.y), color)
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

        // sdl-gpu scissors an image target in its pixels, ignoring the virtual resolution (renderer_GL_common.inl:841).
        let scale = isRenderingGroupOpacity ? deviceScale : (x: 1, y: 1)
        GPU_SetClipRect(rawPointer, gpuRect(clippingRect.applying(CGAffineTransform(scaleX: scale.x, y: scale.y))))
    }
}

private extension UIScreen {
    /// The GPU target's device-pixel ratio per axis (drawable / target). Per-axis because a single
    /// `UIScreen.scale` is wrong when the two axes round differently at fractional densities.
    var deviceScale: (x: CGFloat, y: CGFloat) {
        // The window's target, as `rawPointer` may be a group opacity image, which has no context.
        let screenTarget = GPU_GetContextTarget().pointee
        return (CGFloat(screenTarget.context.pointee.drawable_w) / CGFloat(screenTarget.w),
                CGFloat(screenTarget.context.pointee.drawable_h) / CGFloat(screenTarget.h))
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
