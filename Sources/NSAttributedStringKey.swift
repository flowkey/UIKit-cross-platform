//
//  NSAttributedStringKey.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if !os(Android)

import struct Foundation.NSAttributedStringKey
public typealias NSAttributedStringKey = Foundation.NSAttributedStringKey

#else

import class Foundation.NSMutableAttributedString

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

extension NSMutableAttributedString {
    open func addAttribute(_ name: NSAttributedStringKey, value: Any, range: NSRange) {
        self.addAttribute(name, value: value, range: range)
    }

    open func addAttributes(_ attrs: [NSAttributedStringKey : Any], range: NSRange) {
        attrs.forEach {
            self.addAttribute($0.key, value: $0.value, range: range)
        }
    }
}

#endif
