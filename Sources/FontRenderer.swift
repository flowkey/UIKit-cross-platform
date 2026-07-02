//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal import SDL_ttf


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
    private let fontSize: Int32
    private var _fallbackFonts: [UnsafeMutablePointer<TTF_Font>]?

    #if os(Android)
    private static let fallbackPaths = [
        "/system/fonts/NotoSansSymbols-Regular-Subsetted.ttf",
        "/system/fonts/NotoSansSymbols-Regular-Subsetted2.ttf",
        "/system/fonts/Roboto-Regular.ttf",
        "/system/fonts/DroidSans.ttf",
    ]
    #endif

    var fallbackFonts: [UnsafeMutablePointer<TTF_Font>] {
        if let cached = _fallbackFonts { return cached }
        var fonts: [UnsafeMutablePointer<TTF_Font>] = []
        #if os(Android)
        for path in Self.fallbackPaths {
            if let rwOp = SDL_RWFromFile(path, "rb"),
               let font = TTF_OpenFontRW(rwOp, 1, fontSize) {
                TTF_SetFontHinting(font, TTF_HINTING_LIGHT)
                fonts.append(font)
            }
        }
        #endif
        _fallbackFonts = fonts
        return fonts
    }

    func fontForGlyph(_ code: UInt32) -> UnsafeMutablePointer<TTF_Font>? {
        if code <= 0xFFFF && TTF_GlyphIsProvided(rawPointer, UInt16(code)) != 0 {
            return rawPointer
        }
        for fb in fallbackFonts {
            if code <= 0xFFFF && TTF_GlyphIsProvided(fb, UInt16(code)) != 0 {
                return fb
            }
            if code > 0xFFFF && Find_Glyph(fb, code, CACHED_METRICS) == 0 {
                return fb
            }
        }
        return nil
    }

    deinit {
        _fallbackFonts?.forEach { TTF_CloseFont($0) }
        TTF_CloseFont(rawPointer)
    }

    init?(_ source: CGDataProvider, size: Int32) {
        if !FontRenderer.initialize() { return nil }

        let rwOp = SDL_RWFromConstMem(source.data, Int32(source.data.count))
        guard let font = TTF_OpenFontRW(rwOp, 1, size) else { return nil }

        TTF_SetFontHinting(font, TTF_HINTING_LIGHT) // recommended in docs for max quality
        rawPointer = font
        self.fontSize = size
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

    private func needsFallback(_ text: String) -> Bool {
        if fallbackFonts.isEmpty { return false }
        for scalar in text.unicodeScalars {
            let code = scalar.value
            if code > 0xFFFF || TTF_GlyphIsProvided(rawPointer, UInt16(code)) == 0 {
                return true
            }
        }
        return false
    }

    func render(_ text: String?, color: UIColor, wrapLength: Int = 0, alignment: NSTextAlignment = .left) -> CGImage? {
        guard let text = text else { return nil }

        if wrapLength <= 0 && needsFallback(text) {
            return renderWithFallback(text, color: color)
        }

        // SDL_ttf renders wrapped lines left-aligned only. For centered/right text we compose the
        // lines ourselves so each line is aligned within the wrap width.
        if wrapLength > 0 && alignment != .left {
            return renderWrapped(wrapLines(of: text, wrapLength: wrapLength), color: color, wrapLength: wrapLength, alignment: alignment)
        }

        guard
            let surface = (wrapLength > 0) ?
                TTF_RenderUTF8_Blended_Wrapped(rawPointer, text, color.sdlColor, UInt32(wrapLength)) :
                TTF_RenderUTF8_Blended(rawPointer, text, color.sdlColor)
            else { return nil }

        defer { SDL_FreeSurface(surface) }
        return CGImage(surface: surface)
    }

    /// Returns `text` truncated with a trailing ellipsis so it fits within `maxWidth` (pixels).
    /// Returns `text` unchanged when it already fits (or `maxWidth <= 0`).
    func truncatedText(_ text: String, toWidth maxWidth: Int) -> String {
        guard maxWidth > 0 else { return text }

        var width: Int32 = 0
        var height: Int32 = 0
        TTF_SizeUTF8(rawPointer, text, &width, &height)
        if Int(width) <= maxWidth { return text }

        let ellipsis = "…"
        var characters = Array(text)
        while !characters.isEmpty {
            characters.removeLast()
            let candidate = String(characters) + ellipsis
            TTF_SizeUTF8(rawPointer, candidate, &width, &height)
            if Int(width) <= maxWidth { return candidate }
        }
        return ellipsis
    }

    /// Greedily wraps `text` into lines that each fit within `wrapLength` (pixels), breaking on
    /// spaces and honouring explicit newlines. Matches the line breaking counted by `multilineSize`.
    func wrapLines(of text: String, wrapLength: Int) -> [String] {
        guard wrapLength > 0 else { return [text] }

        var lines: [String] = []
        for paragraph in text.components(separatedBy: "\n") {
            var currentLine = ""
            for word in paragraph.split(separator: " ", omittingEmptySubsequences: false).map(String.init) {
                let candidate = currentLine.isEmpty ? word : currentLine + " " + word
                var candidateWidth: Int32 = 0
                var candidateHeight: Int32 = 0
                TTF_SizeUTF8(rawPointer, candidate, &candidateWidth, &candidateHeight)

                if currentLine.isEmpty || Int(candidateWidth) <= wrapLength {
                    currentLine = candidate
                } else {
                    lines.append(currentLine)
                    currentLine = word
                }
            }
            lines.append(currentLine)
        }
        return lines
    }

    /// Composes pre-wrapped `lines` into a single surface of `wrapLength` width, positioning each
    /// line according to `alignment`.
    private func renderWrapped(_ lines: [String], color: UIColor, wrapLength: Int, alignment: NSTextAlignment) -> CGImage? {
        let lineSpacing: Int32 = 2
        let lineHeight = TTF_FontHeight(rawPointer)
        let totalHeight = Int(lineHeight) * lines.count + Int(lineSpacing) * (lines.count - 1)
        guard totalHeight > 0 else { return nil }

        guard let target = SDL_CreateRGBSurfaceWithFormat(
            0, Int32(wrapLength), Int32(totalHeight), 32, UInt32(SDL_PIXELFORMAT_ARGB8888)
        ) else { return nil }
        defer { SDL_FreeSurface(target) }

        for (index, line) in lines.enumerated() {
            guard !line.isEmpty, let surface = TTF_RenderUTF8_Blended(rawPointer, line, color.sdlColor) else { continue }
            defer { SDL_FreeSurface(surface) }

            SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE)
            let lineWidth = surface.pointee.w
            let x: Int32
            switch alignment {
            case .center: x = (Int32(wrapLength) - lineWidth) / 2
            case .right: x = Int32(wrapLength) - lineWidth
            case .left: x = 0
            }
            var dstRect = SDLRect(x: max(0, x), y: Int32(index) * (lineHeight + lineSpacing), w: lineWidth, h: surface.pointee.h)
            SDL_UpperBlit(surface, nil, target, &dstRect)
        }

        return CGImage(surface: target)
    }

    private func renderWithFallback(_ text: String, color: UIColor) -> CGImage? {
        var runs: [(font: UnsafeMutablePointer<TTF_Font>, text: String)] = []
        for scalar in text.unicodeScalars {
            let font = fontForGlyph(scalar.value) ?? rawPointer

            if let last = runs.last, last.font == font {
                runs[runs.count - 1].text.append(String(scalar))
            } else {
                runs.append((font: font, text: String(scalar)))
            }
        }

        if runs.count == 1 {
            guard let surface = TTF_RenderUTF8_Blended(runs[0].font, runs[0].text, color.sdlColor) else { return nil }
            defer { SDL_FreeSurface(surface) }
            return CGImage(surface: surface)
        }

        let (totalWidth, totalHeight) = size(text)
        guard totalWidth > 0, totalHeight > 0 else { return nil }

        guard let target = SDL_CreateRGBSurfaceWithFormat(
            0, totalWidth, totalHeight, 32, UInt32(SDL_PIXELFORMAT_ARGB8888)
        ) else { return nil }
        defer { SDL_FreeSurface(target) }

        var x: Int32 = 0
        for run in runs {
            guard let surface = TTF_RenderUTF8_Blended(run.font, run.text, color.sdlColor) else { continue }
            defer { SDL_FreeSurface(surface) }

            SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE)
            var dstRect = SDLRect(x: x, y: 0, w: surface.pointee.w, h: surface.pointee.h)
            SDL_UpperBlit(surface, nil, target, &dstRect)
            x += surface.pointee.w
        }

        return CGImage(surface: target)
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

// MARK: Multi-font (styled-run) text

/// Lightweight multi-font text: a sequence of (text, font) runs rendered inline with word
/// wrapping and alignment. Fills the gap left by not having NSAttributedString in this polyfill,
/// e.g. a bold label followed by a regular value on the same wrapping line.
@MainActor
public struct StyledTextRun {
    public let text: String
    public let font: UIFont

    public init(_ text: String, font: UIFont) {
        self.text = text
        self.font = font
    }
}

@MainActor
extension FontRenderer {
    private struct WordToken {
        let text: String
        let renderer: FontRenderer
        let width: Int32
        let spaceWidth: Int32
        let height: Int32
    }

    private static let styledLineSpacing: Int32 = 2

    /// Splits runs into space-separated words, each tagged with its own font renderer/metrics.
    private static func tokenize(_ runs: [StyledTextRun]) -> [WordToken] {
        var tokens: [WordToken] = []
        for run in runs {
            guard let renderer = run.font.fontRenderer else { continue }

            var spaceWidth: Int32 = 0
            var spaceHeight: Int32 = 0
            TTF_SizeUTF8(renderer.rawPointer, " ", &spaceWidth, &spaceHeight)

            for word in run.text.split(separator: " ", omittingEmptySubsequences: true).map(String.init) {
                var width: Int32 = 0
                var height: Int32 = 0
                TTF_SizeUTF8(renderer.rawPointer, word, &width, &height)
                tokens.append(WordToken(text: word, renderer: renderer, width: width, spaceWidth: spaceWidth, height: height))
            }
        }
        return tokens
    }

    private static func wrap(_ tokens: [WordToken], wrapLength: Int) -> [[WordToken]] {
        guard wrapLength > 0 else { return tokens.isEmpty ? [] : [tokens] }

        var lines: [[WordToken]] = []
        var currentLine: [WordToken] = []
        var currentWidth: Int32 = 0

        for token in tokens {
            let addedWidth = currentLine.isEmpty ? token.width : token.spaceWidth + token.width
            if !currentLine.isEmpty && Int(currentWidth + addedWidth) > wrapLength {
                lines.append(currentLine)
                currentLine = [token]
                currentWidth = token.width
            } else {
                currentLine.append(token)
                currentWidth += addedWidth
            }
        }
        if !currentLine.isEmpty { lines.append(currentLine) }
        return lines
    }

    private static func lineWidth(_ line: [WordToken]) -> Int32 {
        line.enumerated().reduce(0) { result, item in
            result + (item.offset == 0 ? 0 : item.element.spaceWidth) + item.element.width
        }
    }

    static func styledRunsSize(_ runs: [StyledTextRun], wrapLength: Int) -> CGSize {
        let tokens = tokenize(runs)
        guard !tokens.isEmpty else { return .zero }

        let lineHeight = tokens.map { $0.height }.max() ?? 0

        if wrapLength <= 0 {
            return CGSize(width: Int(lineWidth(tokens)), height: Int(lineHeight))
        }

        let lines = wrap(tokens, wrapLength: wrapLength)
        let height = Int(lineHeight) * lines.count + Int(styledLineSpacing) * max(0, lines.count - 1)
        return CGSize(width: wrapLength, height: height)
    }

    static func renderStyledRuns(_ runs: [StyledTextRun], color: UIColor, wrapLength: Int, alignment: NSTextAlignment) -> CGImage? {
        let tokens = tokenize(runs)
        guard !tokens.isEmpty else { return nil }

        let lineHeight = tokens.map { $0.height }.max() ?? 0
        let lines = wrapLength > 0 ? wrap(tokens, wrapLength: wrapLength) : [tokens]
        let surfaceWidth = wrapLength > 0 ? Int32(wrapLength) : lineWidth(tokens)
        let totalHeight = lineHeight * Int32(lines.count) + styledLineSpacing * Int32(max(0, lines.count - 1))
        guard surfaceWidth > 0, totalHeight > 0 else { return nil }

        guard let target = SDL_CreateRGBSurfaceWithFormat(
            0, surfaceWidth, totalHeight, 32, UInt32(SDL_PIXELFORMAT_ARGB8888)
        ) else { return nil }
        defer { SDL_FreeSurface(target) }

        for (lineIndex, line) in lines.enumerated() {
            var x: Int32
            switch alignment {
            case .center: x = (surfaceWidth - lineWidth(line)) / 2
            case .right: x = surfaceWidth - lineWidth(line)
            case .left: x = 0
            }
            let y = Int32(lineIndex) * (lineHeight + styledLineSpacing)

            for (index, token) in line.enumerated() {
                if index > 0 { x += token.spaceWidth }
                if let surface = TTF_RenderUTF8_Blended(token.renderer.rawPointer, token.text, color.sdlColor) {
                    SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE)
                    var destination = SDLRect(x: max(0, x), y: y, w: surface.pointee.w, h: surface.pointee.h)
                    SDL_UpperBlit(surface, nil, target, &destination)
                    SDL_FreeSurface(surface)
                }
                x += token.width
            }
        }

        return CGImage(surface: target)
    }
}
