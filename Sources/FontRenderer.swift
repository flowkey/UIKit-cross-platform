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

    /// Returns `text` truncated with a trailing ellipsis so it fits within `wrapLength` (pixels).
    /// Returns `text` unchanged when it already fits (or `wrapLength <= 0`).
    func truncateTextIfNeeded(_ text: String, wrapLength: Int) -> String {
        guard wrapLength > 0 else { return text }

        // Measure with `size(_:)`, the same ruler that sized the label. `TTF_SizeUTF8` measures
        // subtly differently, so a label sized to just fit could still be truncated here.
        if Int(size(text).width) <= wrapLength { return text }

        let ellipsis = "…"
        var characters = Array(text)
        while !characters.isEmpty {
            characters.removeLast()
            let candidate = String(characters) + ellipsis
            if Int(size(candidate).width) <= wrapLength { return candidate }
        }
        return ellipsis
    }

    /// Greedily wraps `text` into lines that each fit within `wrapLength` (pixels), breaking on
    /// spaces and honouring explicit newlines. Matches the line breaking counted by `multilineSize`.
    func wrapLines(of text: String, wrapLength: Int) -> [String] {
        guard wrapLength > 0 else { return [text] }

        var lines: [String] = []
        for paragraph in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
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
        let lineHeight = TTF_FontHeight(rawPointer)
        let height = Self.totalHeight(lineCount: lines.count, lineHeight: lineHeight)

        return composeImage(width: Int32(wrapLength), height: height) { target in
            for (index, line) in lines.enumerated() {
                guard !line.isEmpty, let surface = TTF_RenderUTF8_Blended(rawPointer, line, color.sdlColor) else { continue }
                defer { SDL_FreeSurface(surface) }

                let x = alignmentStartX(surfaceWidth: Int32(wrapLength), contentWidth: surface.pointee.w, alignment: alignment)
                blit(surface, onto: target, x: max(0, x), y: Int32(index) * (lineHeight + lineSpacing))
            }
        }
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
        return composeImage(width: totalWidth, height: totalHeight) { target in
            var x: Int32 = 0
            for run in runs {
                guard let surface = TTF_RenderUTF8_Blended(run.font, run.text, color.sdlColor) else { continue }
                defer { SDL_FreeSurface(surface) }

                blit(surface, onto: target, x: x, y: 0)
                x += surface.pointee.w
            }
        }
    }
}


// MARK: Get size of text for current font

extension FontRenderer {
    func singleLineSize(of text: String) -> CGSize {
        let (width, height) = size(text)
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
}

/// Horizontal start offset for content of `contentWidth` within `surfaceWidth`, per `alignment`.
private func alignmentStartX(surfaceWidth: Int32, contentWidth: Int32, alignment: NSTextAlignment) -> Int32 {
    switch alignment {
    case .center: return (surfaceWidth - contentWidth) / 2
    case .right: return surfaceWidth - contentWidth
    case .left: return 0
    }
}

/// Creates an ARGB target surface of `width`×`height`, lets `draw` composite glyph surfaces onto
/// it, and returns a `CGImage` copy. Returns nil for empty dimensions; the target is always freed.
private func composeImage(width: Int32, height: Int32, draw: (UnsafeMutablePointer<SDLSurface>) -> Void) -> CGImage? {
    guard width > 0, height > 0 else { return nil }
    guard let target = SDL_CreateRGBSurfaceWithFormat(0, width, height, 32, UInt32(SDL_PIXELFORMAT_ARGB8888)) else { return nil }
    defer { SDL_FreeSurface(target) }
    draw(target)
    return CGImage(surface: target)
}

/// Blits an already-rendered glyph `surface` onto `target` at (x, y) with no alpha blending.
private func blit(_ surface: UnsafeMutablePointer<SDLSurface>, onto target: UnsafeMutablePointer<SDLSurface>, x: Int32, y: Int32) {
    SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_NONE)
    var destination = SDLRect(x: x, y: y, w: surface.pointee.w, h: surface.pointee.h)
    SDL_UpperBlit(surface, nil, target, &destination)
}

/// Extra vertical padding between wrapped lines, matching SDL_ttf's own 2px inter-line gap.
private let lineSpacing: Int32 = 2

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
        let lineSpace = Int(lineSpacing)

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

// Not `@MainActor` — Foundation's `NSAttributedString` isn't isolated. The stored `UIFont` is only
// *used* (via `fontRenderer`) in `tokenize`, which runs on the main actor; holding the reference here
// needs no isolation. The default font is resolved lazily there to avoid a `@MainActor` call in init.
public class NSAttributedString {
    public struct Key: Hashable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let font = Key(rawValue: "NSFont")
    }

    struct Run {
        let text: String
        let font: UIFont?
    }

    var runs: [Run]
    public var string: String { runs.map(\.text).joined() }

    public init(string: String, attributes: [Key: Any] = [:]) {
        runs = [Run(text: string, font: attributes[.font] as? UIFont)]
    }
}

public final class NSMutableAttributedString: NSAttributedString {
    public func append(_ attributedString: NSAttributedString) {
        runs.append(contentsOf: attributedString.runs)
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

    /// Splits an attributed string into space-separated words, each tagged with its run's font.
    private static func tokenize(_ attributedString: NSAttributedString, defaultFont: UIFont) -> [WordToken] {
        var tokens: [WordToken] = []
        for run in attributedString.runs {
            let font = run.font ?? defaultFont
            guard let renderer = font.fontRenderer else { continue }

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

    private static func getLineWidth(_ line: [WordToken]) -> Int32 {
        line.enumerated().reduce(0) { result, item in
            result + (item.offset == 0 ? 0 : item.element.spaceWidth) + item.element.width
        }
    }

    /// Tokenizes and wraps `attributedString` (wrapLength 0 = a single unwrapped line). Returns the
    /// laid-out lines, their shared height, and the resulting surface width — or nil if empty.
    private static func layoutLines(_ attributedString: NSAttributedString, wrapLength: Int, defaultFont: UIFont) -> (lines: [[WordToken]], lineHeight: Int32, width: Int32)? {
        let tokens = tokenize(attributedString, defaultFont: defaultFont)
        guard !tokens.isEmpty else { return nil }

        let lineHeight = tokens.map(\.height).max() ?? 0
        let lines = wrapLength > 0 ? wrap(tokens, wrapLength: wrapLength) : [tokens]
        let width = wrapLength > 0 ? Int32(wrapLength) : getLineWidth(tokens)
        return (lines, lineHeight, width)
    }

    private static func totalHeight(lineCount: Int, lineHeight: Int32) -> Int32 {
        lineHeight * Int32(lineCount) + lineSpacing * Int32(max(0, lineCount - 1))
    }

    static func getAttributedStringSize(_ attributedString: NSAttributedString, wrapLength: Int, defaultFont: UIFont) -> CGSize {
        guard let layout = layoutLines(attributedString, wrapLength: wrapLength, defaultFont: defaultFont) else { return .zero }
        return CGSize(width: Int(layout.width), height: Int(totalHeight(lineCount: layout.lines.count, lineHeight: layout.lineHeight)))
    }

    static func renderAttributedString(_ attributedString: NSAttributedString, color: UIColor, wrapLength: Int, alignment: NSTextAlignment, defaultFont: UIFont) -> CGImage? {
        guard let layout = layoutLines(attributedString, wrapLength: wrapLength, defaultFont: defaultFont) else { return nil }
        let height = totalHeight(lineCount: layout.lines.count, lineHeight: layout.lineHeight)

        return composeImage(width: layout.width, height: height) { target in
            for (lineIndex, line) in layout.lines.enumerated() {
                var x = alignmentStartX(surfaceWidth: layout.width, contentWidth: getLineWidth(line), alignment: alignment)
                let y = Int32(lineIndex) * (layout.lineHeight + lineSpacing)

                for (index, token) in line.enumerated() {
                    if index > 0 { x += token.spaceWidth }
                    if let surface = TTF_RenderUTF8_Blended(token.renderer.rawPointer, token.text, color.sdlColor) {
                        defer { SDL_FreeSurface(surface) }
                        blit(surface, onto: target, x: max(0, x), y: y)
                    }
                    x += token.width
                }
            }
        }
    }
}
