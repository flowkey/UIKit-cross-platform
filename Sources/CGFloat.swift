//
//  CGFloat.swift
//  UIKit
//
//  Created by Chris on 19.06.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public typealias CGFloat = Double
public extension CGFloat {
    // This is needed because we sometimes try to convert doubles into CGFloats
    public init(_ value: Double) {
        self = value
    }
}
