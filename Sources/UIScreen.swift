//
//  UIScreen.swift
//  UIKit
//
//  Created by Chris on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// everything with a larger height is a tablet
private let HEIGHT_LIMIT_FOR_PHONES: CGFloat = 800

public class UIScreen {
    public let size: CGSize
    public let scale: CGFloat

    init(size: CGSize, scale: CGFloat) {
        self.size = size
        self.scale = scale
    }
}

public extension UIScreen {
    public static let main = UIScreen(size: SDL.window.size, scale: SDL.window.scale)
    public static let isTablet = main.size.height > HEIGHT_LIMIT_FOR_PHONES
    public static let isPhone = !isTablet
}
