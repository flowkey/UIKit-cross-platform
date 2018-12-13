//
//  NSAttributedStringKey.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(Android)
import struct Foundation.NSAttributedStringKey


extension NSAttributedStringKey {
    public static let kern = NSAttributedStringKey(rawValue: "NSKern")
    public static let foregroundColor = NSAttributedStringKey(rawValue: "NSColor")
}

extension NSAttributedString {
    public typealias Key = NSAttributedStringKey
}

#endif
