#if os(Android)
//
//  AVPlayerItem+Android.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

public class AVPlayerItem {
    public var asset: AVURLAsset
    public init(asset: AVURLAsset) {
        self.asset = asset
    }
}

public class AVURLAsset: JNIObject {
    public override static var className: String { "org.uikit.AVURLAsset" }

    @MainActor
    public var url: URL?

    @MainActor
    convenience public init(url: URL) {
        try! self.init(arguments: JavaSDLView(getSDLView()), url)
        self.url = url
    }
}
#endif
