//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

public class AVPlayerLayer: JNIObject {
    override public static var className: String { "org.uikit.AVPlayerLayer" }

    public convenience init(player: AVPlayer) {
        let parentView = JavaSDLView(getSDLView())
        try! self.init(arguments: parentView, player)
    }

    public var frame: CGRect {
        get { return .zero } // FIXME: This would require returning a JavaObject with the various params
        set {
            Task { @MainActor in
                let scaledFrame = (newValue * UIScreen.main.scale)
                try! call(methodName: "setFrame", arguments: [
                    JavaInt(scaledFrame.origin.x.rounded()),
                    JavaInt(scaledFrame.origin.y.rounded()),
                    JavaInt(scaledFrame.size.width.rounded()),
                    JavaInt(scaledFrame.size.height.rounded())
                ])
            }
        }
    }

    deinit {
        do {
            try call(methodName: "removeFromParent")
        } catch {
            assertionFailure("Couldn't remove AVPlayerLayer from parent")
        }
    }
}
