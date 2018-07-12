//
//  Bundle.swift
//  UIKit
//
//  Created by Geordie Jay on 17.07.17.
//  Copyright © 2017 flowkey. All rights reserved.
//

#if os(macOS)
import class Foundation.Bundle
public typealias Bundle = Foundation.Bundle
#elseif os(Android)
import JNI

private func listFiles(inDirectory subpath: String) throws -> [String] {
    let context = try jni.call("getContext", on: getSDLView(), returningObjectType: "android/content/Context")
    let assetManager = try jni.call("getAssets", on: context, returningObjectType: "android/content/res/AssetManager")
    return try jni.call("list", on: assetManager, with: [subpath])
}

public struct Bundle {
    public init(for: Any.Type) {}

    public func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        do {
            let allFiles = try listFiles(inDirectory: subpath ?? "")
            guard let ext = ext else { return allFiles }
            return allFiles.filter { $0.hasSuffix(ext) }
        } catch {
            assertionFailure("Failed to get directory listing: \(error)")
            return []
        }
    }

    public func path(forResource filename: String, ofType ext: String) -> String? {
        if ext.hasPrefix(".") {
            return filename + ext
        } else {
            return filename + "." + ext
        }
    }
}
#endif

