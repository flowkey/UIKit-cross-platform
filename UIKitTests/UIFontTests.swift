//
//  UIFontTests.swift
//  UIKitTests
//
//  Created by Geordie Jay on 10.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import XCTest

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
