//
//  FontRenderer+renderAttributedString.swift
//  UIKit
//
//  Created by Michael Knoch on 20.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL_ttf

extension FontRenderer {
    func render(attributedString: NSAttributedString, color fallbackColour: UIColor) -> UnsafeMutablePointer<SDLSurface>? {
        guard let surface = createSurface(attributedstring: attributedString) else { return nil }

        var color = fallbackColour.sdlColor
        if color.a == 0 {
            color.a = UInt8(SDL_ALPHA_OPAQUE)
        }

        var alpha_table = [UInt8](0...255)
        if color.a == SDL_ALPHA_OPAQUE {
            for i in alpha_table.indices {
                alpha_table[i] = UInt8(i)
            }
        } else {
            for i in alpha_table.indices {
                alpha_table[i] = UInt8(i * Int(color.a) / 255)
            }
            SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_BLEND)
        }

        var xOffset: Int32 = 0

        // Adding bound checking to avoid all kinds of memory corruption errors
        let lastValidPixel = surface.pointee.pixels.assumingMemoryBound(to: UInt32.self)
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
            var width = glyph.pixmap.width

            if rawPointer.pointee.outline <= 0 && width > glyph.maxx - glyph.minx {
                width = glyph.maxx - glyph.minx
            }


            xOffset += getFontKerningOffset(previousIndex: previousGlyphIndex, currentIndex: glyph.index) >> 6
            previousGlyphIndex = glyph.index

            let attributedColorForCharacter = attributedString.attribute(
                .foregroundColor, at: index, effectiveRange: nil) as? UIColor
            let colorForCharacter = attributedColorForCharacter?.sdlColor ?? color

            let currentColor =
                UInt32(colorForCharacter.r) << 16
                    | UInt32(colorForCharacter.g) << 8
                    | UInt32(colorForCharacter.b)

            for row in 0 ..< glyph.pixmap.rows {
                if (xOffset + glyph.minx) < 0 {
                    xOffset = -glyph.minx
                }

                guard
                    row + glyph.yoffset >= 0,
                    row + glyph.yoffset < surface.pointee.h
                    else { continue }

                let pixels = surface.pointee.pixels.assumingMemoryBound(to: UInt32.self)
                var currentPixel = pixels.advanced(by: Int((row + glyph.yoffset)
                    * surface.pointee.pitch / 4 + xOffset + glyph.minx))

                var source = UnsafeMutablePointer<UInt8>(glyph.pixmap.buffer!)
                    .advanced(by: Int(row * glyph.pixmap.pitch))

                for _ in 0 ..< width {
                    guard currentPixel < lastValidPixel else { break }

                    let alpha = Int(source.pointee)
                    source = source.advanced(by: 1)

                    currentPixel.pointee |= (currentColor | UInt32(alpha_table[alpha]) << 24)
                    currentPixel = currentPixel.advanced(by: 1)
                }
            }

            if let attributedKerningOffset =
                attributedString.attribute(.kern, at: index, effectiveRange: nil) as? CGFloat
            {
                xOffset += Int32(attributedKerningOffset)
            }

            xOffset += glyph.advance
        }

        return surface
    }
}

extension FontRenderer {
    func singleLineSize(of attributedString: NSAttributedString) -> CGSize {
        var width: Int32 = 0
        var height: Int32 = 0
        if TTF_SizeUTF8(rawPointer, attributedString.string, &width, &height) < 0 || width == 0 {
            return .zero
        }

        return CGSize(width: CGFloat(width) + attributedString.entireKerningWidth, height: CGFloat(height))
    }
}


private extension FontRenderer {
    func createSurface(attributedstring: NSAttributedString) -> UnsafeMutablePointer<SDLSurface>? {
        let size = self.singleLineSize(of: attributedstring)

        return SDL_CreateRGBSurface(
            UInt32(SDL_SWSURFACE), Int32(size.width), Int32(size.height), 32,
            0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000
        )
    }

    func getFontKerningOffset(previousIndex: FT_UInt?, currentIndex: FT_UInt) -> Int32 {
        guard let previousIndex = previousIndex else { return 0 }

        let useKerning = (rawPointer.pointee.face.pointee.face_flags & FT_FACE_FLAG_KERNING) != 0
        if useKerning {
            var delta = FT_Vector()
            FT_Get_Kerning(
                self.rawPointer.pointee.face,
                previousIndex,
                currentIndex,
                FT_KERNING_DEFAULT.rawValue,
                &delta
            )
            return Int32(delta.x >> 6)
        }

        return 0
    }
}

private extension NSAttributedString {
    var entireKerningWidth: CGFloat {
        var extraWidthFromAttributedKerning: CGFloat = 0
        for index in 0 ..< self.string.count {
            if let offset = self.attribute(.kern, at: index, effectiveRange: nil) as? CGFloat {
                extraWidthFromAttributedKerning += offset
            }
        }
        return extraWidthFromAttributedKerning
    }
}
