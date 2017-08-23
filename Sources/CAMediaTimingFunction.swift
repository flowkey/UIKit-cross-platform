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

private struct InvalidNameError: Error {}

public class CAMediaTimingFunction {
    private var timing: (CGFloat) -> CGFloat

    init(name: String) throws {
        switch name {
        case kCAMediaTimingFunctionLinear: timing = CAMediaTimingFunction.linear
        case kCAMediaTimingFunctionEaseIn: timing = CAMediaTimingFunction.easeInCubic
        case kCAMediaTimingFunctionEaseOut: timing = CAMediaTimingFunction.easeOutCubic
        case kCAMediaTimingFunctionEaseInEaseOut: timing = CAMediaTimingFunction.easeInOutCubic
        case kCAMediaTimingFunctionDefault: timing = CAMediaTimingFunction.easeOutCubic
        default: throw InvalidNameError()
        }
    }

    func compute(x: CGFloat) -> CGFloat {
        return timing(x)
    }
}

extension CAMediaTimingFunction {
    static func timingFunction(from options: UIViewAnimationOptions) -> CAMediaTimingFunction? {
        if options.contains(.curveEaseIn) {
            return try! CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn) }
        if options.contains(.curveEaseOut) {
            return try! CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) }
        if options.contains(.curveEaseInOut) {
            return try! CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut) }

        return nil
    }
}

fileprivate extension CAMediaTimingFunction {
    static func linear(_ x: CGFloat) -> CGFloat { return x }
    static func easeInCubic(_ x: CGFloat) -> CGFloat { return pow(x, 3) }
    static func easeOutCubic(_ x: CGFloat) -> CGFloat { return x * (2-x) }
    static func easeInOutCubic(_ x: CGFloat) -> CGFloat { return x < 0.5 ? 4*pow(x, 3) : (x-1)*(2*x-2)*(2*x-2)+1 }
}
