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
    @_exported @testable import UIKit
    typealias Button = UIKit.Button
#endif

typealias CGRect = UIKit.CGRect
typealias CALayer = UIKit.CALayer
typealias CABasicAnimation = UIKit.CABasicAnimation
typealias CAMediaTimingFunction = UIKit.CAMediaTimingFunction
typealias UIView = UIKit.UIView
typealias UIScrollView = UIKit.UIScrollView
typealias UIScrollViewDelegate = UIKit.UIScrollViewDelegate
typealias UIPanGestureRecognizer = UIKit.UIPanGestureRecognizer
typealias UIEdgeInsets = UIKit.UIEdgeInsets
typealias CGImage = UIKit.CGImage
typealias UIImage = UIKit.UIImage
typealias UITouch = UIKit.UITouch
typealias UIEvent = UIKit.UIEvent
typealias CGSize = UIKit.CGSize
typealias CGFloat = UIKit.CGFloat
typealias CGPoint = UIKit.CGPoint
typealias NSAttributedString = UIKit.NSAttributedString

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
