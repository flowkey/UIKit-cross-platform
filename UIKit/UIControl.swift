//
//  UIControl.swift
//  UIKit
//
//  Created by Chris on 30.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public enum UIControlContentHorizontalAlignment {
    case center
    case left
    case right
    // missing fill and leading (BETA) and trailing (BETA) from iOS UIKIt
}

public enum UIControlContentVerticalAlignment {
    case center
    case top
    case bottom
    // missing fill from iOS UIKIt
}

// current minimal implementation of UIControl for content alignment in Button
open class UIControl: UIView {
    public var contentHorizontalAlignment: UIControlContentHorizontalAlignment = .left
    public var contentVerticalAlignment: UIControlContentVerticalAlignment = .top
}
