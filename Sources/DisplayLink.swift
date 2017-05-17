//
//  DisplayLink.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//


/// This is just a cheap wrapper for now that will break any previous instances upon setting `callback`!
open class DisplayLink {
    public init() {}

    public var isPaused = true {
        didSet {
            SDL.update = isPaused ? nil : callback
        }
    }

    public var callback: (() -> Void)? {
        didSet {
            let wasPaused = isPaused
            isPaused = wasPaused // set or remove `SDL.update`
        }
    }

    public func invalidate() {
        callback = nil
    }
}
