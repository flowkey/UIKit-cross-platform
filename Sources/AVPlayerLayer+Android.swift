#if os(Android)
//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

public enum AVLayerVideoGravity: JavaInt {
    case resizeAspect = 0 // RESIZE_MODE_FIT
    case resize = 3 // RESIZE_MODE_FILL
    case resizeAspectFill = 4 // RESIZE_MODE_ZOOM
}

@MainActor
final public class AVPlayerLayer: CALayer {
    public var kotlinAVPlayerLayer: KotlinAVPlayerLayer!

    public convenience init(player: AVPlayer) {
        self.init()
        kotlinAVPlayerLayer = KotlinAVPlayerLayer(player: player)
    }

    public var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet { kotlinAVPlayerLayer?.setVideoGravity(videoGravity) }
    }

    override public var opacity: Float {
        didSet { kotlinAVPlayerLayer?.setAlpha(opacity) }
    }

    override public var isHidden: Bool {
        didSet { kotlinAVPlayerLayer?.setIsHidden(isHidden) }
    }

    override public func copy() -> AVPlayerLayer {
        let copy = super.copy()
        print("[AVPlayerLayer] Copying and setting kotlinAVPlayerLayer")
        // Allow the presentation layer's frame to be animated:
        copy.kotlinAVPlayerLayer = kotlinAVPlayerLayer
        return copy
    }

    override public var zPosition: CGFloat {
        didSet { kotlinAVPlayerLayer?.setElevation(zPosition) }
    }

    // [Frame Animations]
    // `frame` is a computed property, so `position` and `bounds` are what actually gets animated
    override public var bounds: CGRect {
        didSet { kotlinAVPlayerLayer?.setFrame(frame) }
    }

    override public var position: CGPoint {
        didSet { kotlinAVPlayerLayer?.setFrame(frame) }
    }
    // [/Frame Animations]
}

@MainActor
public final class KotlinAVPlayerLayer: JNIObject {
    override public static var className: String { "org.uikit.AVPlayerLayer" }

    public convenience init(player: AVPlayer) {
        let parentView = JavaSDLView(getSDLView())
        try! self.init(arguments: parentView, player)
    }

    public func setVideoGravity(_ newValue: AVLayerVideoGravity) {
        try! call("setResizeMode", arguments: [newValue.rawValue])
    }

    public func setAlpha(_ newValue: Float) {
        try! call("setAlpha", arguments: [newValue])
    }

    public func setFrame(_ newValue: CGRect) {
        guard let scale = UIScreen.main?.scale else { return }
        let scaledFrame = newValue * scale
        try! call("setFrame", arguments: [
            JavaInt(scaledFrame.origin.x.rounded()),
            JavaInt(scaledFrame.origin.y.rounded()),
            JavaInt(scaledFrame.size.width.rounded()),
            JavaInt(scaledFrame.size.height.rounded())
        ])
    }

    public func setIsHidden(_ newValue: Bool) {
        try! call("setIsHidden", arguments: [newValue])
    }

    public func setElevation(_ newValue: Double) {
        try! call("setElevation", arguments: [newValue])
    }

    deinit {
        do {
            try call("removeFromParent")
        } catch {
            assertionFailure("Couldn't remove AVPlayerLayer from parent")
        }
    }
}
#endif
