//
//  CGPath.swift
//  UIKit
//
//  Created by Geordie Jay on 30.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public typealias CGPath = CGRect

extension CGPath {
    public init(rect: CGRect, transform: CGAffineTransform?) {
        self = rect
    }
}
