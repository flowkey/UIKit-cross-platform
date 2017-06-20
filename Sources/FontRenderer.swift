//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.ttf

let macSourcesDir: String = String(#file.characters.dropLast("FontRenderer.swift".characters.count)) + ".."

func initSDL_ttf() -> Bool {
    if TTF_WasInit() == 1 {
        return true
    }
    return TTF_Init() != -1
}

internal class FontRenderer {
    let rawPointer: OpaquePointer
    
    init?(name: String, size: CGFloat) {
        if initSDL_ttf() == false {
            return nil
        }

        let resourcesDir = macSourcesDir + "/Resources/"
        let pathToFontFile = resourcesDir + name + ".ttf"

        // TODO: get and add correct contentScaleFactor according to device later
        let contentScaleFactor = 2.0
        let adjustedFontSize = Int32(size * contentScaleFactor)
        
        let rwOp = SDL_RWFromFile(pathToFontFile, "rb")
        
        guard let font = TTF_OpenFontRW(rwOp, 1, adjustedFontSize) else { return nil }
        rawPointer = font
    }

    func getLineHeight() -> Int {
        return Int(TTF_FontHeight(rawPointer))
    }

    func size(of text: String) -> CGSize {
        let unicode16text = text.utf16.map { $0 }
        var width: Int32 = 0
        var height: Int32 = 0
        TTF_SizeUNICODE(rawPointer, unicode16text, &width, &height)

        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }

    func render(_ text: String?, color: UIColor, wrapLength: Int = 0) -> Texture? {
        guard let text = text else { return nil }
        let unicode16Text = text.utf16.map { $0 }

        guard
            let surface = (wrapLength > 0) ?
                TTF_RenderUNICODE_Blended_Wrapped(rawPointer, unicode16Text, color.sdlColor, UInt32(wrapLength)) :
                TTF_RenderUNICODE_Blended(rawPointer, unicode16Text, color.sdlColor)
        else {
            return nil
        }

        return Texture(surface: surface)
    }
}

