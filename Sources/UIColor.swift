//
//  UIColor.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

public struct UIColor: Equatable {

    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    public init(hex: Int, alpha: CGFloat = 1) {
        let red = (hex & 0xFF0000) >> 16
        let green = (hex & 0x00FF00) >> 8
        let blue = (hex & 0x0000FF)
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1) {
        self.red = red.normalisedToUInt8()
        self.green = green.normalisedToUInt8()
        self.blue = blue.normalisedToUInt8()
        self.alpha = alpha.normalisedToUInt8()
    }

    // mocked!
    public init(patternImage: UIImage?) {
        // TODO: define a color object for specified Quartz color reference https://developer.apple.com/documentation/uikit/uicolor/1621933-init
        self.red = CGFloat(250).normalisedToUInt8()
        self.green = CGFloat(250).normalisedToUInt8()
        self.blue = CGFloat(250).normalisedToUInt8()
        self.alpha = CGFloat(1).normalisedToUInt8()
    }
    
    public static func == (lhs: UIColor, rhs: UIColor) -> Bool {
        return (lhs.red == rhs.red) && (lhs.green == rhs.green) && (lhs.blue == rhs.blue)
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
    public static let orange = UIColor(red: 255, green: 127.5, blue: 0)
    public static let lightGray = UIColor(red: 170, green: 170, blue: 170)
    public static let clear = black.withAlphaComponent(0.0)

    public var cgColor: CGColor {
        return self
    }

    public func withAlphaComponent(_ alpha: Float) -> UIColor {
        return UIColor((self.red, self.green, self.blue, alpha.normalisedToUInt8()))
    }
}

extension UInt8 {
    func toNormalisedFloat() -> Float {
        return Float(self) / Float(UInt8.max)
    }
}

extension CGFloat {
    func normalisedToUInt8() -> UInt8 {
        let normalisedValue = Swift.min(Swift.max(self, 0), 1) // prevent overflow
        return UInt8(normalisedValue * CGFloat(UInt8.max))
    }
}

extension Float {
    func normalisedToUInt8() -> UInt8 {
        let normalisedValue = Swift.min(Swift.max(self, 0), 1) // prevent overflow
        return UInt8(normalisedValue * Float(UInt8.max))
    }
}

extension UIColor {
    var sdlColor: SDLColor {
        return SDLColor(r: red, g: green, b: blue, a: alpha)
    }
}
