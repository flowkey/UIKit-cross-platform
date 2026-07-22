#if os(Android)
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
        try! self.call("setSwiftAVPlayerInstancePtr", arguments: [self.swiftInstancePtr])
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
        let type: Int
        let message: String
    }
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoReady")
public func nativeOnVideoReady(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject, swiftAVPlayerInstancePtr: JavaLong) {
    AVPlayer.from(swiftAVPlayerInstancePtr: swiftAVPlayerInstancePtr)?.onVideoReady?()
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoEnded")
public func nativeOnVideoEnded(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject, swiftAVPlayerInstancePtr: JavaLong) {
    AVPlayer.from(swiftAVPlayerInstancePtr: swiftAVPlayerInstancePtr)?.onVideoEnded?()
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoBuffering")
public func nativeOnVideoBuffering(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject, swiftAVPlayerInstancePtr: JavaLong) {
    AVPlayer.from(swiftAVPlayerInstancePtr: swiftAVPlayerInstancePtr)?.onVideoBuffering?()
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoError")
public func nativeOnVideoError(
    env: UnsafeMutablePointer<JNIEnv>,
    cls: JavaObject,
    type: JavaInt,
    message: JavaString,
    swiftAVPlayerInstancePtr: JavaLong
) {
    let error = AVPlayer.ExoPlaybackError(
        type: Int(type),
        message: (try? String(javaString: message)) ?? ""
    )
    AVPlayer.from(swiftAVPlayerInstancePtr: swiftAVPlayerInstancePtr)?.onError?(error)
}

extension AVPlayer {
    static func from(swiftAVPlayerInstancePtr: JavaLong) -> AVPlayer? {
        guard let reference = UnsafeRawPointer(bitPattern: Int(swiftAVPlayerInstancePtr)) else {
            let msg = "Could not derefence AVPlayer instance from swiftAVPlayerInstancePtr."
            print(msg)
            assertionFailure(msg)
            return nil
        }
        return Unmanaged<AVPlayer>.fromOpaque(reference).takeUnretainedValue()
    }
}
#endif
