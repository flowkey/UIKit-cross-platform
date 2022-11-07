//
//  FontRenderer+renderAttributedString.swift
//  UIKit
//
//  Created by Michael Knoch on 20.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL_ttf

extension FontRenderer {
    @MainActor
    func render(attributedString: NSAttributedString, color fallbackColor: UIColor) -> UnsafeMutablePointer<SDLSurface>? {
        guard
            let surface = createSurface(toFit: attributedString),
            surface.pointee.pixels != nil
        else {
            assertionFailure("Couldn't render attributed string '\(attributedString.string)'")
            return nil
        }

        var xOffset: Int32 = 0

        // Bounds checking to avoid memory corruption errors
        let surfaceEndIndex = surface.pointee.pixels.assumingMemoryBound(to: UInt32.self)
            + Int(surface.pointee.pitch / 4 * surface.pointee.h)

        var previousGlyphIndex: FT_UInt?
        for (index, unicodeScalar) in attributedString.string.unicodeScalars.enumerated() {
            let c: UInt32 = unicodeScalar.value

            if c == UNICODE_BOM_NATIVE || c == UNICODE_BOM_SWAPPED {
                continue
            }

            if Find_Glyph(rawPointer, c, CACHED_METRICS|CACHED_PIXMAP) != 0 {
                print("Couldn't find glyph \(c) in \(getFontFamilyName() ?? "font")")
                SDL_FreeSurface(surface)
                return nil
            }

            let glyph = rawPointer.pointee.current.pointee
            let width = rawPointer.pointee.outline > 0 ?
                glyph.pixmap.width :
                min(glyph.pixmap.width, UInt32(glyph.maxx - glyph.minx))

            xOffset += getFontKerningOffset(between: previousGlyphIndex, and: glyph.index)
            previousGlyphIndex = glyph.index

            let attributedColorForCharacter = attributedString.attribute(
                .foregroundColor, at: index, effectiveRange: nil) as? UIColor
            let colorForCharacter = (attributedColorForCharacter ?? fallbackColor).sdlColor

            let currentColor =
                      UInt32(colorForCharacter.r) << 16
                    | UInt32(colorForCharacter.g) << 8
                    | UInt32(colorForCharacter.b)

            for row in 0 ..< Int32(glyph.pixmap.rows) {
                if (xOffset + glyph.minx) < 0 {
                    xOffset = -glyph.minx
                }

                guard
                    row + glyph.yoffset >= 0,
                    row + glyph.yoffset < surface.pointee.h
                    else { continue }

                let pixels = surface.pointee.pixels.assumingMemoryBound(to: UInt32.self)
                let pixelsPerRow: Int32 = surface.pointee.pitch / 4
                var currentPixel = pixels.advanced(
                    by: Int((row + glyph.yoffset) * pixelsPerRow + xOffset + glyph.minx)
                )

                var source = UnsafeMutablePointer<UInt8>(glyph.pixmap.buffer!)
                    .advanced(by: Int(row * glyph.pixmap.pitch))

                for _ in 0 ..< width {
                    guard currentPixel < surfaceEndIndex else { break }

                    let alpha = Int(source.pointee)
                    source = source.advanced(by: 1)

                    currentPixel.pointee |= (currentColor | UInt32(alpha) << 24)
                    currentPixel = currentPixel.advanced(by: 1)
                }
            }

            if let attributedKerningOffset =
                attributedString.attribute(.kern, at: index, effectiveRange: nil) as? CGFloat
            {
                xOffset += Int32(attributedKerningOffset * UIScreen.main.scale)
            }

            xOffset += glyph.advance
        }

        return surface
    }
}

extension FontRenderer {
    fileprivate func createSurface(toFit attributedstring: NSAttributedString) -> UnsafeMutablePointer<SDLSurface>? {
        let size = self.singleLineSize(of: attributedstring)
        precondition(size.width > 0)
        precondition(size.height > 0)

        let surface = SDL_CreateRGBSurface(
            UInt32(SDL_SWSURFACE), Int32(size.width), Int32(size.height), 32,
            0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000
        )
        SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_BLEND)
        return surface
    }

    func getFontKerningOffset(between previousIndex: FT_UInt?, and currentIndex: FT_UInt) -> Int32 {
        guard let previousIndex = previousIndex, fontHasKerning else { return 0 }

        var delta = FT_Vector()
        FT_Get_Kerning(
            rawPointer.pointee.face,
            previousIndex,
            currentIndex,
            FT_KERNING_DEFAULT.rawValue,
            &delta
        )

        return Int32(delta.x >> 6)
    }
}
