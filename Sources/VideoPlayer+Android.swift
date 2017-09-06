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
        }
    }

    var onVideoEnded: (() -> Void)? {
        didSet {
            print("didSet onVideoEnded to", onVideoEnded)
            javaVideo.setOnEndedCallback(onVideoEnded!) // should always exist in didSet call
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

//    public func setOnEndedCallback(_ callback: (() -> Void)) {
//        javaVideo?.setOnEndedCallback(callback)
//    }

    public func getCurrentTimeInMS() -> Double {
        return javaVideo.getCurrentTimeInMS() ?? 0.0
    }

    public func seek(to newTime: Double) {
        javaVideo.seek(to: newTime)
    }

    public var isMuted: Bool = false
    public var rate: Double = 1 {
        willSet(newRate) {
            javaVideo.setPlaybackRate(to: newRate)
        }
    }
}

private class JavaVideo: JNIObject {
    convenience init?(url: String) {
        self.init("com.flowkey.nativeplayersdl.VideoJNI", arguments: [url])
    }

    func play() {
        try! call(methodName: "play")
    }

    func pause() {
        try! call(methodName: "pause")
    }

    func setOnEndedCallback(_ callback: (() -> Void)) {
        print("javaVideo.setOnEndedCallback to", callback)
        try! call(methodName: "setOnVideoEndedCallback") // add callback argument / function pointer here
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
        let pixelCoordinateContentScale = 2
        let androidWidth = Int(width) * pixelCoordinateContentScale
        let androidHeight = Int(height) * pixelCoordinateContentScale
        try! call(methodName: "setSize", arguments: [androidWidth, androidHeight])
    }
}
