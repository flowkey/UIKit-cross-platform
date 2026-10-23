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

    init(rotationAngle: CGFloat) {
        self.init(rotationByRadians: rotationAngle)
    }

    init(translationX: CGFloat, y: CGFloat) {
        self.init(translationByX: translationX, byY: y)
    }

    func scaledBy(x: CGFloat, y: CGFloat) -> CGAffineTransform {
        CGAffineTransform(scaleX: x, y: y).concatenated(self)
    }

    func translatedBy(x: CGFloat, y: CGFloat) -> CGAffineTransform {
        CGAffineTransform(translationX: x, y: y).concatenated(self)
    }

    var isIdentity: Bool {
        return self == .identity
    }
}
