//
//  UIEvent.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import class Foundation.NSDate

enum UIEventPhase: String {
    case began, moved, ended
}

public class UIEvent {
    internal static var activeEvents = Set<UIEvent>()

    public var allTouches: Set<UITouch>?
    public let timestamp =  NSDate.timeIntervalSinceReferenceDate
    var phase: UIEventPhase = .began

    public init() {}

    init(from touch: UITouch) {
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
