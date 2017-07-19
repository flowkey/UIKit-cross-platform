//
//  Bundle.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import CJNI
import JNISwift

//#if os(Android)
@_silgen_name("Android_JNI_GetActivityClass")
public func getActivityClass() -> JavaClass

private func listFiles(inDirectory subpath: String) throws -> [String] {
    let activityClass = getActivityClass()
    let context = try callStatic("getContext", on: activityClass, returningObjectType: "android.content.Context")
    let assetManager = try call("getAssets", on: context, returningObjectType: "android.content.res.AssetManager")

    return try call("list", on: assetManager, with: [subpath])
}

public struct Bundle {
    public init(for: Any.Type) {}

    public func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        do {
            let allFiles = try listFiles(inDirectory: subpath ?? "")
            guard let ext = ext else { return allFiles }

            let filteredFiles = allFiles.filter({ filename -> Bool in
                let result = strcmp(String(filename.characters.suffix(ext.characters.count)), ext)
                return result == 0 // 0 is an exact match
            })

            return filteredFiles
        } catch {
            return []
        }
    }

    public func path(forResource filename: String, ofType ext: String) -> String? {
        if ext.characters.first  == "." {
            return filename + ext
        } else {
            return filename + "." + ext
        }
    }
}
//#endif
