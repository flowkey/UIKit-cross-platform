//
//  NSAttributedStringKey.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct NSAttributedStringKey: Hashable, RawRepresentable {
    public typealias RawValue = String
    public var rawValue: String
    public var hashValue: Int

    public init(rawValue: String) {
        self.rawValue = rawValue
        self.hashValue = rawValue.hashValue
    }

    public static func ==(lhs: NSAttributedStringKey, rhs: NSAttributedStringKey) -> Bool {
        return lhs == rhs
    }

    public static let kern = NSAttributedStringKey(rawValue: "NSKern")
    public static let foregroundColor = NSAttributedStringKey(rawValue: "NSColor")
}
