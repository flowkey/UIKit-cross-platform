//
//  VideoTexture+Mac.swift
//  UIKit
//
//  Created by Chris on 23.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

internal final class VideoTexture: Texture {
    convenience init?(width: Int, height: Int, format: GPU_FormatEnum) {
        self.init(ptr: GPU_CreateImage(UInt16(width), UInt16(height), format))
    }
}

