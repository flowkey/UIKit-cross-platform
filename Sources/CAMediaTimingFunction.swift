//
//  CAMediaTimingFunction.swift
//  UIKit
//
//  Created by Michael Knoch on 22.08.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import func Foundation.pow

public let kCAMediaTimingFunctionLinear = "linear"
public let kCAMediaTimingFunctionEaseIn = "easeIn"
public let kCAMediaTimingFunctionEaseOut = "easeOut"
public let kCAMediaTimingFunctionEaseInEaseOut = "easeInEaseOut"
public let kCAMediaTimingFunctionDefault = "default"
let kCAMediaTimingFunctionCustomEaseOut = "customEaseOut"

public class CAMediaTimingFunction {
    private let timing: (CGFloat) -> CGFloat

    init(name: String) {
        switch name {
        case kCAMediaTimingFunctionLinear: timing = CAMediaTimingFunction.linear
        case kCAMediaTimingFunctionEaseIn: timing = CAMediaTimingFunction.easeInCubic
        case kCAMediaTimingFunctionEaseOut: timing = CAMediaTimingFunction.easeOutQuad
        case kCAMediaTimingFunctionCustomEaseOut: timing = CAMediaTimingFunction.customEaseOut
        case kCAMediaTimingFunctionEaseInEaseOut, kCAMediaTimingFunctionDefault:
            timing = CAMediaTimingFunction.easeInOutCubic
        default: fatalError("invalid name in CAMediaTimingFunction init")
        }
    }

    subscript(at x: CGFloat) -> CGFloat {
        return timing(x)
    }
}

extension CAMediaTimingFunction {
    static func linear(_ x: CGFloat) -> CGFloat { return x }
    static func easeInCubic(_ x: CGFloat) -> CGFloat { return pow(x, 3) }
    static func easeOutCubic(_ x: CGFloat) -> CGFloat { 
        let t = x - 1
        return (t*t*t + 1)
    }
    static func easeInQuad(_ x: CGFloat) -> CGFloat { return pow(x, 2) }
    static func easeOutQuad(_ x: CGFloat) -> CGFloat { return x*(2-x) }
    static func easeInOutCubic(_ x: CGFloat) -> CGFloat {
        return x < 0.5 ? 2*pow(x, 2) : -1+(4-2*x)*x
    }

    // from CubicBezier1D optimising away constant terms
    static func customEaseOut(_ x: CGFloat) -> CGFloat {
        let term1 = UIScrollViewDecelerationRateNormal * 3 * x * pow(1 - x, 2)
        let term2 = 3 * pow(x, 2) * (1 - x)
        let term3 = pow(x, 3)

        return term1 + term2 + term3
    }
}
