//
//  SDL2 Shims.swift
//  sdl2testapinotes
//
//  Created by Geordie Jay on 05.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

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

extension SDLBool: ExpressibleByBooleanLiteral {
    static let `true` = __SDL_TRUE
    static let `false` = __SDL_FALSE

    public init(booleanLiteral value: Bool) {
        self = (value ? .true : .false)
    }
}

extension SDLRect: Equatable {
    public func intersects(_ other: SDLRect) -> Bool {
        var other = other
        return self.intersects(&other) == .true
    }

    public func intersection(with other: SDLRect) -> SDLRect {
        var other = other
        var result = SDLRect()
        self.intersection(with: &other, result: &result)
        return result
    }

    public static func == (lhs: SDLRect, rhs: SDLRect) -> Bool {
        var rhs = rhs
        return lhs.equals(&rhs) == .true
    }
}
