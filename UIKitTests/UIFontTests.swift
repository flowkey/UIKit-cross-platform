//
//  UIFontTests.swift
//  UIKitTests
//
//  Created by Geordie Jay on 10.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest
#if !os(iOS)
@testable import UIKit // access the polyfill's internal text-rendering helpers
#endif

@MainActor
class UIFontTests: XCTestCase {
    let testFont = UIFont.systemFont(ofSize: 16)

    let singleLineText = "Text with single line"
    let multilineText = """
        Text with three lines
        which is a bit longer
        than the first one.
        """

    func testGetSingleLineTextSize() {
        let calculatedSize = singleLineText.size(with: testFont)
        XCTAssert(calculatedSize.width > 0)
        XCTAssertEqual(calculatedSize.height, testFont.lineHeight)
    }

    func testGetWrappedMultilineTextSize() {
        let wrapLength: CGFloat = 200
        let calculatedSize = multilineText.size(with: testFont, wrapLength: wrapLength)
        XCTAssertEqual(calculatedSize.width, CGFloat(wrapLength))

        let numberOfLines = CGFloat(multilineText.numberOfLines())

        // SDL_ttf adds an additional 2px per line on top of the font's line height
        // We are testing on retina devices, so 2px becomes 1px after reducing down:
        let extraSDLTTFPadding: CGFloat = 1

        let expectedHeight = testFont.lineHeight * numberOfLines + (numberOfLines - 1) * extraSDLTTFPadding
        XCTAssertEqual(calculatedSize.height, expectedHeight)
    }
}


private extension String {
    func numberOfLines() -> UInt {
        if self.isEmpty { return 0 }

        // We start at 1 line and increase for every newline char
        return self.reduce(1, { total, char in total + ((char == "\n") ? 1 : 0) })
    }
}

#if !os(iOS)
@MainActor
class FontMetricsTests: XCTestCase {
    func testCapHeightUsesCapitalHGlyphMetrics() throws {
        try withTestRenderer(glyphEncoding: "H") { renderer in
            XCTAssertEqual(renderer.getAscent(), 12)
            XCTAssertEqual(renderer.getDescent(), -4)
            XCTAssertEqual(renderer.getCapHeight(), 7)
        }
    }

    func testCapHeightFallsBackToAscentWhenCapitalHIsMissing() throws {
        try withTestRenderer(glyphEncoding: "A") { renderer in
            XCTAssertEqual(renderer.getAscent(), 12)
            XCTAssertEqual(renderer.getCapHeight(), 12)
        }
    }

    private func withTestRenderer(glyphEncoding: Unicode.Scalar, body: (FontRenderer) -> Void) throws {
        // The fallback glyph is 7 pixels high, distinct from the 12-pixel ascent.
        // Mapping it to A instead of H reproduces successful .notdef measurement.
        let font = """
            STARTFONT 2.1
            FONT -UIKit-Metrics-Medium-R-Normal--16-160-75-75-C-80-ISO10646-1
            SIZE 16 75 75
            FONTBOUNDINGBOX 8 16 0 -4
            STARTPROPERTIES 5
            FONT_ASCENT 12
            FONT_DESCENT 4
            DEFAULT_CHAR \(glyphEncoding.value)
            CHARSET_REGISTRY "ISO10646"
            CHARSET_ENCODING "1"
            ENDPROPERTIES
            CHARS 1
            STARTCHAR test
            ENCODING \(glyphEncoding.value)
            SWIDTH 500 0
            DWIDTH 8 0
            BBX 8 7 0 0
            BITMAP
            FF
            81
            81
            FF
            81
            81
            FF
            ENDCHAR
            ENDFONT

            """
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("UIKitFontMetrics-\(UUID().uuidString).bdf")
        try font.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let provider = try XCTUnwrap(UIKit.CGDataProvider(filepath: url.path))
        try withExtendedLifetime(provider) {
            let renderer = try XCTUnwrap(FontRenderer(provider, size: 16))
            body(renderer)
        }
    }
}

/// Tests for the text-rendering helpers this UIKit polyfill adds on top of SDL_ttf:
/// single-line ellipsis truncation, greedy word wrapping, and attributed (multi-font) text.
/// These only exercise measurement (`TTF_SizeUTF8`), so they need no GPU/render target.
@MainActor
class TextRenderingTests: XCTestCase {
    // The font is loaded by TestSetup; `fontRenderer` is the SDL_ttf backend used for measuring.
    private var renderer: FontRenderer { UIFont.systemFont(ofSize: 16).fontRenderer! }

    // MARK: Truncation (numberOfLines == 1 + .byTruncatingTail)

    func testTruncatedTextIsUnchangedWhenItFits() {
        let text = "Short"
        let wideEnough = renderer.singleLineSize(of: text).width + 100
        XCTAssertEqual(renderer.truncateTextIfNeeded(text, wrapLength: wideEnough), text)
    }

    func testTruncatedTextAddsEllipsisAndFitsWithinWidth() {
        let text = "A line long enough that it must be truncated to fit"
        let half = renderer.singleLineSize(of: text).width / 2

        let result = renderer.truncateTextIfNeeded(text, wrapLength: half)
        XCTAssertNotEqual(result, text)
        XCTAssertTrue(result.hasSuffix("…"))
        XCTAssertLessThanOrEqual(renderer.singleLineSize(of: result).width, half)
    }

    func testTruncatedTextReturnsInputForNonPositiveWidth() {
        XCTAssertEqual(renderer.truncateTextIfNeeded("Hello", wrapLength: 0), "Hello")
    }

    // MARK: Word wrapping

    func testWrapLinesKeepsTextOnOneLineWhenItFits() {
        let text = "one two three"
        let wideEnough = Int(renderer.singleLineSize(of: text).width) + 100
        XCTAssertEqual(renderer.wrapLines(of: text, wrapLength: wideEnough), [text])
    }

    func testWrapLinesBreaksLongTextAcrossLinesKeepingEveryWord() {
        let text = "one two three four five six seven eight nine ten"
        let narrow = Int(renderer.singleLineSize(of: "one two three").width)

        let lines = renderer.wrapLines(of: text, wrapLength: narrow)
        XCTAssertGreaterThan(lines.count, 1)
        // Greedy word wrapping never drops or reorders words.
        XCTAssertEqual(lines.joined(separator: " "), text)
    }

    func testWrapLinesHonoursExplicitNewlines() {
        XCTAssertEqual(renderer.wrapLines(of: "first\nsecond\nthird", wrapLength: 10_000), ["first", "second", "third"])
    }

    // MARK: Attributed (multi-font) text

    func testMutableAttributedStringConcatenatesRuns() {
        let string = NSMutableAttributedString(string: "Composer: ", attributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
        string.append(NSAttributedString(string: "J. S. Bach", attributes: [.font: UIFont.systemFont(ofSize: 16)]))
        XCTAssertEqual(string.string, "Composer: J. S. Bach")
    }

    func testAttributedStringSizeHasPositiveDimensions() {
        let string = NSAttributedString(string: "Hello world", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        let size = FontRenderer.getAttributedStringSize(string, wrapLength: 0, defaultFont: .systemFont(ofSize: 16))
        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    func testAttributedStringSizeWrapsToWrapLengthAndGrowsTaller() {
        let string = NSAttributedString(string: "one two three four five six seven eight", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        let unwrapped = FontRenderer.getAttributedStringSize(string, wrapLength: 0, defaultFont: .systemFont(ofSize: 16))
        let wrapLength = Int(unwrapped.width / 3)

        let wrapped = FontRenderer.getAttributedStringSize(string, wrapLength: wrapLength, defaultFont: .systemFont(ofSize: 16))
        XCTAssertEqual(wrapped.width, CGFloat(wrapLength))
        XCTAssertGreaterThan(wrapped.height, unwrapped.height)
    }

    func testEmptyAttributedStringHasZeroSize() {
        let string = NSAttributedString(string: "", attributes: [.font: UIFont.systemFont(ofSize: 16)])
        XCTAssertEqual(FontRenderer.getAttributedStringSize(string, wrapLength: 0, defaultFont: .systemFont(ofSize: 16)), .zero)
    }
}
#endif
