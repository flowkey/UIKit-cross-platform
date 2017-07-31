//
//  Bundle.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

import JNI

#if os(Android)
private func listFiles(inDirectory subpath: String) throws -> [String] {
    let context = try jni.callStatic("getContext", on: getActivityClass(), returningObjectType: "android.content.Context")
    let assetManager = try jni.call("getAssets", on: context, returningObjectType: "android.content.res.AssetManager")

    return try jni.call("list", on: assetManager, with: [subpath])
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
            print("Failed to get directory listing:", error)
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
#endif

