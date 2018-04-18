//
//  UIScreen.swift
//  UIKit
//
//  Created by Chris on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIScreen {
    public let bounds: CGRect
    public let scale: CGFloat

    init(bounds: CGRect, scale: CGFloat) {
        self.bounds = bounds
        self.scale = scale
    }
}

public extension UIScreen {
    public static let main: UIScreen = {
        #if !DEBUG
        // Crash in production when accessing this without a rootView.
        if SDL.rootView == nil {
            preconditionFailure("Tried to get UIScreen.main dimensions, but no rootView exists")
        }
        #endif

        // Otherwise a fallback value e.g. in XCTests, so we don't need to initialize all of SDL:
        return UIScreen(
            bounds: SDL.rootView?.bounds ?? CGRect(x: 0, y: 0, width: 1024, height: 768),
            scale: SDL.rootView?.layer.contentsScale ?? 2.0
        )
    }()
}
