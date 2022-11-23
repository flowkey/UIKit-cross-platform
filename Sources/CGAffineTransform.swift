//
//  CGAffineTransform.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public typealias CGAffineTransform = AffineTransform

public extension CGAffineTransform {
    init(scaleX: CGFloat, y: CGFloat) {
        self.init(scaleByX: scaleX, byY: y)
    }

    var isIdentity: Bool {
        return self == .identity
    }

}
