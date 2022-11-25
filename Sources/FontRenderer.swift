//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL_ttf


extension FontRenderer {
    /// Stores the renderers for a specific Name/Size UIFont configuration to avoid reiniting them all the time.
    static var cache = [String: FontRenderer]()

    /// Called whenever the UIScreen is destroyed to avoid strange font rendering bugs on reinit.
    static func cleanupSession() {
        cache.removeAll()
        TTF_Quit()
    }

    private static func initialize() -> Bool {
        return (TTF_WasInit() == 1) || (TTF_Init() != -1)
    }
}

@MainActor
public class FontRenderer {
    let rawPointer: UnsafeMutablePointer<TTF_Font>
    deinit { TTF_CloseFont(rawPointer) }

    init?(_ source: CGDataProvider, size: Int32) {
        if !FontRenderer.initialize() { return nil }

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
}


// MARK: Get size of text for current font

extension FontRenderer {
    func singleLineSize(of text: String) -> CGSize {
        let (width, height) = size(text)
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
        return multilineSize(of: text, wrapLength: Int(wrapLength))
    }

    private func multilineSize(of text: UnsafePointer<CChar>, wrapLength: Int) -> CGSize {
        guard wrapLength > 0 else { return .zero }
        let lineSpace = 2

        var textLineHeight: Int32 = 0

        var tok = UnsafeMutablePointer(mutating: text)
        let end = tok + SDL_strlen(text)

        var lines = [UnsafeMutablePointer<CChar>]()
        repeat {
            lines.append(tok)

            /* Look for the end of the line */

            var searchIndex =
                strchr(tok, newLineR) ??
                    strchr(tok, newLineN) ??
                    end

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

        let linesCount = lines.count
        let combinedTextHeight = Int(textLineHeight) * linesCount
        let combinedLineSpacing = lineSpace * (linesCount - 1)

        return CGSize(width: wrapLength, height: combinedTextHeight + combinedLineSpacing)
    }
}
