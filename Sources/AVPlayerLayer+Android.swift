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
public class AVPlayerLayer: JNIObject {
    override public static var className: String { "org.uikit.AVPlayerLayer" }

    public convenience init(player: AVPlayer) {
        let parentView = JavaSDLView(getSDLView())
        try! self.init(arguments: parentView, player)
    }

    public var videoGravity: AVLayerVideoGravity = .resizeAspect {
        didSet {
            try! call("setResizeMode", arguments: [videoGravity.rawValue])
        }
    }

    public var frame: CGRect {
        get { return .zero } // FIXME: This would require returning a JavaObject with the various params
        set {
            guard let scale = UIScreen.main?.scale else { return }
            let scaledFrame = (newValue * scale)
            try! call("setFrame", arguments: [
                JavaInt(scaledFrame.origin.x.rounded()),
                JavaInt(scaledFrame.origin.y.rounded()),
                JavaInt(scaledFrame.size.width.rounded()),
                JavaInt(scaledFrame.size.height.rounded())
            ])
        }
    }

    deinit {
        do {
            try call("removeFromParent")
        } catch {
            assertionFailure("Couldn't remove AVPlayerLayer from parent")
        }
    }
}
