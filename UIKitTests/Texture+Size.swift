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

        let gpuImagePointer = UnsafeMutablePointer<GPU_Image>.allocate(capacity: 1)
        gpuImagePointer.initialize(to: gpuImage)

        self.init(gpuImagePointer)
    }
}
