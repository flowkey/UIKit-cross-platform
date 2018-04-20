//
//  FontRenderer+renderAttributedString.swift
//  UIKit
//
//  Created by Michael Knoch on 20.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import SDL_ttf

extension FontRenderer {
    func render(attributedString: NSAttributedString, color _color: UIColor) -> UnsafeMutablePointer<SDLSurface>? {
        var width: Int32 = 0
        var height: Int32 = 0
        if TTF_SizeUTF8(rawPointer, attributedString.string, &width, &height) < 0 || width == 0 {
            print("Text has zero width")
            return nil
        }

        guard let surface = SDL_CreateRGBSurface(
            UInt32(SDL_SWSURFACE), width, height, 32,
            0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000
        ) else { return nil }

        var color = _color.sdlColor
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
        let destinationCheck = surface.pointee.pixels.assumingMemoryBound(to: UInt32.self)
            + Int(surface.pointee.pitch / 4 * surface.pointee.h)

        for (index, unicodeScalar) in attributedString.string.unicodeScalars.enumerated() {
            let c: UInt32 = unicodeScalar.value

            if c == UNICODE_BOM_NATIVE || c == UNICODE_BOM_SWAPPED {
                continue
            }

            if Find_Glyph(rawPointer, c, CACHED_METRICS|CACHED_PIXMAP) != 0 {
                print("Couldn't find glyph")
                SDL_FreeSurface(surface)
                return nil
            }

            let glyph: UnsafeMutablePointer<c_glyph> = rawPointer.pointee.current

            // Ensure the width of the pixmap is correct. On some cases
            // freetype may report a larger pixmap than possible.
            width = glyph.pointee.pixmap.width

            if (rawPointer.pointee.outline <= 0 && width > glyph.pointee.maxx - glyph.pointee.minx) {
                width = glyph.pointee.maxx - glyph.pointee.minx
            }


            let previousIndex = min(index - 1, 0)
            let useKerning = (rawPointer.pointee.face.pointee.face_flags & FT_FACE_FLAG_KERNING) != 0

            if useKerning && previousIndex > 0 && glyph.pointee.index > 0 {
                var delta = FT_Vector()
                FT_Get_Kerning(
                    rawPointer.pointee.face,
                    FT_UInt(previousIndex),
                    glyph.pointee.index,
                    FT_KERNING_DEFAULT.rawValue,
                    &delta
                )
                xOffset = xOffset.advanced(by: delta.x >> 6)
            }

            let attributedColorForCharacter = attributedString.attribute(
                .foregroundColor, at: index, effectiveRange: nil) as? UIColor
            let cholorForCharacter = attributedColorForCharacter?.sdlColor ?? color

            let pixel =
                  UInt32(cholorForCharacter.r) << 16
                | UInt32(cholorForCharacter.g) << 8
                | UInt32(cholorForCharacter.b)

            for row in 0..<glyph.pointee.pixmap.rows {
                if (xOffset + glyph.pointee.minx) < 0 {
                    xOffset = -glyph.pointee.minx
                }

                if row + glyph.pointee.yoffset < 0 {
                    continue
                }
                if row + glyph.pointee.yoffset >= surface.pointee.h {
                    continue
                }

                let pixels = surface.pointee.pixels.assumingMemoryBound(to: UInt32.self)
                var destination = pixels.advanced(by: Int((row + glyph.pointee.yoffset)
                    * surface.pointee.pitch / 4 + xOffset + glyph.pointee.minx))

                var source = UnsafeMutablePointer<UInt8>(glyph.pointee.pixmap.buffer!)
                    .advanced(by: Int(row * glyph.pointee.pixmap.pitch))

                for _ in 0..<width {
                    guard destination < destinationCheck else { break }

                    let alpha = Int(source.pointee)
                    source = source.advanced(by: 1)

                    destination.pointee = destination.pointee | (pixel | UInt32(alpha_table[alpha]) << 24)
                    destination = destination.advanced(by: 1)
                }
            }

            xOffset = xOffset + glyph.pointee.advance
        }

        return surface
    }
}
