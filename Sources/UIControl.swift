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

public struct UIControlState: OptionSet, Hashable {
    public var rawValue: Int

    public var hashValue: Int {
        return rawValue.hashValue
    }

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let normal = UIControlState(rawValue: 1 << 0)
    public static let highlighted = UIControlState(rawValue: 1 << 1)
    public static let selected = UIControlState(rawValue: 1 << 2)
    public static let disabled = UIControlState(rawValue: 1 << 3)

    public static func == (lhs: UIControlState, rhs: UIControlState) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

// current minimal implementation of UIControl for content alignment in Button
open class UIControl: UIView {
    public var contentHorizontalAlignment: UIControlContentHorizontalAlignment = .center
    public var contentVerticalAlignment: UIControlContentVerticalAlignment = .center

    open var isEnabled = true
    open var isHighlighted = false
    open var isSelected = false

    public var state: UIControlState {
        var controlState: UIControlState = .normal
        if isHighlighted { controlState.formUnion(.highlighted) }
        if isSelected { controlState.formUnion(.selected) }
        if !isEnabled { controlState.formUnion(.disabled) }

        if controlState != [.normal] { // contains no other state
            controlState.subtract(.normal)
        }

        return controlState
    }
}
