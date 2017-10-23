//
//  VideoPlayer.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

open class VideoPlayer: UIView {
    fileprivate var jniVideo: JNIVideo

    public init(url: String) {
        self.jniVideo = try! JNIVideo(url: url)
        super.init(frame: .zero)
    }

    override open var frame: CGRect {
        willSet(newFrame) {
            let scale = UIScreen.main.scale
            let scaledWidth = Double(newFrame.width * scale)
            let scaledHeight = Double(newFrame.height * scale)
            let scaledX = Double(newFrame.origin.x * scale)
            let scaledY = Double(newFrame.origin.y * scale)

            jniVideo.setSize(width: scaledWidth, height: scaledHeight)
            jniVideo.setOrigin(x: scaledX, y: scaledY)
        }
    }

    public var onVideoEnded: (() -> Void)? {
        get { return jni.onVideoEnded }
        set { jni.onVideoEnded = newValue }
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

    public var isMuted: Bool = false {
        get { return jniVideo.isMuted }
        set { jniVideo.isMuted = newValue }
    }

    public var rate: Double = 1 {
        willSet { jniVideo.setPlaybackRate(to: newValue) }
    }
}
