//
//  FontLoader.swift
//  UIKit
//
//  Created by Geordie Jay on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL.ttf


internal class FontLoader {
    private init() {}
    lazy var shared: FontLoader = {
        let status = TTF_Init()
        if status == -1 {
            fatalError("Couldn't init SDL_ttf")
        }

        return FontLoader()
    }()
}
