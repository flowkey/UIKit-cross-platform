//
//  Locale+languageCode.swift
//  UIKit
//
//  Created by Michael Knoch on 10.04.18.
//  Copyright © 2018 flowkey. All rights reserved.
//

import JNI
import struct Foundation.Locale

public typealias Locale = Foundation.Locale

public extension Locale {
    /// platform independent languageCode
    /// Returns the language code of the locale, or nil if has none.
    public var universalLanguageCode: String? {
        #if os(Android)
        return try? jni.call("getDeviceLanguage", on: getSDLView())
        #else
        return Locale.current.languageCode
        #endif
    }
}
