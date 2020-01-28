//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

public class AVPlayer: JNIObject {
    public var onLoaded: ((Error?) -> Void)?
    public var onVideoEnded: (() -> Void)?

    override public class var className: String {
        return "org.uikit.AVPlayer"
    }

    public convenience init(playerItem: AVPlayerItem) {
        let parentView = JavaSDLView(getSDLView())
        try! self.init(arguments: parentView, playerItem.asset)
        globalAVPlayer = self
    }

    public func play() {
        try! call(methodName: "play")
    }

    public func pause() {
        try! call(methodName: "pause")
    }

    public func getCurrentTimeInMS() -> Int64 {
        return try! call(methodName: "getCurrentTimeInMilliseconds")
    }

    public func seek(to timeInMilliseconds: Int64) {
        try! call(methodName: "seekToTimeInMilliseconds", arguments: [timeInMilliseconds])
    }

    public var rate: Float {
        get { return try! call(methodName: "getPlaybackRate") }
        set { try! call(methodName: "setPlaybackRate", arguments: [newValue]) }
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

    public struct DataSourceError: Error {}
}

private weak var globalAVPlayer: AVPlayer?

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoReady")
public func nativeOnVideoReady(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onLoaded?(nil)
    globalAVPlayer?.onLoaded = nil
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoEnded")
public func nativeOnVideoEnded(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onVideoEnded?()
}

@_cdecl("Java_org_uikit_AVPlayer_nativeOnVideoSourceError")
public func nativeOnVideoSourceError(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalAVPlayer?.onLoaded?(AVPlayer.DataSourceError())
    globalAVPlayer?.onLoaded = nil
}

extension AVPlayer: JavaParameterConvertible {
    private static let javaClassname = "org/uikit/AVPlayer"
    public static let asJNIParameterString = "L\(javaClassname);"

    public func toJavaParameter() -> JavaParameter {
        return JavaParameter(object: self.instance)
    }
}
