//
//  UIScreen+render.swift
//  UIKit
//
//  Created by Chris on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL
import SDL_gpu
import func Foundation.round

extension UIScreen {
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
            GPU_RectangleRoundFilled(rawPointer, rect.gpuRect(scale: scale), cornerRadius: Float(cornerRadius), color: color.sdlColor)
        } else {
            GPU_RectangleFilled(rawPointer, rect.gpuRect(scale: scale), color: color.sdlColor)
        }
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat) {
        GPU_SetLineThickness(Float(lineThickness))
        GPU_Rectangle(rawPointer, rect.gpuRect(scale: scale), color: lineColor.sdlColor)
    }

    func outline(_ rect: CGRect, lineColor: UIColor, lineThickness: CGFloat, cornerRadius: CGFloat) {
        if cornerRadius > 1 {
            GPU_SetLineThickness(Float(lineThickness))
            GPU_RectangleRound(rawPointer, rect.gpuRect(scale: scale), cornerRadius: Float(cornerRadius), color: lineColor.sdlColor)
        } else {
            outline(rect, lineColor: lineColor, lineThickness: lineThickness)
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

        GPU_SetClipRect(rawPointer, clippingRect.gpuRect(scale: scale))
    }
}

private extension CGRect {
    func gpuRect(scale: CGFloat) -> GPU_Rect {
        return GPU_Rect(
            x: Float(round(self.origin.x * scale) / scale),
            y: Float(round(self.origin.y * scale) / scale),
            w: Float(round(self.size.width * scale) / scale),
            h: Float(round(self.size.height * scale) / scale)
        )
    }
}
