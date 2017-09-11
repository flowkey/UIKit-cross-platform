//
//  VideoPlayer.swift
//  UIKit
//
//  Created by Geordie Jay on 10.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI
import SDL.gpu

open class VideoPlayer: UIView {
    fileprivate var javaVideo: JavaVideo

    override open var frame: CGRect {
        willSet(newFrame) {
            javaVideo.setSize(width: Double(newFrame.width), height: Double(newFrame.height))
            javaVideo.setOrigin(x: Double(newFrame.origin.x), y: Double(newFrame.origin.y))
        }
    }

    public var onVideoEnded: (() -> Void)? {
        willSet(newValue) {
            if let onEndedCallback = newValue {
                javaVideo.setOnEndedCallback(onEndedCallback)
            }
        }
    }

    public init(url: String) {
        self.javaVideo = JavaVideo(url: url)!
        super.init(frame: .zero)
    }

    public func play() {
        javaVideo.play()
    }

    public func pause() {
        javaVideo.pause()
    }

    public func getCurrentTimeInMS() -> Double {
        return javaVideo.getCurrentTimeInMS()
    }

    public func seek(to newTime: Double) {
        javaVideo.seek(to: newTime)
    }

    public var isMuted: Bool = false {
        willSet(newValue) {
            javaVideo.isMuted = newValue
        }
    }
    public var rate: Double = 1 {
        willSet(newRate) {
            javaVideo.setPlaybackRate(to: newRate)
        }
    }
}

@_silgen_name("Java_com_flowkey_nativeplayersdl_VideoJNI_nativeOnVideoEnded")
public func nativeOnVideoEnded(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    javaVideo?.onVideoEnded?()
}

private weak var javaVideo: JavaVideo?

private class JavaVideo: JNIObject {
    convenience init?(url: String) {
        self.init("com.flowkey.nativeplayersdl.VideoJNI", arguments: [url])
        javaVideo = self
    }

    deinit {
        javaVideo = nil
    }

    var onVideoEnded: (() -> Void)?
    
    var isMuted: Bool = false {
        willSet(muted) {
            if (muted) {
                try! call(methodName: "setVolume", arguments: [0.0])
            } else {
                try! call(methodName: "setVolume", arguments: [1.0])
            }
        }
    }

    func play() {
        try! call(methodName: "play")
    }

    func pause() {
        try! call(methodName: "pause")
    }

    func setOnEndedCallback(_ callback: @escaping (() -> Void)) {
        onVideoEnded = callback
    }

    func getCurrentTimeInMS() -> Double {
        return try! call(methodName: "getCurrentTimeInMilliseconds")
    }

    func seek(to timeInMilliseconds: Double) {
        try! call(methodName: "seekToTimeInMilliseconds", arguments: [timeInMilliseconds])
    }

    func setPlaybackRate(to rate: Double) {
        try! call(methodName: "setPlaybackRate", arguments: [rate])
    }

    func setSize(width: Double, height: Double) {
        let scaleFactor = Int(SDL.window.scaleFactor)
        let androidWidth = Int(width) * scaleFactor
        let androidHeight = Int(height) * scaleFactor
        try! call(methodName: "setSize", arguments: [androidWidth, androidHeight])
    }

    func setOrigin(x: Double, y: Double) {
        try! call(methodName: "setOrigin", arguments: [Int(x), Int(y)])
    }
}
