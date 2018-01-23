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

    init(size: CGSize, scale: CGFloat) {
        self.bounds = CGRect(origin: .zero, size: size)
        self.scale = scale
    }
}

public extension UIScreen {
    public static let main: UIScreen = {
        #if DEBUG // Use a fallback value e.g. in XCTests, so we don't need to initialize all of SDL
        let windowSize = SDL.window?.size ?? CGSize(width: 1024, height: 768)
        let windowScale = SDL.window?.scale ?? 2.0
        #else
        // These will crash if window doesn't exist:
        let windowSize = SDL.window.size
        let windowScale = SDL.window.scale
        #endif

        return UIScreen(size: windowSize, scale: windowScale)
    }()
}
