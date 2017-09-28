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
        self.jniVideo = JNIVideo(url: url)!
        super.init(frame: .zero)
    }

    override open var frame: CGRect {
        willSet(newFrame) {
            let scaledWidth = Double(newFrame.width) * SDL.window.scaleFactor
            let scaledHeight = Double(newFrame.height) * SDL.window.scaleFactor
            let scaledX = Double(newFrame.origin.x) * SDL.window.scaleFactor
            let scaledY = Double(newFrame.origin.y) * SDL.window.scaleFactor

            jniVideo.setSize(width: scaledWidth, height: scaledHeight)
            jniVideo.setOrigin(x: scaledX, y: scaledY)
        }
    }

    public var onVideoEnded: (() -> Void)? {
        willSet(newValue) {
            if let onEndedCallback = newValue {
                jniVideo.setOnEndedCallback(onEndedCallback)
            }
        }
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
        willSet { jniVideo.isMuted = newValue }
    }

    public var rate: Double = 1 {
        willSet { jniVideo.setPlaybackRate(to: newValue) }
    }
}