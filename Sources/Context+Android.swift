//
//  Context+Android.swift
//  UIKit
//
//  Created by Chetan Agarwal on 07/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

#if os(Android)

import Foundation
import JNI

/**
 https://developer.android.com/reference/android/content/Context
 */
class Context: JNIObject {

    static let className = "android.content.Context"

    static func getContext() throws -> Context {
        return try Context(
            jni.call("getContext", on: getSDLView(), returningObjectType: className)
        )
    }

    func getCacheDir() throws ->  File {
        return try File(
            jni.call("getCacheDir", on: self.instance, returningObjectType: File.className)
        )
    }

    func getFilesDir() throws ->  File {
        return try File(
            jni.call("getFilesDir", on: self.instance, returningObjectType: File.className)
        )
    }
}
#endif

