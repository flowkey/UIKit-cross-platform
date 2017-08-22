//
//  AnimatableProperty.swift
//  UIKit
//
//  Created by Michael Knoch on 15.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public protocol AnimatableProperty {}

extension CGRect: AnimatableProperty {}
extension CGFloat: AnimatableProperty {}
extension Int: AnimatableProperty {}
extension Double: AnimatableProperty {}

extension AnimatableProperty {
    /// Returns CGFloat if currentValue is numeric,
    /// returns nil if trying to cast from CGrect or non numeric values
    var cgFloat: CGFloat? {
        switch self {
        case let int as Int: return CGFloat(int)
        case let double as Double: return CGFloat(double)
        default: return nil
        }
    }
}
