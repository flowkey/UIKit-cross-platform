//
//  AVPlayerItem+Android.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI
import struct Foundation.URL

public class AVPlayerItem {
    public var asset: AVURLAsset
    public init(asset: AVURLAsset) {
        self.asset = asset
    }
}

public class AVURLAsset: JNIObject {
    public override static var className: String { "org.uikit.AVURLAsset" }

    public var url: URL?
    convenience public init(url: URL) {
        try! self.init(arguments: JavaSDLView(getSDLView()), url.absoluteString)
        self.url = url
    }
}

extension AVURLAsset: JavaParameterConvertible, JavaInitializableFromMethod {
    private static let javaClassname = "org/uikit/AVURLAsset"
    public static let asJNIParameterString = "L\(javaClassname);"

    public func toJavaParameter() -> JavaParameter {
        return JavaParameter(object: self.instance)
    }

    public static func fromMethod(calling methodID: JavaMethodID, on object: JavaObject, args: [JavaParameter]) throws -> Self {
        let jObject = try jni.CallObjectMethod(methodID, on: object, parameters: args)
        return try self.init(jObject)
    }

    public static func fromStaticMethod(calling methodID: JavaMethodID, on javaClass: JavaClass, args: [JavaParameter]) throws -> Self {
        let jObject = try jni.CallStaticObjectMethod(methodID, on: javaClass, parameters: args)
        return try self.init(jObject)
    }
}

