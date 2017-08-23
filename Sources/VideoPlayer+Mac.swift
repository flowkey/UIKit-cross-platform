//
//  VideoPlayer+Mac.swift
//  UIKit
//
//  Created by Geordie Jay on 13.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import AVFoundation
import SDL

open class VideoPlayer: UIView {
    override open class var layerClass: CALayer.Type {
        return UIKit.AVPlayerLayer.self
    }
    var player: AVPlayer? { return playerLayer.player }
    var playerLayer: UIKit.AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    public init(url: String) {
        super.init(frame: .zero)
        playerLayer.player = AVPlayer(url: URL(string: url)!)
    }

    open func play() {
        player?.rate = Float(self.rate)
    }

    open func pause() {
        // equivalent to player.pause(), but this makes the API consistent with self.play():
        player?.rate = 0
    }

    public func getCurrentTime() -> Double {
        return (player?.currentTime().seconds ?? 0) * 1000
    }

    public func seek(to timeInMS: Double) {
        let timeInSeconds = timeInMS * 1000
        player?.seek(
            to: CMTime(seconds: timeInSeconds, preferredTimescale: 48),
            toleranceBefore: CMTime(value: 32 / 1000, timescale: 48),
            toleranceAfter: CMTime(value: 32 / 1000, timescale: 48)
        )
    }

    open var isMuted: Bool {
        get { return player?.isMuted ?? false }
        set { player?.isMuted = newValue }
    }

    open var rate: Double = 1 {
        didSet {
            guard let player = player, player.rate > 0 else { return } // don't set rate unless playing
            player.rate = Float(rate)
        }
    }
}
