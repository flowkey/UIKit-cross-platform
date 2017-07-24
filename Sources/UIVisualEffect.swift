//
//  UIVisualEffect.swift
//  UIKit
//
//  Created by Chris on 24.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public class UIVisualEffect {}

public class UIBlurEffect: UIVisualEffect {
    public init(style: UIBlurEffectStyle) {}
}

public enum UIBlurEffectStyle {
    case extraLight
    case light
    case dark
}
