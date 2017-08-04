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
    fileprivate let javaVideo: JavaVideo

    public init(url: String) {
        print(url)
        javaVideo = JavaVideo(url: url)!
        super.init(frame: .zero)
    }

    open func play() {
        javaVideo.play()
    }

    open func pause() {
        javaVideo.pause()
    }

    public func getCurrentTime() -> Double {
        return javaVideo.getCurrentTime()
    }

    public func seek(to newTime: Double) {
        javaVideo.seek(to: newTime)
    }

    open var isMuted: Bool = false
    open var rate: Double = 1
}

private class JavaVideo: JNIObject {
    convenience init?(url: String) {
        self.init("com.flowkey.nativeplayersdl.SDLVideo", arguments: [url])
    }

    func play() {
        try! call(methodName: "play")
    }

    func pause() {
        try! call(methodName: "pause")
    }

    func getCurrentTime() -> Double {
        return try! call(methodName: "getCurrentTimeInMilliseconds")
    }

    func seek(to timeInMilliseconds: Double) {
        try! call(methodName: "seekToTimeInMilliseconds", arguments: [timeInMilliseconds])
    }
}
