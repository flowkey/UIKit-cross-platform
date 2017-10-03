//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

class JNIVideo: JNIObject {
    convenience init(url: String, javaClassPath: String) throws {
        try self.init(javaClassPath, arguments: [url])
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
