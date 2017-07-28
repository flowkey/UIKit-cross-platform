//
//  UIVisualEffect.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIVisualEffect {}

public class UIBlurEffect: UIVisualEffect {
    public let style: UIBlurEffectStyle

    public init(style: UIBlurEffectStyle) {
        self.style = style
    }
}

public enum UIBlurEffectStyle {
    case extraLight
    case light
    case dark
}
