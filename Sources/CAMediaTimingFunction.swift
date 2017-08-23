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

public class CAMediaTimingFunction {
    private let timing: (CGFloat) -> CGFloat

    init(name: String) {
        switch name {
        case kCAMediaTimingFunctionLinear: timing = CAMediaTimingFunction.linear
        case kCAMediaTimingFunctionEaseIn: timing = CAMediaTimingFunction.easeInCubic
        case kCAMediaTimingFunctionEaseOut: timing = CAMediaTimingFunction.easeOutCubic
        case kCAMediaTimingFunctionEaseInEaseOut: timing = CAMediaTimingFunction.easeInOutCubic
        case kCAMediaTimingFunctionDefault: timing = CAMediaTimingFunction.easeOutCubic
        default: fatalError("invalid name")
        }
    }

    subscript(at x: CGFloat) -> CGFloat {
        return timing(x)
    }
}

extension CAMediaTimingFunction {
    static func timingFunction(from options: UIViewAnimationOptions) -> CAMediaTimingFunction? {
        if options.contains(.curveEaseIn) {
            return CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        } else if options.contains(.curveEaseOut) {
            return CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        } else if options.contains(.curveEaseInOut) {
            return CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        }

        return nil
    }
}

fileprivate extension CAMediaTimingFunction {
    static func linear(_ x: CGFloat) -> CGFloat { return x }
    static func easeInCubic(_ x: CGFloat) -> CGFloat { return pow(x, 3) }
    static func easeOutCubic(_ x: CGFloat) -> CGFloat { return x * (2-x) }
    static func easeInOutCubic(_ x: CGFloat) -> CGFloat {
        return x < 0.5 ? 4*pow(x, 3) : (x-1)*pow((2*x-2), 2)+1
    }
}
