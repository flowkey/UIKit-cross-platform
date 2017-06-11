//
//  UIColor.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

public struct UIColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    public init(hex: Int, alpha: Double = 1) {
        let red = (hex & 0xFF0000) >> 16
        let green = (hex & 0x00FF00) >> 8
        let blue = (hex & 0x0000FF)
        self.init(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255, alpha: alpha)
    }

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red.normalisedToUInt8()
        self.green = green.normalisedToUInt8()
        self.blue = blue.normalisedToUInt8()
        self.alpha = alpha.normalisedToUInt8()
    }

    // Initialise from a color struct from e.g. renderer.getDrawColor()
    init(_ tuple: (r: UInt8, g: UInt8, b: UInt8, a: UInt8)) {
        red = tuple.r; green = tuple.g; blue = tuple.b; alpha = tuple.a
    }
}

public typealias CGColor = UIColor // They can be the same for us.

extension UIColor {
    public static let black = UIColor(red: 0, green: 0, blue: 0)
    public static let white = UIColor(red: 255, green: 255, blue: 255)
    public static let red = UIColor(red: 255, green: 0, blue: 0)
    public static let green = UIColor(red: 0, green: 255, blue: 0)
    public static let blue = UIColor(red: 0, green: 0, blue: 255)
    public static let clear = black.withAlphaComponent(0.0)

    public var cgColor: CGColor {
        return self
    }

    public func withAlphaComponent(_ alpha: Double) -> UIColor {
        return UIColor((self.red, self.green, self.blue, alpha.normalisedToUInt8()))
    }
}

extension UInt8 {
    func toNormalisedDouble() -> Double {
        return Double(self) / Double(UInt8.max)
    }
}

extension Double {
    /// Normalises a double value to a number between 0 and 1,
    /// then converts it to a range of 0 to 255 (UInt8.max):
    func normalisedToUInt8() -> UInt8 {
        let normalisedValue = min(max(self, 0), 1) // prevent overflow
        return UInt8(normalisedValue * Double(UInt8.max))
    }
}

extension UIColor {
    var sdlColor: SDLColor {
        return SDLColor(r: red, g: green, b: blue, a: alpha)
    }
}
