//
//  VideoPlayer.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class VideoPlayer: UIView {
    private var player: AVPlayer

    public init(url: String) {
        self.jniVideo = try! JNIVideo(url: url)
        super.init(frame: .zero)
    }

    override open var frame: CGRect {
        willSet(newFrame) {
            let scaledFrame = (newFrame * UIScreen.main.scale)
            jniVideo.frame = scaledFrame
        }
    }

    public var onVideoEnded: (() -> Void)? {
        get { return jniVideo.onVideoEnded }
        set { jniVideo.onVideoEnded = newValue }
    }

    public func play() {
        jniVideo.play()
    }

    public func pause() {
        jniVideo.pause()
    }

    public func getCurrentTimeInMS() -> Double {
        return jniVideo.getCurrentTimeInMS()
    }

    public func seek(to newTime: Double) {
        jniVideo.seek(to: newTime)
    }

    public var isMuted: Bool {
        get { return jniVideo.isMuted }
        set { jniVideo.isMuted = newValue }
    }

    public var rate: Double = 1 {
        willSet { jniVideo.setPlaybackRate(to: newValue) }
    }
}
