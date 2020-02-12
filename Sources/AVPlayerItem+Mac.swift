//
//  AVPlayerItem+Mac.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import class AVFoundation.AVPlayerItem
@_exported import class AVFoundation.AVURLAsset
import struct AVFoundation.CMTime

public typealias CMTime = AVFoundation.CMTime

extension AVPlayerItem {
    public var durationInMs: Double {
        return duration.seconds * 1000
    }
}
