//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL_ttf

private func initSDL_ttf() -> Bool {
    return (TTF_WasInit() == 1) || (TTF_Init() != -1) // TTF_Init returns -1 on failure
}

internal class FontRenderer {
    private let rawPointer: UnsafeMutablePointer<TTF_Font>
    deinit { TTF_CloseFont(rawPointer) }

    init?(_ source: CGDataProvider, size: Int32) {
        if !initSDL_ttf() { return nil }

        let rwOp = SDL_RWFromConstMem(source.data, Int32(source.data.count))
        guard let font = TTF_OpenFontRW(rwOp, 1, size) else { return nil }

        TTF_SetFontHinting(font, TTF_HINTING_LIGHT) // recommended in docs for max quality
        rawPointer = font
    }

    func getLineHeight() -> Int {
        return Int(TTF_FontLineSkip(rawPointer))
    }

    func getFontStyleName() -> String? {
        guard let styleName = TTF_FontFaceStyleName(rawPointer) else { return nil }
        return String(cString: styleName)
    }

    func getFontFamilyName() -> String? {
        guard let cStringFamilyName = TTF_FontFaceFamilyName(rawPointer) else { return nil }
        return String(cString: cStringFamilyName)
    }

    func render(_ text: String?, color: UIColor, wrapLength: Int = 0) -> CGImage? {
        guard let text = text else { return nil }

        guard
            let surface = (wrapLength > 0) ?
                TTF_RenderUTF8_Blended_Wrapped(rawPointer, text, color.sdlColor, UInt32(wrapLength)) :
                TTF_RenderUTF8_Blended(rawPointer, text, color.sdlColor)
            else { return nil }

        defer { SDL_FreeSurface(surface) }
        return CGImage(surface: surface)
    }

    func render(_ attributedText: NSAttributedString?, color: UIColor) -> CGImage? {
        guard let attributedText = attributedText else { return nil }

        guard let surface = self.render(attributedString: attributedText, color: color)
        else { return nil }

        defer { SDL_FreeSurface(surface) }
        return CGImage(surface: surface)
    }
}


// MARK: Get size of text for current font

extension FontRenderer {
    func singleLineSize(of text: String) -> CGSize {
        var width: Int32 = 0
        var height: Int32 = 0
        TTF_SizeUTF8(rawPointer, text, &width, &height)

        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
}

// Optimise perf
private let newLineR = Int32("\r".utf8.first!)
private let newLineN = Int32("\n".utf8.first!)

extension FontRenderer {
    private func charIsDelimiter(_ char: CChar) -> Bool {
        let wrappingDelimiters = " -\t\r\n"
        return strchr(wrappingDelimiters, Int32(char)) != nil
    }

    internal func multilineSize(of text: String, wrapLength: UInt) -> CGSize {
        return multilineSize(of: text, textLength: Int32(text.count), wrapLength: Int(wrapLength))
    }

    private func multilineSize(of text: UnsafePointer<CChar>, textLength: Int32, wrapLength: Int) -> CGSize {
        guard wrapLength > 0 else { return .zero }
        let lineSpace = 2

        var textLineHeight: Int32 = 0

        var tok = UnsafeMutablePointer(mutating: text)
        let end = tok + Int(textLength)

        var lines = [UnsafeMutablePointer<CChar>]()
        repeat {
            lines.append(tok)

            /* Look for the end of the line */

            var searchIndex =
                strchr(tok, newLineR) ??
                    strchr(tok, newLineN) ??
                    end.advanced(by: -1)

            var firstCharOfNextLine = searchIndex + 1

            /* Get the longest string that will fit in the desired space */
            while true {
                /* Strip trailing whitespace */
                while searchIndex > tok && charIsDelimiter(searchIndex[-1]) {
                    searchIndex -= 1
                }

                if searchIndex == tok {
                    if charIsDelimiter(searchIndex.pointee) {
                        searchIndex.pointee = CChar(0)
                    }
                    break
                }

                let delim = searchIndex.pointee
                searchIndex.pointee = CChar(0)

                var textLineWidth: Int32 = 0
                TTF_SizeUTF8(self.rawPointer, tok, &textLineWidth, &textLineHeight)

                if (UInt32(textLineWidth) <= wrapLength) {
                    break
                } else {
                    /* Back up and try again... */
                    searchIndex.pointee = delim
                }

                while searchIndex > tok && !charIsDelimiter(searchIndex[-1]) {
                    searchIndex -= 1
                }

                if searchIndex > tok {
                    firstCharOfNextLine = searchIndex
                }
            }

            tok = firstCharOfNextLine
        } while (tok < end)

        // The sizing using linesCount is actually correct, but it gives a different result compared to
        // what actually gets rendered. So for now, use this updated figure to have correct sizeThatFits etc:
        let numberOfRandomExtraLinesRenderedBySDLTTF = 1
        let linesCount = lines.count + numberOfRandomExtraLinesRenderedBySDLTTF

        let combinedTextHeight = Int(textLineHeight) * linesCount
        let combinedLineSpacing = lineSpace * (linesCount - 1)

        return CGSize(width: wrapLength, height: combinedTextHeight + combinedLineSpacing)
    }
}


extension FontRenderer {
    func render(attributedString: NSAttributedString, color: UIColor) -> UnsafeMutablePointer<SDLSurface>? {
        var width: Int32 = 0
        var height: Int32 = 0

        var xstart: Int32 = 0

        var alpha: Int
        var alpha_table = [UInt8](0...255)
        var pixel: UInt32

        var src = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        var dst = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        var dst_check = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)

        var glyph: UnsafeMutablePointer<c_glyph>
        var prev_index: FT_UInt = 0

        /* Get the dimensions of the text surface */
        if TTF_SizeUTF8(rawPointer, attributedString.string, &width, &height) < 0 || width == 0 {
            print("Text has zero width");
            return nil;
        }

        guard let textbuf = SDL_CreateRGBSurface(
            UInt32(SDL_SWSURFACE), width, height, 32,
            0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000
        ) else { return nil }

        /* Adding bound checking to avoid all kinds of memory corruption errors
         that may occur. */
        dst_check = textbuf.pointee.pixels.assumingMemoryBound(to: UInt32.self) + Int(textbuf.pointee.pitch/4 * textbuf.pointee.h)

        let useKerning = (rawPointer.pointee.face.pointee.face_flags & FT_FACE_FLAG_KERNING) != 0

        var sdlColor = color.sdlColor

        if (sdlColor.a == 0) {
            sdlColor.a = UInt8(SDL_ALPHA_OPAQUE);
        }

        if (sdlColor.a == SDL_ALPHA_OPAQUE) {
            for i in alpha_table.indices {
                alpha_table[i] = UInt8(i)
            }
        } else {
            for i in alpha_table.indices {
                alpha_table[i] = UInt8(i * Int(sdlColor.a) / 255)
            }
            print(alpha_table)
            SDL_SetSurfaceBlendMode(textbuf, SDL_BLENDMODE_BLEND)
        }


        for (index, unicodeScalar) in attributedString.string.unicodeScalars.enumerated() {
            let c: UInt32 = unicodeScalar.value

            if (c == UNICODE_BOM_NATIVE || c == UNICODE_BOM_SWAPPED) {
                continue
            }

            let error: CInt = Find_Glyph(rawPointer, c, CACHED_METRICS|CACHED_PIXMAP);
            if (error != 0) {
                print("Couldn't find glyph")
                SDL_FreeSurface(textbuf)
                return nil
            }

            glyph = rawPointer.pointee.current
            /* Ensure the width of the pixmap is correct. On some cases,
             * freetype may report a larger pixmap than possible.*/
            width = glyph.pointee.pixmap.width

            if (rawPointer.pointee.outline <= 0 && width > glyph.pointee.maxx - glyph.pointee.minx) {
                width = glyph.pointee.maxx - glyph.pointee.minx
            }

            /* do kerning, if possible AC-Patch */
            if (useKerning && prev_index > 0 && glyph.pointee.index > 0) {
                var delta = FT_Vector()
                FT_Get_Kerning(rawPointer.pointee.face, prev_index, glyph.pointee.index, FT_KERNING_DEFAULT.rawValue, &delta);
                xstart = xstart.advanced(by: delta.x >> 6)
            }

            let charColor: SDLColor? = (attributedString.attribute(.foregroundColor, at: index, effectiveRange: nil) as? UIColor)?.sdlColor

            for row in 0..<glyph.pointee.pixmap.rows {
                /* Make sure we don't go either over, or under the limit */
                if (xstart + glyph.pointee.minx) < 0 {
                    xstart = -glyph.pointee.minx
                }
                if Int(row) + Int(glyph.pointee.yoffset) < 0 {
                    continue;
                }
                if (Int(row) + Int(glyph.pointee.yoffset)) >= textbuf.pointee.h {
                    continue;
                }

                let pixels = textbuf.pointee.pixels.assumingMemoryBound(to: UInt32.self)
                dst = pixels.advanced(by: Int((row + glyph.pointee.yoffset) * textbuf.pointee.pitch/4 + xstart + glyph.pointee.minx))

                src = UnsafeMutablePointer<UInt8>(glyph.pointee.pixmap.buffer!)
                    .advanced(by: Int(row * glyph.pointee.pixmap.pitch))

                for _ in 0..<width {
                    if dst >= dst_check { break }

                    alpha = Int(src.pointee)
                    src = src.advanced(by: 1)

                    let _color = charColor ?? color.sdlColor

                    pixel = (UInt32(_color.r) << 16) | (UInt32(_color.g) << 8) | (UInt32(_color.b))
                    dst.pointee = dst.pointee | ( pixel | UInt32(alpha_table[alpha]) << 24)
                    dst = dst.advanced(by: 1)
                }
            }

            xstart = xstart + glyph.pointee.advance
            prev_index = glyph.pointee.index
        }

        return textbuf
    }

}

