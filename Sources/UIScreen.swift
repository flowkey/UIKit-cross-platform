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
    public static let main = UIScreen(size: SDL.window.size, scale: SDL.window.scale)
}
