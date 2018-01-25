//
//  TestSetup.swift
//  UIKitTests
//
//  Created by Chris on 31.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Foundation
    @testable import UIKit
#endif

@objc(TestSetup) class TestSetup: NSObject {
    override init() {
        // TODO: The implementations of these two methods are almost identical,
        // we should make UIFont.loadSystemFonts work everywhere and just call it.
        #if os(iOS)
            FontLoader.loadBundledFonts()
        #else
            UIFont.loadSystemFonts()
        #endif
    }
}
