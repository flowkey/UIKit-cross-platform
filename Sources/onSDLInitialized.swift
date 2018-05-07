//
//  onSDLInitialized.swift
//  UIKit
//
//  Created by Michael Knoch on 07.05.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

internal var sdlInitialized: (() -> Void)?

public func onSDLInitialized(callback: (() -> Void)?) {
    sdlInitialized = callback
    if SDL.isInitialized {
        sdlInitialized?()
    }
}
