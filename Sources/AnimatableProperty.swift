//
//  AnimatableProperty.swift
//  UIKit
//
//  Created by Michael Knoch on 15.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public protocol AnimatableProperty {}

extension CGFloat: AnimatableProperty {}
extension Int: AnimatableProperty {}
extension Double: AnimatableProperty {}
