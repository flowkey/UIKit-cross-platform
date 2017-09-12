//
//  UIScreen.swift
//  UIKit
//
//  Created by Chris on 08.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

// everything with a larger height is a tablet
let HEIGHT_LIMIT_FOR_PHONES: CGFloat = 800

public class UIScreen {
    var size: CGSize
    init(size: CGSize) {
        self.size = size
    }
}

public extension UIScreen {
    public static var main = UIScreen(size: SDL.window.size)
    public static var isTablet = main.size.height > HEIGHT_LIMIT_FOR_PHONES
    public static var isPhone = !isTablet
}
