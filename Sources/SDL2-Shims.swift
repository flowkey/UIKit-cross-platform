//
//  SDL2 Shims.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 05.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

@_implementationOnly import SDL

struct SDLError: Error {
    let description: String
    init() {
        // Get the error at time of throwing, otherwise another error could occur in the meantime:
        self.description = String(cString: __SDL_GetError())
    }
}

extension SDLDisplayMode {
    static var current: SDLDisplayMode? {
        var displayMode = SDLDisplayMode()
        guard __SDL_GetCurrentDisplayMode(0, &displayMode) == 0 else {
            return nil
        }
        
        return displayMode
    }
}

extension SDLBool {
    static let `true` = __SDL_TRUE
    static let `false` = __SDL_FALSE
}
