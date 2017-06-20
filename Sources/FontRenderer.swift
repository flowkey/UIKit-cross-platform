//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.ttf

let macSourcesDir: String = String(#file.characters.dropLast("FontLoader.swift".characters.count)) + ".."

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
        let pathToFontFile = resourcesDir + "/\(name)"
        
        let rwOp = SDL_RWFromFile(pathToFontFile, "rb")
        
        guard let font = TTF_OpenFontRW(rwOp, Int32(true), Int32(size)) else {
            return nil
        }
        
        rawPointer = font
    }
    
    func render(_ text: String, color: UIColor, wrapLength: Int = 0) -> Texture? {
        let unicode16Text = text.utf16.map { $0 }
        guard let surface = TTF_RenderUNICODE_Blended_Wrapped(rawPointer, unicode16Text, color.sdlColor, UInt32(wrapLength)) else {
            return nil
        }
        
        return Texture(surface: surface)
    }
}
