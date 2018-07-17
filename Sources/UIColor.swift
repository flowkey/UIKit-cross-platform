//
//  UIColor.swift
//  NativePlayerSDL
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

public class UIColor: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    public convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = (hex & 0xFF0000) >> 16
        let green = (hex & 0x00FF00) >> 8
        let blue = (hex & 0x0000FF)
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }

    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red.normalisedToUInt8()
        self.green = green.normalisedToUInt8()
        self.blue = blue.normalisedToUInt8()
        self.alpha = alpha.normalisedToUInt8()
    }

    // from wikipedia: https://en.wikipedia.org/wiki/HSL_and_HSV
    // XXX: This is not currently working as it should but it is better than nothing
    // We currently only use this in testing, but whoever needs it for real should have a look at fixing it..
    public convenience init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        let c = (1 - ((2 * brightness) - 1).magnitude) * saturation
        let x = c * (1 - (hue.remainder(dividingBy: 2) - 1).magnitude)

        let m = brightness - (0.5 * c)

        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let hueDash = hue * 6
        if hueDash < 1 {
            (r,g,b) = (c,x,0)
        } else if hueDash < 2 {
            (r,g,b) = (x,c,0)
        } else if hueDash < 3 {
            (r,g,b) = (0,c,x)
        } else if hueDash < 4 {
            (r,g,b) = (0,x,c)
        } else if hueDash < 5 {
            (r,g,b) = (x,0,c)
        } else if hueDash < 6 {
            (r,g,b) = (c,0,x)
        } else {
            (r,g,b) = (0,0,0)
        }

        self.init(red: r + m, green: g + m, blue: b + m, alpha: alpha)
    }

    // FIXME: mocked!
    public init(patternImage: UIImage?) {
        // TODO: define a color object for specified Quartz color reference https://developer.apple.com/documentation/uikit/uicolor/1621933-init
        self.red = 255
        self.green = 255
        self.blue = 255
        self.alpha = 255
    }
    
    public static func == (lhs: UIColor, rhs: UIColor) -> Bool {
        return (lhs.red == rhs.red) && (lhs.green == rhs.green) && (lhs.blue == rhs.blue) && (lhs.alpha == rhs.alpha)
    }

    // Initialise from a color struct from e.g. renderer.getDrawColor()
    init(_ tuple: (r: UInt8, g: UInt8, b: UInt8, a: UInt8)) {
        red = tuple.r; green = tuple.g; blue = tuple.b; alpha = tuple.a
    }
}

public typealias CGColor = UIColor // They can be the same for us.

extension UIColor {
    public static let black = UIColor(red: 0, green: 0, blue: 0)
    public static let white = UIColor(red: 1, green: 1, blue: 1)
    public static let red = UIColor(red: 1, green: 0, blue: 0)
    public static let green = UIColor(red: 0, green: 1, blue: 0)
    public static let blue = UIColor(red: 0, green: 0, blue: 1)
    public static let purple = UIColor(red: 0.5, green: 0, blue: 0.5)
    public static let orange = UIColor(red: 1, green: 0.5, blue: 0)
    public static let lightGray = UIColor(red: 2.0 / 3.0, green: 2.0 / 3.0, blue: 2.0 / 3.0)
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0) // as per iOS

    public var cgColor: CGColor {
        return self
    }

    public func withAlphaComponent(_ alpha: CGFloat) -> UIColor {
        return UIColor((self.red, self.green, self.blue, alpha.normalisedToUInt8()))
    }
}

extension UInt8 {
    func toNormalisedFloat() -> Float {
        return Float(self) / Float(UInt8.max)
    }
}

extension CGFloat {
    /// Normalises a double value to a number between 0 and 1,
    /// then converts it to a range of 0 to 255 (UInt8.max):
    func normalisedToUInt8() -> UInt8 {
        let normalisedValue = Swift.min(Swift.max(self, 0), 1) // prevent overflow
        return UInt8(normalisedValue * CGFloat(UInt8.max))
    }
}

extension Float {
    /// Normalises a double value to a number between 0 and 1,
    /// then converts it to a range of 0 to 255 (UInt8.max):
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

extension UIColor: CustomStringConvertible {
    public var description: String {
        return "rgba(\(red), \(green), \(blue), \(alpha))"
    }
}
