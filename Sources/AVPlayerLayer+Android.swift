//
//  JNIVideo.swift
//  UIKit
//
//  Created by Chris on 13.09.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI
import func Foundation.round // For rounding CGFloats in .frame

public class AVPlayerLayer: JNIObject {

    public convenience init(player: AVPlayer) {
        let parentView = JavaSDLView(getSDLView())
        try! self.init("org.uikit.AVPlayerLayer", arguments: [parentView, player])
    }

    public var frame: CGRect {
        get { return .zero } // FIXME: This would require returning a JavaObject with the various params
        set {
            let scaledFrame = (newValue * UIScreen.main.scale)
            try! call(methodName: "setFrame", arguments: [
                Int(round(scaledFrame.origin.x)),
                Int(round(scaledFrame.origin.y)),
                Int(round(scaledFrame.size.width)),
                Int(round(scaledFrame.size.height))
            ])
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

extension AVPlayerLayer: JavaParameterConvertible {
    private static let javaClassname = "org/uikit/VideoJNI"
    public static let asJNIParameterString = "L\(javaClassname);"

    public func toJavaParameter() -> JavaParameter {
        return JavaParameter(object: self.instance)
    }
}
