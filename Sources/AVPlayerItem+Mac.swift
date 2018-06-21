//
//  AVPlayerItem+Mac.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

@_exported import class AVFoundation.AVPlayerItem
import struct AVFoundation.CMTime
import func AVFoundation.CMTimeGetSeconds

public typealias CMTime = AVFoundation.CMTime

extension AVPlayerItem {
    public var durationInMs: Double {
        return CMTimeGetSeconds(self.duration) * 1000
    }
}
