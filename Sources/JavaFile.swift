//
//  JavaFile.swift
//  UIKit
//
//  Created by Chetan Agarwal on 07/06/2019.
//  Copyright © 2019 flowkey. All rights reserved.
//

#if os(Android)

import Foundation
import JNI

/**
 https://developer.android.com/reference/java/io/File
 */
final class JavaFile: JNIObject {


    override public class var className: String {
        return "java.io.File"
    }

    convenience init(path: String) throws {
        try self.init(JavaFile.className, arguments: [path])
    }

    func getAbsolutePath() throws -> String {
        return try call(methodName: "getAbsolutePath")
    }
}

#endif
