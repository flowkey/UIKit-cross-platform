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

    public var callback: (() -> Void)! {
        didSet { updateActiveDisplayLinks() }
    }

    /// Whether this link should tick. Re-check it before each callback in a frame: a callback can
    /// pause or invalidate *another* link, and `activeDisplayLinks` is iterated as a snapshot.
    public var isActive: Bool { !isPaused && callback != nil }

    private func updateActiveDisplayLinks() {
        if isActive {
            DisplayLink.activeDisplayLinks.insert(self)
        } else {
            DisplayLink.activeDisplayLinks.remove(self)
        }
    }

    public func invalidate() {
        callback = nil
    }
}

extension DisplayLink: Hashable {
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }

    nonisolated public static func ==(lhs: DisplayLink, rhs: DisplayLink) -> Bool {
        return lhs === rhs
    }
}
