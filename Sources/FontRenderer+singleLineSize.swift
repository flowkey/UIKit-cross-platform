//
//  FontRenderer+singleLineSize.swift
//  UIKit
//
//  Created by Geordie Jay on 17.05.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

@_implementationOnly import SDL_ttf

extension FontRenderer {
    // From `TTF_HANDLE_STYLE_BOLD`
    var fontRequiresManualBoldHandling: Bool {
        return (
            rawPointer.pointee.style & TTF_STYLE_BOLD != 0
                && rawPointer.pointee.face_style & TTF_STYLE_BOLD == 0
        )
    }

    // From `TTF_HANDLE_STYLE_UNDERLINE`
    var fontRequiresManualUnderlineHandling: Bool {
        return rawPointer.pointee.style & TTF_STYLE_UNDERLINE != 0
    }

    private var fontUnderlineTopYPosition: Int32 {
        // With outline, the underline_offset is underline_offset + outline.
        // So, we don't have to remove the top part of the outline height.
        return rawPointer.pointee.ascent - rawPointer.pointee.underline_offset - 1
    }

    private var fontUnderlineBottomYPosition: Int32 {
        let row = fontUnderlineTopYPosition + rawPointer.pointee.underline_height
        return row + (rawPointer.pointee.outline * 2)
    }

    // From `FT_HAS_KERNING`
    var fontHasKerning: Bool {
        return (
            rawPointer.pointee.face.pointee.face_flags & FT_FACE_FLAG_KERNING != 0
                && rawPointer.pointee.kerning != 0
        )
    }

    func size(_ text: String) -> (width: Int32, height: Int32) {
        var minX: Int32 = 0
        var maxX: Int32 = 0
        var minY: Int32 = 0
        var maxY: Int32 = 0

        let outlineWidth = rawPointer.pointee.outline
        let outlineDelta = outlineWidth * 2 // could be 0

        var x: Int32 = 0
        var previousGlyphIndex: FT_UInt? = nil

        // Load each character and sum its bounding box
        for currentGlyph in freetypeGlyphs(in: text) {
            x += getFontKerningOffset(between: previousGlyphIndex, and: currentGlyph.index)
            previousGlyphIndex = currentGlyph.index

            minX = min(minX, x + currentGlyph.minx)

            if fontRequiresManualBoldHandling {
                x += rawPointer.pointee.glyph_overhang
            }

            maxX = max(maxX, x + max(currentGlyph.advance, currentGlyph.maxx))

            minY = min(minY, currentGlyph.miny)
            maxY = max(maxY, currentGlyph.maxy)

            x += currentGlyph.advance
        }


        let width = (maxX - minX) + outlineDelta

        // Some fonts descend below font height (e.g. FletcherGothicFLF)
        let fontHeight = rawPointer.pointee.height
        let measuredHeight = max(fontHeight, (rawPointer.pointee.ascent - minY) + outlineDelta)

        // Update height if necessary according to underline style
        if fontRequiresManualUnderlineHandling {
            return (width: width, height: max(fontUnderlineBottomYPosition, measuredHeight))
        }

        return (width: width, height: measuredHeight)
    }


    func freetypeGlyphs(in string: String) -> UnfoldSequence<c_glyph, String.UnicodeScalarView.Iterator> {
        return sequence(state: string.unicodeScalars.makeIterator(), next: { [weak self] unicodeScalars -> c_glyph? in
            guard let `self` = self else { return nil }

            var characterCode: UInt32 = 0
            while true {
                guard let nextScalar = unicodeScalars.next() else { return nil }

                characterCode = nextScalar.value

                // Skip BOM characters:
                if characterCode != UNICODE_BOM_NATIVE && characterCode != UNICODE_BOM_SWAPPED {
                    break
                }
            }

            guard Find_Glyph(self.rawPointer, characterCode, CACHED_METRICS) == 0 else {
                assertionFailure("Glyph \(characterCode) ('\(Character(UnicodeScalar(characterCode)!))') could not be found")
                return nil
            }

            let glyph = self.rawPointer.pointee.current.pointee

            let spaceCharacterCode = 32
            let newLineCharacterCode = 10
            if characterCode != spaceCharacterCode, characterCode != newLineCharacterCode, glyph.maxx - glyph.minx <= 0 {
                assertionFailure("Glyph \(characterCode) ('\(Character(UnicodeScalar(characterCode)!))') has no width")
                return nil
            }

            return glyph
        })
    }
}
