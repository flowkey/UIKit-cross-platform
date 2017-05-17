//
//  UIWindow.swift
//  UIKit
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIWindow: UIView {
    public static var main: UIWindow {
        return SDL.rootView
    }

    internal init() {
        super.init(frame: .zero)
    }
}
