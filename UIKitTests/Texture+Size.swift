//
//  Texture+Size.swift
//  UIKitTests
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@testable import UIKit

extension Texture {
    convenience init?(size: CGSize) {
        var gpuImage = GPU_Image()

        gpuImage.w = UInt16(size.width)
        gpuImage.h = UInt16(size.height)

        // TODO: check capacity of 16 or initialize in different way without explizit capacity
        let gpuImagePointer = UnsafeMutablePointer<GPU_Image>.allocate(capacity: 16)
        gpuImagePointer.initialize(to: gpuImage)

        self.init(gpuImage: gpuImagePointer)
    }
}
