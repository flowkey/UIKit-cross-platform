//
//  SDL+JNIExtensions.swift
//  UIKit
//
//  Created by Geordie Jay on 27.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

@_cdecl("Android_JNI_GetActivityClass")
public func getSDLViewClass() -> JavaClass

@_cdecl("SDL_AndroidGetActivity")
public func getSDLView() -> JavaObject

/// Wraps an `SDLActivity` `JavaObject` instance.
/// We do this to allow calling of methods via the JNI that require an "org/libsdl/app/SDLActivity"
/// instead of just a "java/lang/Object".
struct JavaSDLView: JavaParameterConvertible {
    private let object: JavaObject
    init(_ object: JavaObject) {
        self.object = object
    }

    private static let javaClassname = "org/libsdl/app/SDLActivity"
    static let asJNIParameterString = "L\(javaClassname);"

    func toJavaParameter() -> JavaParameter {
        return JavaParameter(object: self.object)
    }

    static func fromStaticField(_ fieldID: JavaFieldID, of javaClass: JavaClass) throws -> JavaSDLView {
        let jobject: JavaObject = try jni.GetStaticObjectField(of: javaClass, id: fieldID)
        return self.init(jobject)
    }

    static func fromMethod(calling methodID: JavaMethodID, on object: JavaObject, args: [JavaParameter]) throws -> JavaSDLView {
        let jObject = try jni.CallObjectMethod(methodID, on: object, parameters: args)
        return self.init(jObject)
    }

    static func fromStaticMethod(calling methodID: JavaMethodID, on javaClass: JavaClass, args: [JavaParameter]) throws -> JavaSDLView {
        let jObject = try jni.CallStaticObjectMethod(methodID, on: javaClass, parameters: args)
        return self.init(jObject)
    }

    static func fromField(_ fieldID: JavaFieldID, on javaObject: JavaObject) throws -> JavaSDLView {
        let javaStringObject = try jni.GetObjectField(of: javaObject, id: fieldID)
        return self.init(javaStringObject)
    }
}
