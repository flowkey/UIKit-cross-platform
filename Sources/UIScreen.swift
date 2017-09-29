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
    var scale: CGFloat
    
    init(size: CGSize, scale: CGFloat) {
        self.size = size
        self.scale = scale
    }
}

public extension UIScreen {
    public static var main = UIScreen(size: SDL.window.size, scale: SDL.window.scale)
    public static var isTablet = main.size.height > HEIGHT_LIMIT_FOR_PHONES
    public static var isPhone = !isTablet
}
