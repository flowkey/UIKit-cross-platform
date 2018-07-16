//
//  UIScreen.swift
//  UIKit
//
//  Created by Chris on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public final class UIScreen {
    public let bounds: CGRect
    public let scale: CGFloat

    init(bounds: CGRect, scale: CGFloat) {
        self.bounds = bounds
        self.scale = scale
    }
}

public extension UIScreen {
    public static var main: UIScreen {
        #if !DEBUG
        // Crash in production when accessing this without a glRenderer.
        if UIApplication.shared == nil {
            preconditionFailure("Tried to get UIScreen.main dimensions before calling `UIApplicationMain`!")
        }
        #endif

        // Otherwise a fallback value e.g. in XCTests, so we don't need to initialize all of SDL:
        return UIScreen(
            bounds: UIApplication.shared?.glRenderer.bounds ?? CGRect(origin: .zero, size: CGSize(width: 1024, height: 768)),
            scale: UIApplication.shared?.glRenderer.scale ?? 2.0
        )
    }
}
