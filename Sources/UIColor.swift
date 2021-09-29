//
//  UIColor.swift
//  UIKit
//
//  Created by Geordie Jay on 16.05.17.
//  Copyright © 2017 Geordie Jay. All rights reserved.
//

import SDL

// XXX: We don't actually *want* UIColor to be an NSObject but we 
// can't avoid it for now either because of a crash in Foundation
// https://bugs.swift.org/browse/SR-11233
import class Foundation.NSObject
//
public class UIColor: NSObject/*, Hashable*/ {
    let redValue: UInt8
    let greenValue: UInt8
    let blueValue: UInt8
    let alphaValue: UInt8

    convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = (hex & 0xFF0000) >> 16
        let green = (hex & 0x00FF00) >> 8
        let blue = (hex & 0x0000FF)
        self.init(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.redValue = red.normalisedToUInt8()
        self.greenValue = green.normalisedToUInt8()
        self.blueValue = blue.normalisedToUInt8()
        self.alphaValue = alpha.normalisedToUInt8()
    }

    // Without this we'd break Hashable / Equatable contracts for collections.
    // We MUST guarantee that two _equal_ values also have the same `hashValue`.
    // It is necessary because UIColor is currently an NSObject due to bugs in Foundation (see above).
    // Otherwise we could just use the automatic Hashable conformance
    override public var hash: Int {
        // On Android Int/UInt are 32bit
        // `255 << 24` (the "actual" number) does not fit into Int32.
        // It _does_ fit into a UInt32 though, so here we add up the binary values
        // as UInts, and then use that binary value (bit pattern) to construct
        // an Int whose "actual" value we don't care about (it just has to be
        // unique for each combination of the component colour values)...
        let result = UInt(redValue) << 24 + UInt(greenValue) << 16 + UInt(blueValue) << 8 + UInt(alphaValue)
        return Int(bitPattern: UInt(result))
    }

    // from wikipedia: https://en.wikipedia.org/wiki/HSL_and_HSV
    // XXX: This is not currently working as it should but it is better than nothing
    // We currently only use this in testing, but whoever needs it for real should have a look at fixing it..
    public convenience init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        let c: CGFloat = (1 - ((2 * brightness) - 1).magnitude) * saturation
        let x: CGFloat = c * (1 - (hue.remainder(dividingBy: 2) - 1).magnitude)

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
        self.redValue = 255
        self.greenValue = 255
        self.blueValue = 255
        self.alphaValue = 255
    }
    
    public static func == (lhs: UIColor, rhs: UIColor) -> Bool {
        return (lhs.redValue == rhs.redValue) && (lhs.greenValue == rhs.greenValue) && (lhs.blueValue == rhs.blueValue) && (lhs.alphaValue == rhs.alphaValue)
    }

    // Initialise from a color struct from e.g. renderer.getDrawColor()
    init(_ tuple: (r: UInt8, g: UInt8, b: UInt8, a: UInt8)) {
        redValue = tuple.r; greenValue = tuple.g; blueValue = tuple.b; alphaValue = tuple.a
    }
}

// XXX: Can't override NSObject's description
// extension UIColor: CustomStringConvertible {
//     public var description: String {
//         return "rgba(\(red), \(green), \(blue), \(alpha))"
//     }
// }

public typealias CGColor = UIColor // They can be the same for us.

extension UIColor {
    public static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let yellow = UIColor(red: 1, green: 1, blue: 0, alpha: 1)
    public static let purple = UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1)
    public static let orange = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    public static let lightGray = UIColor(red: 2.0 / 3.0, green: 2.0 / 3.0, blue: 2.0 / 3.0, alpha: 1)
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0) // as per iOS

    public var cgColor: CGColor {
        return self
    }

    public func withAlphaComponent(_ alpha: CGFloat) -> UIColor {
        return UIColor((self.redValue, self.greenValue, self.blueValue, alpha.normalisedToUInt8()))
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
        return SDLColor(r: redValue, g: greenValue, b: blueValue, a: alphaValue)
    }
}
