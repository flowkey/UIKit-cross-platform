//
//  DisplayLink.swift
//  UIKit
//
//  Created by Geordie Jay on 25.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class DisplayLink {
    static var activeDisplayLinks: Set<DisplayLink> = []

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
            DisplayLink.activeDisplayLinks.remove(self)
        } else {
            DisplayLink.activeDisplayLinks.insert(self)
        }
    }

    public func invalidate() {
        callback = nil
    }
}

extension DisplayLink: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    public static func == (lhs: DisplayLink, rhs: DisplayLink) -> Bool {
        return lhs === rhs
    }
}
