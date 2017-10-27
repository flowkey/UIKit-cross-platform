//
//  CGBitmapInfo.swift
//  UIKit
//
//  Created by Geordie Jay on 25.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct CGBitmapInfo: OptionSet {
    public let rawValue: UInt32
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    static let alphaInfoMask = CGBitmapInfo(rawValue: 31)
}
