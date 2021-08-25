//
//  AndroidContext.swift
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
class AndroidContext: JNIObject {

    override public class var className: String {
        return "android.content.Context"
    }

    static func getContext() throws -> AndroidContext {
        return try AndroidContext(
            jni.call("getContext", on: getSDLView(), returningObjectType: className)
        )
    }

    func getCacheDir() throws ->  JavaFile {
        return try JavaFile(
            jni.call("getCacheDir", on: self.instance, returningObjectType: JavaFile.className)
        )
    }

    func getFilesDir() throws ->  JavaFile {
        return try JavaFile(
            jni.call("getFilesDir", on: self.instance, returningObjectType: JavaFile.className)
        )
    }
}
#endif

