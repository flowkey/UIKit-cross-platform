//
//  CALayer+SDL.swift
//  UIKit
//
//  Created by Chris on 27.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import SDL
import SDL_gpu

extension CALayer {
    final func sdlRender(at parentAbsoluteOrigin: CGPoint = .zero, parentOpacity: Float = 1) {
        let opacity = parentOpacity * self.opacity
        if isHidden || opacity < 0.01 { return }

        if !CATransform3DEqualToTransform(transform, CATransform3DIdentity) {
            withUnsafeMutablePointer(to: &transform.storage) { pointerToTuple in
                pointerToTuple.withMemoryRebound(to: Float.self, capacity: 16) { pointerToFirstTransformFloat in
                    GPU_MultMatrix(pointerToFirstTransformFloat)
                }
            }
        }

        let absoluteFrame = frame.offsetBy(parentAbsoluteOrigin)
        
        // Big performance optimization. Don't render anything that's entirely offscreen:
        guard absoluteFrame.intersects(SDL.rootView.bounds) else { return }

        if let mask = mask, let maskContents = mask.contents {
            ShaderProgram.mask.activate()
            ShaderProgram.mask.set(maskImage: maskContents, frame: absoluteFrame) // must be set after activation
        }

        if let backgroundColor = backgroundColor {
            let backgroundColorOpacity = opacity * backgroundColor.alpha.toNormalisedFloat()
            SDL.window.fill(
                absoluteFrame,
                with: backgroundColor.withAlphaComponent(CGFloat(backgroundColorOpacity)),
                cornerRadius: cornerRadius
            )
        }

        if borderWidth > 0 {
            SDL.window.outline(
                absoluteFrame,
                lineColor: borderColor.withAlphaComponent(CGFloat(opacity)),
                lineThickness: borderWidth,
                cornerRadius: cornerRadius
            )
        }

        if let shadowPath = shadowPath, let shadowColor = shadowColor {
            let absoluteShadowOpacity = shadowOpacity * opacity * 0.5 // for "shadow" effect ;)

            if absoluteShadowOpacity > 0.01 {
                let absoluteShadowPath = shadowPath.offsetBy(absoluteFrame.origin)
                SDL.window.fill(
                    absoluteShadowPath,
                    with: shadowColor.withAlphaComponent(CGFloat(absoluteShadowOpacity)),
                    cornerRadius: 2
                )
            }
        }

        if let contents = contents {
            SDL.window.blit(
                contents,
                at: absoluteFrame.origin,
                scaleX: Float(1 / contentsScale),
                scaleY: Float(1 / contentsScale),
                opacity: opacity,
                clippingRect: (masksToBounds ? superlayer?.bounds : nil)
            )
        }

        if mask != nil {
            ShaderProgram.deactivateAll()
        }

        sublayers?.forEach {
            var currentTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())

            ($0.presentation ?? $0).sdlRender(
                at: absoluteFrame.origin.offsetBy(-bounds.origin),
                parentOpacity: opacity
            )

            withUnsafeMutablePointer(to: &currentTransform.storage) { pointerToTuple in
                pointerToTuple.withMemoryRebound(to: Float.self, capacity: 16) { pointerToFirstTransformFloat in
                    GPU_MatrixCopy(GPU_GetCurrentMatrix(), pointerToFirstTransformFloat)
                }
            }
        }
    }
}
