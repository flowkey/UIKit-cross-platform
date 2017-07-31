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
    @testable import UIKit
#endif

@objc(TestSetup) class TestSetup: NSObject {
    override init() {
        #if os(iOS)
            loadCustomFont(name: "roboto-medium", fontExtension: "ttf")
        #else
            UIFont.loadSystemFonts()
        #endif
    }
}
