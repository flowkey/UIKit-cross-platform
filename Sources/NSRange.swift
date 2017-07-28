//
//  NSRange.swift
//  UIKit
//
//  Created by Chris on 25.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

public struct NSRange {
    public var location: Int
    public var length: Int

    public init() {
        location = 0
        length = 0
    }

    public init(location: Int, length: Int) {
        self.location = location
        self.length = length
    }
}
