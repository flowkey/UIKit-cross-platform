//
//  CGAffineTransform.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct CGAffineTransform {
    public var a: CGFloat = 0
    public var b: CGFloat = 0
    public var c: CGFloat = 0
    public var d: CGFloat = 0
    public var tx: CGFloat = 0
    public var ty: CGFloat = 0

    public init(scaleX: CGFloat, y: CGFloat) {

    }

    public init() {

    }

    public static let identity = CGAffineTransform()
}
