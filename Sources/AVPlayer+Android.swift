//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

public class AVPlayer: JNIObject {
    public var onReady: (() -> Void)?
    public var onVideoEnded: (() -> Void)?

    public convenience init(playerItem: AVPlayerItem) {
        let parentView = JavaSDLView(getSDLView())
        try! self.init("org.uikit.AVPlayer", arguments: [parentView, playerItem])
        globalAVPlayer = self
    }

    public func play() {
        try! call(methodName: "play")
    }

    public func pause() {
        try! call(methodName: "pause")
    }

    public func getCurrentTimeInMS() -> Double {
        return try! call(methodName: "getCurrentTimeInMilliseconds")
    }

    public func seek(to timeInMilliseconds: Double) {
        try! call(methodName: "seekToTimeInMilliseconds", arguments: [timeInMilliseconds])
    }

    public func setPlaybackRate(to rate: Double) {
        try! call(methodName: "setPlaybackRate", arguments: [rate])
    }

    public var isMuted: Bool = false {
        didSet {
            let newVolume = isMuted ? 0.0 : 1.0
            try! call(methodName: "setVolume", arguments: [newVolume])
        }
    }

    deinit {
        try? call(methodName: "cleanup")
    }
}



private weak var globalAVPlayer: AVPlayer?

@_silgen_name("Java_org_uikit_AVPlayer_nativeOnVideoReady")
public func nativeOnVideoReady(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onReady?()
}

@_silgen_name("Java_org_uikit_AVPlayer_nativeOnVideoEnded")
public func nativeOnVideoEnded(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onVideoEnded?()
}

extension AVPlayer: JavaParameterConvertible {
    private static let javaClassname = "org/uikit/AVPlayer"
    public static let asJNIParameterString = "L\(javaClassname);"

    public func toJavaParameter() -> JavaParameter {
        return JavaParameter(object: self.instance)
    }
}
