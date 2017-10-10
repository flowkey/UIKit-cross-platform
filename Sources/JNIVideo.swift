//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

@_silgen_name("Java_org_uikit_VideoJNI_nativeOnVideoEnded")
public func nativeOnVideoEnded(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalJNIVideo?.onVideoEnded?()
}

private weak var globalJNIVideo: JNIVideo?

class JNIVideo: JNIObject {
    init(url: String) throws {
        try super.init("org.uikit.VideoJNI", arguments: [url])
        globalJNIVideo = self
    }

    deinit {
        globalJNIVideo = nil
    }

    var onVideoEnded: (() -> Void)?

    func setOnEndedCallback(_ callback: @escaping (() -> Void)) {
        onVideoEnded = callback
    }

    var isMuted: Bool = false {
        didSet {
            let args = isMuted ? [0.0] : [1.0]
            try! call(methodName: "setVolume", arguments: args)
        }
    }

    func play() {
        try! call(methodName: "play")
    }

    func pause() {
        try! call(methodName: "pause")
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
        try! call(methodName: "setSize", arguments: [Int(width), Int(height)])
    }

    func setOrigin(x: Double, y: Double) {
        try! call(methodName: "setOrigin", arguments: [Int(x), Int(y)])
    }
}
