internal import SDL_gpu

internal class RenderTarget {
    var rawPointer: UnsafeMutablePointer<GPU_Target>

    let bounds: CGRect
    var scale: CGFloat = 1.0
    var clippingRect: CGRect? {
        didSet {
            guard let clippingRect else {
                return GPU_UnsetClip(rawPointer)
            }

            if rawPointer.pointee.image == nil {
                GPU_SetClipRect(rawPointer, clippingRect.gpuRect(scale: scale))
            } else {
                // for some reason using an image as a target works differently than the window..
                GPU_SetClipRect(
                    rawPointer,
                    GPU_Rect(
                        x: Float(clippingRect.minX),
                        y: Float(clippingRect.minY),
                        w: Float(clippingRect.width * scale),
                        h: Float(clippingRect.height * scale)
                    )
                )
            }
        }
    }

    init(_ gpuTarget: UnsafeMutablePointer<GPU_Target>) {
        rawPointer = gpuTarget
        bounds = CGRect(x: 0, y: 0, width: CGFloat(rawPointer.pointee.w), height: CGFloat(rawPointer.pointee.h))
    }

    init(image: UnsafeMutablePointer<GPU_Image>) {
        rawPointer = GPU_LoadTarget(image)
        bounds = CGRect(x: 0, y: 0, width: CGFloat(rawPointer.pointee.w), height: CGFloat(rawPointer.pointee.h))
    }

    deinit {
        // XXX: Does this play nice when RenderTarget == UIScreen?
        GPU_FreeTarget(rawPointer)
    }
}

extension RenderTarget {
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

    func blit(renderTarget: RenderTarget, opacity: Float) throws {
        GPU_SetAnchor(renderTarget.rawPointer.pointee.image, 0, 0)
        GPU_SetRGBA(renderTarget.rawPointer.pointee.image, 255, 255, 255, opacity.normalisedToUInt8())

        GPU_BlitTransform(
            renderTarget.rawPointer.pointee.image,
            nil,
            self.rawPointer,
            0, // offset
            0, // offset
            0, // rotation in degrees
            Float(1 / scale),
            Float(1 / scale)
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
            GPU_RectangleRoundFilled(rawPointer, rect.gpuRect(scale: scale), cornerRadius: Float(cornerRadius), color: color.sdlColor)
        } else {
            GPU_RectangleFilled(rawPointer, rect.gpuRect(scale: scale), color: color.sdlColor)
        }
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat) {
        // we want to render the outline 'inside' the rect rather
        // than exceeding the bounds when lineThickness is bigger than 1
        let offset = lineThickness / 2
        let scaledGpuRect = CGRect(
            x: rect.origin.x + offset,
            y: rect.origin.y + offset,
            width: rect.size.width - offset,
            height: rect.size.height - offset
        ).gpuRect(scale: scale)

        GPU_SetLineThickness(Float(lineThickness))
        GPU_Rectangle(rawPointer, scaledGpuRect, color: lineColor.sdlColor)
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat, cornerRadius: CGFloat) {
        if cornerRadius > 1 {
            // we want to render the outline 'inside' the rect rather
            // than exceeding the bounds when lineThickness is bigger than 1
            let offset = lineThickness / 2
            let scaledGpuRect = CGRect(
                x: rect.origin.x + offset,
                y: rect.origin.y + offset,
                width: rect.size.width - offset,
                height: rect.size.height - offset
            ).gpuRect(scale: scale)

            GPU_SetLineThickness(Float(lineThickness))
            GPU_RectangleRound(rawPointer, scaledGpuRect, cornerRadius: Float(cornerRadius), color: lineColor.sdlColor)
        } else {
            outline(rect, lineColor: lineColor, lineThickness: lineThickness)
        }
    }

    func flip() throws {
        GPU_Flip(rawPointer)
        try throwOnErrors(ofType: [GPU_ERROR_USER_ERROR, GPU_ERROR_BACKEND_ERROR])
    }

    func setVirtualResolution(w: UInt16, h: UInt16) {
        GPU_SetVirtualResolution(rawPointer, w, h)
    }
}

private extension CGRect {
    func gpuRect(scale: CGFloat) -> GPU_Rect {
        return GPU_Rect(
            x: Float((self.origin.x * scale).rounded() / scale),
            y: Float((self.origin.y * scale).rounded() / scale),
            w: Float((self.size.width * scale).rounded() / scale),
            h: Float((self.size.height * scale).rounded() / scale)
        )
    }
}


extension CALayer {
    func setRenderTargetIfNeeded() {
        if mask == nil, (opacity == 1 || sublayers == nil) {
            renderTarget = nil
            return
        }

        let bounds = if masksToBounds || mask?.bounds == nil {
            mask?.bounds ?? bounds
        } else {
            UIScreen.main?.bounds ?? bounds
        }

        guard let image = GPU_CreateImage(
            UInt16(bounds.width * contentsScale),
            UInt16(bounds.height * contentsScale),
            GPU_FORMAT_RGBA
        ) else {
            assertionFailure("Couldn't create render target")
            return
        }

        renderTarget = RenderTarget(image: image)
        renderTarget?.scale = contentsScale
        renderTarget?.setVirtualResolution(w: UInt16(bounds.width), h: UInt16(bounds.height))
    }
}
