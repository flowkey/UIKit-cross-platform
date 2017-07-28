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
            DisplayLink.removeDisplayLink(self)
        } else {
            DisplayLink.addDisplayLink(self)
        }
    }

    public func invalidate() {
        callback = nil
    }
}

extension DisplayLink {
    static var activeDisplayLinks: Set<DisplayLink> = []
    static func addDisplayLink(_ displayLink: DisplayLink) {
        activeDisplayLinks.insert(displayLink)
    }

    static func removeDisplayLink(_ displayLink: DisplayLink) {
        activeDisplayLinks.remove(displayLink)
    }
}

extension DisplayLink: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (lhs: DisplayLink, rhs: DisplayLink) -> Bool {
        return lhs === rhs
    }
}
