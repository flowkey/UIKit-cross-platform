//
//  DisplayLink.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class DisplayLink {
    public init() {}

    public var isPaused = true {
        didSet { updateActiveDisplayLinks() }
    }

    // You'd have to call displayLink.callback() yourself to crash the program by this being nil
    public var callback: (() -> Void)! {
        didSet { updateActiveDisplayLinks() }
    }

    private func updateActiveDisplayLinks() {
        if isPaused || callback == nil {
            SDL.remove(displayLink: self)
        } else {
            SDL.add(displayLink: self)
        }
    }

    public func invalidate() {
        callback = nil
    }
}
