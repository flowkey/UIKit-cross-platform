//
//  NSAttributedStringKey.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(Android)
import Foundation

extension NSAttributedString.Key {
    public static let kern = NSAttributedString.Key(rawValue: "NSKern")
    public static let foregroundColor = NSAttributedString.Key(rawValue: "NSColor")
}

#endif
