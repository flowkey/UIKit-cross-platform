//
//  AnimatableProperty.swift
//  UIKit
//
//  Created by Michael Knoch on 15.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public protocol AnimatableProperty {}

extension CGColor: AnimatableProperty {
    func interpolation(to endResult: CGColor, progress: CGFloat) -> CGColor {
        let startR = Int(red)
        let startG = Int(green)
        let startB = Int(blue)
        let startA = Int(alpha)

        let endR = Int(endResult.red)
        let endG = Int(endResult.green)
        let endB = Int(endResult.blue)
        let endA = Int(endResult.alpha)

        let currentProgress = Int(progress.normalisedToUInt8())
        let maxProgress = Int(UInt8.max)

        
        let resultR = abs(startR + (endR - startR) * currentProgress / maxProgress)
        let resultG = abs(startG + (endG - startG) * currentProgress / maxProgress)
        let resultB = abs(startB + (endB - startB) * currentProgress / maxProgress)
        let resultA = abs(startA + (endA - startA) * currentProgress / maxProgress)

        return CGColor((
            r: UInt8(resultR),
            g: UInt8(resultG),
            b: UInt8(resultB),
            a: UInt8(resultA)
        ))
    }
}

extension CGRect: AnimatableProperty {}
extension CGPoint: AnimatableProperty {}
extension Float: AnimatableProperty {}
extension CATransform3D: AnimatableProperty {}
