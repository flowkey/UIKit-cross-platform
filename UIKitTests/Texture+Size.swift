//
//  Texture+Size.swift
//  UIKitTests
//
//  Created by Chris on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import SDL_gpu
@testable import UIKit

extension CGImage {
    convenience init?(size: CGSize, bytesPerPixel: Int32 = 4, sourceData: Data? = nil) {
        // CGImage takes care of deiniting the memory on cleanup so pass this as retained:
        let pointer = UnsafeMutablePointer<GPU_Image>.allocate(capacity: 1)
        pointer.pointee.w = UInt16(size.width)
        pointer.pointee.h = UInt16(size.height)
        pointer.pointee.bytes_per_pixel = bytesPerPixel
        self.init(pointer, sourceData: sourceData)
    }
}
