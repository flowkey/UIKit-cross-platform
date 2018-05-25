//
//  NSAttributedStringKey.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import struct Foundation.NSAttributedStringKey
public typealias NSAttributedStringKey = Foundation.NSAttributedStringKey

#if os(Android)
extension NSAttributedStringKey {
    public static let kern = NSAttributedStringKey(rawValue: "NSKern")
    public static let foregroundColor = NSAttributedStringKey(rawValue: "NSColor")
}
#endif
