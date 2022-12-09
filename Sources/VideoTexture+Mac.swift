//
//  VideoTexture+Mac.swift
//  UIKit
//
//  Created by Chris on 23.10.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(macOS)

@_implementationOnly import SDL_gpu

internal final class VideoTexture: CGImage {
    convenience init?(width: Int, height: Int, format: GPU_FormatEnum) {
        self.init(GPU_CreateImage(UInt16(width), UInt16(height), format), sourceData: nil)
    }
}

#endif
