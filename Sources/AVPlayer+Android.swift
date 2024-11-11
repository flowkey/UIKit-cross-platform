//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

public class AVPlayer: JNIObject {
    public override static var className: String { "org.uikit.AVPlayer" }

    public var onError: ((ExoPlaybackError) -> Void)?
    public var onVideoReady: (() -> Void)?
    public var onVideoEnded: (() -> Void)?
    public var onVideoBuffering: (() -> Void)?

    public convenience init(playerItem: AVPlayerItem) {
        let parentView = JavaSDLView(getSDLView())
        try! self.init(arguments: parentView, playerItem.asset)
        globalAVPlayer = self
    }

    public func play() {
        try! call("play")
    }

    public func pause() {
        try! call("pause")
    }

    public func getCurrentTimeInMS() -> Int64 {
        return try! call("getCurrentTimeInMilliseconds")
    }

    public func seek(to timeInMilliseconds: Int64) {
        try! call("seekToTimeInMilliseconds", arguments: [timeInMilliseconds])
    }

    public var rate: Float {
        get { return try! call("getPlaybackRate") }
        set { try! call("setPlaybackRate", arguments: [newValue]) }
    }

    public var isMuted: Bool = false {
        didSet {
            let newVolume = isMuted ? 0.0 : 1.0
            try! call("setVolume", arguments: [newVolume])
        }
    }

    deinit {
        try? call("cleanup")
    }

    public struct ExoPlaybackError: Error {
        let type: Int // https://exoplayer.dev/doc/reference/com/google/android/exoplayer2/ExoPlaybackException.Type.html
        let message: String
    }
}

private weak var globalAVPlayer: AVPlayer?

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoReady")
public func nativeOnVideoReady(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onVideoReady?()
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoEnded")
public func nativeOnVideoEnded(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onVideoEnded?()
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoBuffering")
public func nativeOnVideoBuffering(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onVideoBuffering?()
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoError")
public func nativeOnVideoError(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject, type: JavaInt, message: JavaString) {
    let error = AVPlayer.ExoPlaybackError(
        type: Int(type),
        message: (try? String(javaString: message)) ?? "N/A"
    )
    globalAVPlayer?.onError?(error)
}
