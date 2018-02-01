//
//  UIImage+testImage.swift
//  UIKitTests
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    @testable import UIKit
#endif

extension UIImage {
    static func testImage(ofSize size: CGSize) -> UIImage {
        var testImage: UIImage
        #if os(iOS)
            UIGraphicsBeginImageContext(size)
            testImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        #else
            testImage = UIImage(cgImage: CGImage(size: size)!, scale: 1)
        #endif
        return testImage
    }
}
