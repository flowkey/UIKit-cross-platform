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
    final func sdlRender(in parentAbsoluteOrigin: CGPoint = .zero, parentOpacity: Float = 1) {
        let opacity = self.opacity * parentOpacity
        if isHidden || opacity < 0.01 { return }

        let absoluteFrame = frame.offsetBy(parentAbsoluteOrigin)

        // Big performance optimization. Don't render anything that's entirely offscreen:
        guard absoluteFrame.intersects(SDL.rootView.bounds) else { return }

        if SDL.window.printThisLoop {
            print("--------------------------------")
            print(self.delegate ?? self)
            print(absoluteFrame)
            print("at \(parentAbsoluteOrigin))")
            print()
        }

        if let mask = mask, let maskContents = mask.contents {
            ShaderProgram.mask.activate() // must activate before setting parameters (below)!
            ShaderProgram.mask.set(maskImage: maskContents, frame: mask.bounds)
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
                SDL.window.fill(
                    shadowPath.offsetBy(absoluteFrame.origin),
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

        let parentTransform = CATransform3D(unsafePointer: GPU_GetCurrentMatrix())
        let modelViewTransform = parentTransform.concat(self.transform)
        modelViewTransform.setAsSDLgpuMatrix()

        // This can be written more succinctly, but the current form is easier to step through when debugging:
        if let sublayers = sublayers {
            let boundsOffsetOrigin = absoluteFrame.origin.offsetBy(-bounds.origin)
            for sublayer in sublayers {
                (sublayer.presentation ?? sublayer).sdlRender(in: boundsOffsetOrigin, parentOpacity: opacity)
            }
        }

        // Remove current transform from the stack
        parentTransform.setAsSDLgpuMatrix()
    }
}
