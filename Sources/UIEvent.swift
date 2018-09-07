//
//  UIEvent.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import struct Foundation.Date

public class UIEvent {
    internal static var activeEvents = Set<UIEvent>() // TEMP: not used
    internal static var touchEvent: UIEvent? // TEMP: this is used instead

    // TODO: think through approach to singleton touchEvent
    // perhaps implement eventTypes?
    // (currently, all events we get are touch events)

    public var allTouches: Set<UITouch>? // NOTE: why is this optional? isn't empty set enough?
    public let timestamp = Date.timeIntervalSinceReferenceDate

    public init() {}

    internal init(touch: UITouch) {
        allTouches = Set<UITouch>([touch])
    }
}

extension UIEvent: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }

    public static func == (lhs: UIEvent, rhs: UIEvent) -> Bool {
        return lhs === rhs
    }
}


