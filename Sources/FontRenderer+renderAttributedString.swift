//
//  FontRenderer+renderAttributedString.swift
//  UIKit
//
//  Created by Michael Knoch on 20.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

internal import SDL_ttf

extension FontRenderer {
    func getFontKerningOffset(between previousIndex: FT_UInt?, and currentIndex: FT_UInt) -> Int32 {
        guard let previousIndex = previousIndex, fontHasKerning else { return 0 }

        var delta = FT_Vector()
        FT_Get_Kerning(
            rawPointer.pointee.face,
            previousIndex,
            currentIndex,
            FT_KERNING_DEFAULT.rawValue,
            &delta
        )

        return Int32(delta.x >> 6)
    }
}
