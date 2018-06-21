//
//  AVPlayerItem+Android.swift
//  UIKit
//
//  Created by Geordie Jay on 24.05.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI
import struct Foundation.URL

public class AVPlayerItem: JNIObject {
    public var url: URL?
    convenience public init(url: URL) {
        try! self.init("org.uikit.AVPlayerItem", arguments: [JavaSDLView(getSDLView()), url.absoluteString])
        self.url = url
    }

    public var durationInMs: Double {
        let duration: Int64 = try! jni.GetField("duration", from: self.instance)
        return Double(duration)
    }
}

extension AVPlayerItem: JavaParameterConvertible, JavaInitializableFromMethod {
    private static let javaClassname = "org/uikit/AVPlayerItem"
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

