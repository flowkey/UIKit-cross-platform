//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI
import func Foundation.round // For rounding CGFloats in .frame

@_silgen_name("Java_org_uikit_VideoJNI_nativeOnVideoEnded")
public func nativeOnVideoEnded(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalJNIVideo?.onVideoEnded?()
}

@_silgen_name("Java_org_uikit_VideoJNI_nativeOnVideoReady")
public func nativeOnVideoReady(env: UnsafeMutablePointer<JNIEnv>, cls: JavaObject) {
    globalJNIVideo?.onVideoReady?()
}

private weak var globalJNIVideo: JNIVideo?

class JNIVideo: JNIObject {
    init(url: String) throws {
        let parentView = JavaSDLView(getSDLView())
        try super.init("org.uikit.VideoJNI", arguments: [parentView, url])
        globalJNIVideo = self
    }

    deinit {
        try? call(methodName: "cleanup")
    }

    var onVideoEnded: (() -> Void)?
    var onVideoReady: (() -> Void)?

    var isMuted: Bool = false {
        didSet {
            let newVolume = isMuted ? 0.0 : 1.0
            try! call(methodName: "setVolume", arguments: [newVolume])
        }
    }

    var frame: CGRect {
        get { return .zero } // FIXME: This would require returning a JavaObject with the various params
        set {
            try! call(methodName: "setFrame", arguments: [
                Int(round(newValue.origin.x)),
                Int(round(newValue.origin.y)),
                Int(round(newValue.size.width)),
                Int(round(newValue.size.height))
            ])
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
}
