//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.ttf

private func initSDL_ttf() -> Bool {
    return (TTF_WasInit() == 1) || (TTF_Init() != -1) // TTF_Init returns -1 on failure
}

internal class FontRenderer {
    private let rawPointer: OpaquePointer // TTF_Font
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
        let unicode16Text = text.toUTF16()

        guard
            let surface = (wrapLength > 0) ?
                TTF_RenderUNICODE_Blended_Wrapped(rawPointer, unicode16Text, color.sdlColor, UInt32(wrapLength)) :
                TTF_RenderUNICODE_Blended(rawPointer, unicode16Text, color.sdlColor)
        else {
            return nil
        }

        defer { surface.pointee.free() }
        return CGImage(surface: surface)
    }
}

private extension String {
    func toUTF16() -> [UInt16] {
        // Add a 0 to the end of the array to mark the end of the C string
        return self.utf16.map { $0 } + [0]
    }
}


// MARK: Get size of text for current font

extension FontRenderer {
    func singleLineSize(of text: String) -> CGSize {
        var width: Int32 = 0
        var height: Int32 = 0
        TTF_SizeUNICODE(rawPointer, text.toUTF16(), &width, &height)

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
        let end = UnsafeMutablePointer(mutating: text.advanced(by: Int(textLength)))

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

        let combinedTextHeight = Int(textLineHeight) * lines.count
        let combinedLineSpacing = lineSpace * (lines.count - 1)

        return CGSize(width: wrapLength, height: combinedTextHeight + combinedLineSpacing)
    }
}

